*&---------------------------------------------------------------------*
*& Report  ZRECALCULATE_CAPA
*&
*& Version 10 as of 2nd March 2012 (AM)
*&   Corrected Issue: Performance Issue in Function
*&                    CRM_STATUS_BUFFER_IMP_FROM_MEM
*&
*& Version 14 as of 22nd March 2012 (UF)
*&   Corrected Issue: 1. Additioanl messages in the LOG file
*&                      (/SCWM/CCECK/094, /SCWM/CCECK/095, /SCWM/L1170)
*&                    2. SORT LT_LAGP
*&                    3. APPEND is_lagp TO gt_bin in STOCK_CAPA and HU_CAPA
*&                      (required for 'simulation and update' to update all)
*&
*& Version 16 as of 23rd July 2012 (UF)
*&    Corrected Issue: check bins with KZLER = abap_true. (FORM bin_get)
*&
*& Version 17 as of 28rd May 2014 (UF)
*&    Corrected Issue: 1. with gp_bino = X, calculation of weight/volume/capa
*&                        for unpacked stock was wrong (FORM hu_capa)
*&                     2. new selection parameter gp_anzle
*&                        calculate LAGP-ANZLE and KZLER only
*&
*& Version 18 as of 6d June 2014 (UF)
*&    Corrected Issue: KZLER for negative AQUA (open picking WT) -> KZLER = ' '
*&
*& Version 19 as of 13 April 2015 (UF)
*&     Corrected Issue: For SUBBINs in pallet storage types,
*&                      KZVOL has to be checked / corrected
*&
*& Version 20 as of 2nd March 2017 (AS)
*&     Corrected Issue: For MAINBIN in pallet storage types
*&                      KZLER, ANZLE, KZVOL
*&
*& Version 21 as of 4th September 2017 (AS)
*&     Corrected Issue: PTWY DATE not cleared for empty bin
*&
*& Version 22 as of 27th Oktober 2017 (AS)
*&     Corrected Issue: KZVOL is cleared for divided main bins
*&
*&   When changing this report, make sure you are changing the newest
*&   Version, which is attached to note 1532672, and describe the
*&   Changes in this comment, please also update the Version Number
*&---------------------------------------------------------------------*
REPORT  zrecalculate_capa.
TYPE-POOLS: wmegc.
DATA: go_log   TYPE REF TO /scwm/cl_log.
DATA: gt_t331  TYPE /scwm/tt_t331,
      gt_bin   TYPE /scwm/tt_lagp,
      gt_hdr   TYPE /scwm/tt_huhdr,
      gt_itm   TYPE /scwm/tt_huitm.
DATA: gs_prof  TYPE bal_s_prof,
      gs_log   TYPE bal_s_log,
      gs_lgtyp TYPE /scwm/t331,
      gs_bin   TYPE /scwm/lagp.  "for select option only
DATA: gv_logh  TYPE balloghndl.
SELECTION-SCREEN BEGIN OF BLOCK 001 WITH FRAME TITLE text-001.
PARAMETERS: gp_lgnum TYPE /scwm/lgnum OBLIGATORY.
SELECT-OPTIONS: gp_lgtyp FOR gs_lgtyp-lgtyp,
                gp_lgpla FOR gs_bin-lgpla.
SELECTION-SCREEN END OF BLOCK 001.
SELECTION-SCREEN BEGIN OF BLOCK 002 WITH FRAME TITLE text-002.
PARAMETERS: gp_bino TYPE abap_bool DEFAULT abap_false,
            gp_anzle TYPE abap_bool DEFAULT abap_false.
SELECTION-SCREEN END OF BLOCK 002.
SELECTION-SCREEN BEGIN OF BLOCK 003 WITH FRAME TITLE text-003.
PARAMETERS: gp_slog TYPE abap_bool DEFAULT abap_false,
            gp_sim  TYPE abap_bool DEFAULT abap_true,
            gp_2step TYPE abap_bool DEFAULT abap_false.
SELECTION-SCREEN END OF BLOCK 003.
START-OF-SELECTION.
* get selected storage types:
  IF gp_lgpla[] IS INITIAL.
    SELECT * FROM /scwm/t331 INTO TABLE gt_t331
                             WHERE lgnum = gp_lgnum AND
                                   lgtyp IN gp_lgtyp.
  ELSE.
    SELECT * FROM /scwm/lagp INTO TABLE gt_bin
                             WHERE lgnum = gp_lgnum  AND
                                   lgtyp IN gp_lgtyp AND
                                   lgpla IN gp_lgpla.
    IF sy-subrc IS INITIAL.
      SORT gt_bin BY lgtyp.
      DELETE ADJACENT DUPLICATES FROM gt_bin COMPARING lgtyp.
      SELECT * FROM /scwm/t331 INTO TABLE gt_t331
                               FOR ALL ENTRIES IN gt_bin
                               WHERE lgnum = gp_lgnum AND
                                     lgtyp = gt_bin-lgtyp.
      CLEAR: gt_bin.
    ENDIF.
  ENDIF.
* generate log for protocoll
  CREATE OBJECT go_log.
  CONCATENATE sy-datum space 'capa' INTO sy-msgv1.
  gs_log-extnumber = sy-msgv1.
  gs_log-object = '/SCWM/WME'.
  gs_log-subobject = 'LOG_GENERAL'.
  go_log->create_log( EXPORTING is_log = gs_log
                      IMPORTING ev_loghandle = gv_logh ).
  TRY.
      IF gp_2step = abap_true.
        gp_sim = abap_true.
        PERFORM recalc_capa.
        PERFORM setup_for_second.
      ENDIF.
      PERFORM recalc_capa.
      MESSAGE 'Data analysis finished' TYPE 'S'.
      go_log->add_message2log( EXPORTING ip_detlvl = '1'
                                         ip_loghandle = gv_logh ).
      PERFORM table_update.
      IF gp_slog = abap_true.
        go_log->save_applog2db( iv_loghandle = gv_logh ).
      ENDIF.
    CATCH /scwm/cx_basics.
      go_log->add_message2log( EXPORTING ip_detlvl = '1'
                                         ip_loghandle = gv_logh ).
  ENDTRY.
  COMMIT WORK.
  CALL FUNCTION 'DEQUEUE_ALL'.
  TRY.
      go_log->display_log( iv_loghandle = gv_logh ).
    CATCH /scwm/cx_basics.
      WRITE: 'problem in protocoll'.
  ENDTRY.
*--------------------------------------------------------------------
FORM recalc_capa.
  DATA: lt_huhdr TYPE /scwm/tt_huhdr_int,
        lt_huitm TYPE /scwm/tt_huitm_int,
        lt_lagp  TYPE /scwm/tt_lagp,
        lt_pallet_main  TYPE /scwm/tt_lagp.
  DATA: ls_main TYPE /scwm/s_hu_main_data,
        ls_loc   TYPE /lime/loc_key,
        ls_t331  TYPE /scwm/t331.
  DATA: lv_msg   TYPE string,
        lv_itm   TYPE i,
        lv_hdr   TYPE i,
        lv_bin   TYPE i.
  FIELD-SYMBOLS: <s_lagp> TYPE /scwm/lagp.
  ls_main-appl = 'WME'.
  ls_main-lgnum = gp_lgnum.
* perform capa redetermination per storage type.
  LOOP AT gt_t331 INTO ls_t331.
    CLEAR: lt_lagp, lv_bin, lv_hdr, lv_itm.
    PERFORM bin_get USING    ls_t331
                    CHANGING lt_lagp
                             lt_pallet_main.
    IF gp_sim = abap_false.
      PERFORM bin_lock USING    ls_t331
                       CHANGING lt_lagp.
    ENDIF.
    SORT lt_lagp BY lgpla.
    LOOP AT lt_lagp ASSIGNING <s_lagp>.
      CLEAR: lt_huhdr, lt_huitm, ls_loc.
      IF ls_t331-nocapaupd = abap_true.
        PERFORM bin_capa USING    ls_t331 lt_huhdr lt_huitm
                         CHANGING <s_lagp> lv_bin.
        CONTINUE.
      ENDIF.
* get_HU's and stock
      ls_loc-idx_loc = 'W01'.
      ls_loc-lgnum = gp_lgnum.
      ls_loc-lgtyp = ls_t331-lgtyp.
      ls_loc-lgpla = <s_lagp>-lgpla.
      CALL FUNCTION '/SCWM/HU_GT_FILL'
        EXPORTING
          iv_appl      = 'WME'
          is_main_data = ls_main
          is_location  = ls_loc
        IMPORTING
          et_huhdr     = lt_huhdr
          et_huitm     = lt_huitm
        EXCEPTIONS
          not_found    = 1
          error        = 2
          OTHERS       = 3.
      IF sy-subrc <> 0.
        go_log->add_message2log( EXPORTING ip_detlvl = '1'
                                           ip_loghandle = gv_logh ).
        CONTINUE.
      ENDIF.
      CHECK NOT lt_huhdr IS INITIAL.
      DELETE lt_huitm WHERE vsi = wmegc_vsi_kit OR
                            vsi = wmegc_vsi_phm OR
                            quan = 0.
      SORT lt_huitm BY guid_parent.
      SORT lt_huhdr BY guid_hu.
*     recalculate Stock-Items
      IF gp_anzle IS INITIAL.
        PERFORM stock_capa USING    ls_t331 lt_huhdr <s_lagp>
                           CHANGING lt_huitm lv_itm.
        PERFORM hu_capa  USING    ls_t331 lt_huitm <s_lagp>
                         CHANGING lt_huhdr lv_hdr.
      ENDIF.
      PERFORM bin_capa USING    ls_t331 lt_huhdr lt_huitm
                       CHANGING <s_lagp> lv_bin.
      DELETE lt_huhdr WHERE updkz = space.
      DELETE lt_huhdr WHERE vhi CN ' '.
      APPEND LINES OF lt_huhdr TO gt_hdr.
      CALL FUNCTION '/SCWM/HUMAIN_REFRESH'.
    ENDLOOP.
    LOOP AT lt_pallet_main ASSIGNING <s_lagp>.
      PERFORM pallet_main_update USING ls_t331
                                    CHANGING <s_lagp> lv_bin.
    ENDLOOP.
    SORT gt_bin BY lgtyp lgpla.
    DELETE ADJACENT DUPLICATES FROM gt_bin COMPARING lgpla.
    IF lv_bin > 0 OR lv_hdr > 0 OR lv_itm > 0.
      MESSAGE i126(/scwm/ccheck) WITH ls_t331-lgtyp lv_bin lv_hdr lv_itm
                                 INTO lv_msg.
    ELSE.
      MESSAGE i125(/scwm/ccheck) WITH ls_t331-lgtyp INTO lv_msg.
    ENDIF.
    go_log->add_message2log( EXPORTING ip_detlvl = '1'
                                       ip_loghandle = gv_logh ).
  ENDLOOP.
ENDFORM.                    "recalc_capa
*--------------------------------------------------------------------
FORM bin_get USING    is_t331 TYPE /scwm/t331
             CHANGING et_lagp TYPE /scwm/tt_lagp
                      et_pallet_main TYPE /scwm/tt_lagp.
  DATA: lt_huhdr TYPE /scwm/tt_huhdr_int.
  DATA: ls_lagp  TYPE /scwm/lagp.
  IF gp_lgpla[] IS INITIAL.
    SELECT * FROM /scwm/lagp INTO TABLE et_lagp
                             WHERE lgnum = gp_lgnum AND
                                   lgtyp = is_t331-lgtyp.
  ELSE.
    SELECT * FROM /scwm/lagp INTO TABLE et_lagp
                             WHERE lgnum = gp_lgnum AND
                                   lgpla IN gp_lgpla AND
                                   lgtyp = is_t331-lgtyp.
  ENDIF.
*  DELETE et_lagp WHERE kzler = abap_true.
  LOOP AT et_lagp INTO ls_lagp WHERE flgsbin = '2'.
    APPEND ls_lagp TO et_pallet_main.
  ENDLOOP.
  DELETE et_lagp WHERE flgsbin = '2'.
ENDFORM.                    "bin_get
*----------------------------------------------------------------------
FORM stock_capa USING    is_t331  TYPE /scwm/t331
                         it_huhdr TYPE /scwm/tt_huhdr_int
                         is_lagp  TYPE /scwm/lagp
                CHANGING ct_huitm TYPE /scwm/tt_huitm_int
                         cv_itm   TYPE i.
  DATA: ls_dim   TYPE /scwm/s_capacity,
        ls_huitm TYPE /scwm/quan.
  DATA: lv_hu    TYPE /scwm/guid_hu,
        lv_msg   TYPE string.
  FIELD-SYMBOLS: <s_huitm> TYPE /scwm/s_huitm_int,
                 <s_huhdr> TYPE /scwm/s_huhdr_int.
  LOOP AT ct_huitm ASSIGNING <s_huitm>.
    MOVE-CORRESPONDING <s_huitm> TO ls_dim.
    IF NOT <s_huhdr> IS ASSIGNED OR
       <s_huhdr>-guid_hu <> <s_huitm>-guid_parent.
      READ TABLE it_huhdr ASSIGNING <s_huhdr>
                          WITH KEY guid_hu = <s_huitm>-guid_parent
                          BINARY SEARCH.
      CHECK sy-subrc IS INITIAL.
      IF <s_huhdr>-vhi IS INITIAL.
        lv_hu = <s_huhdr>-guid_hu.
      ELSE.
        CLEAR: lv_hu.    "dummy HU must not be passed
      ENDIF.
    ENDIF.
    TRY.
        IF gp_bino = abap_true.
          CHECK lv_hu IS INITIAL.  "calculate only for stock on bin level
        ENDIF.
        CALL FUNCTION '/SCWM/STOCK_CAPA'
          EXPORTING
            iv_hu   = lv_hu
            is_t331 = is_t331
          CHANGING
            cs_quan = <s_huitm>.
        IF <s_huitm>-weight < 0. CLEAR: <s_huitm>-weight. ENDIF.
        IF <s_huitm>-volum  < 0. CLEAR: <s_huitm>-volum.  ENDIF.
        IF <s_huitm>-capa   < 0. CLEAR: <s_huitm>-capa.   ENDIF.
        IF <s_huitm>-weight <> ls_dim-weight OR
           <s_huitm>-volum  <> ls_dim-volum OR
           <s_huitm>-capa   <> ls_dim-capa.
          <s_huitm>-updkz = 'U'.
          MOVE-CORRESPONDING <s_huitm> TO ls_huitm.
          APPEND ls_huitm TO gt_itm.
          MESSAGE w095(/scwm/ccheck) WITH <s_huitm>-matid INTO lv_msg.
          go_log->add_message2log( EXPORTING ip_detlvl = '2'
                                     ip_loghandle = gv_logh ).
          ADD 1 TO cv_itm.
          IF gp_sim = abap_true.
            APPEND is_lagp TO gt_bin.
          ENDIF.
        ENDIF.
      CATCH /scwm/cx_core.
        go_log->add_message2log( EXPORTING ip_detlvl = '2'
                                           ip_loghandle = gv_logh ).
    ENDTRY.
  ENDLOOP.
ENDFORM.                    "stock_capa
*-----------------------------------------------------------------
FORM hu_capa USING    is_t331  TYPE /scwm/t331
                      it_huitm TYPE /scwm/tt_huitm_int
                      is_lagp  TYPE /scwm/lagp
             CHANGING ct_huhdr TYPE /scwm/tt_huhdr_int
                      cv_hdr   TYPE i.
  DATA: lt_huhdr TYPE /scwm/tt_huhdr_int.
  DATA: ls_huhdr TYPE /scwm/s_huhdr_int,
        ls_dim   TYPE /scwm/s_capacity.
  DATA: lv_hus   TYPE sytabix,
        lv_index TYPE sytabix,
        lv_msg   TYPE string.
  FIELD-SYMBOLS: <s_huhdr> TYPE /scwm/s_huhdr_int,
                 <s_hdr>   TYPE /scwm/s_huhdr_int,
                 <s_huitm> TYPE /scwm/s_huitm_int.
  lt_huhdr = ct_huhdr.
* clear all capacity data.
  IF gp_bino = abap_false.
    MODIFY lt_huhdr FROM ls_huhdr TRANSPORTING n_weight g_weight
                                               n_volume g_volume
                                               n_capa   g_capa
                                  WHERE vhi <> 'E'.
  ELSE.
*   clear is only done for dummy-HU's!
    MODIFY lt_huhdr FROM ls_huhdr TRANSPORTING n_weight g_weight
                                               n_volume g_volume
                                               n_capa   g_capa
                                  WHERE vhi CN ' E'.
  ENDIF.
  DESCRIBE TABLE ct_huhdr LINES lv_hus.
  DO.
    ADD 1 TO lv_index.
    READ TABLE lt_huhdr ASSIGNING <s_huhdr> INDEX lv_index.
    IF NOT sy-subrc IS INITIAL. EXIT. ENDIF.  "exit DO
    CLEAR: ls_dim.
* add tare capa to gross capa for this handling unit
    IF gp_bino = abap_false AND NOT <s_huhdr>-vhi = 'E'.
      <s_huhdr>-g_weight = <s_huhdr>-g_weight + <s_huhdr>-t_weight.
      <s_huhdr>-g_volume = <s_huhdr>-g_volume + <s_huhdr>-t_volume.
      <s_huhdr>-g_capa   = <s_huhdr>-g_capa   + <s_huhdr>-t_capa.
      ls_dim-weight = <s_huhdr>-t_weight.
      ls_dim-volum  = <s_huhdr>-t_volume.
      ls_dim-capa   = <s_huhdr>-t_capa.
    ELSEIF gp_bino = abap_true AND <s_huhdr>-vhi = 'A'.
      ls_dim-weight = <s_huhdr>-g_weight.
      ls_dim-volum  = <s_huhdr>-g_volume.
      ls_dim-capa   = <s_huhdr>-g_capa.
    ELSE.
      ls_dim-weight = <s_huhdr>-g_weight.
      ls_dim-volum  = <s_huhdr>-g_volume.
      ls_dim-capa   = <s_huhdr>-g_capa.
      CONTINUE.
    ENDIF.
* update stock capa to HU
    READ TABLE it_huitm TRANSPORTING NO FIELDS
                        WITH KEY guid_parent = <s_huhdr>-guid_hu.
    IF sy-subrc IS INITIAL.
      LOOP AT it_huitm ASSIGNING <s_huitm> FROM sy-tabix.
        IF <s_huitm>-guid_parent <> <s_huhdr>-guid_hu. EXIT. ENDIF.
        <s_huhdr>-n_weight = <s_huhdr>-n_weight + <s_huitm>-weight.
        <s_huhdr>-n_volume = <s_huhdr>-n_volume + <s_huitm>-volum.
        <s_huhdr>-n_capa = <s_huhdr>-n_capa + <s_huitm>-capa.
        <s_huhdr>-g_weight = <s_huhdr>-g_weight + <s_huitm>-weight.
        ls_dim-weight = ls_dim-weight + <s_huitm>-weight.
        IF <s_huhdr>-closed_package = abap_false.
          <s_huhdr>-g_volume = <s_huhdr>-g_volume + <s_huitm>-volum.
          ls_dim-volum = ls_dim-volum + <s_huitm>-volum.
        ENDIF.
        <s_huhdr>-g_capa = <s_huhdr>-g_capa + <s_huitm>-capa.
        ls_dim-capa = ls_dim-capa + <s_huitm>-capa.
      ENDLOOP.
    ENDIF.
* add HU capa to higher levels
    DO.
      IF <s_huhdr>-top = abap_true.  "exit do
        EXIT.
      ENDIF.
      READ TABLE lt_huhdr ASSIGNING <s_huhdr>
                          WITH KEY guid_hu = <s_huhdr>-higher_guid
                          BINARY SEARCH.
      IF NOT sy-subrc IS INITIAL. EXIT. ENDIF.  "exit do
      <s_huhdr>-g_weight = <s_huhdr>-g_weight + ls_dim-weight.
      <s_huhdr>-n_weight = <s_huhdr>-n_weight + ls_dim-weight.
      <s_huhdr>-n_volume = <s_huhdr>-n_volume + ls_dim-volum.
      IF <s_huhdr>-closed_package = abap_true.
        CLEAR: ls_dim-volum.
      ELSE.
        <s_huhdr>-g_volume = <s_huhdr>-g_volume + ls_dim-volum.
      ENDIF.
      <s_huhdr>-g_capa = <s_huhdr>-g_capa + ls_dim-capa.
      <s_huhdr>-n_capa = <s_huhdr>-n_capa + ls_dim-capa.
    ENDDO.
    IF lv_index >= lv_hus. EXIT. ENDIF.
  ENDDO.
  LOOP AT ct_huhdr ASSIGNING <s_huhdr>.
    READ TABLE lt_huhdr ASSIGNING <s_hdr> INDEX sy-tabix.
    IF <s_huhdr>-g_weight < 0. CLEAR: <s_huhdr>-g_weight. ENDIF.
    IF <s_huhdr>-n_weight < 0. CLEAR: <s_huhdr>-n_weight. ENDIF.
    IF <s_huhdr>-g_volume < 0. CLEAR: <s_huhdr>-g_volume. ENDIF.
    IF <s_huhdr>-n_volume < 0. CLEAR: <s_huhdr>-n_volume. ENDIF.
    IF <s_huhdr>-g_capa   < 0. CLEAR: <s_huhdr>-g_capa.   ENDIF.
    IF <s_huhdr>-n_capa   < 0. CLEAR: <s_huhdr>-n_capa.   ENDIF.
    CHECK <s_huhdr>-s_dimall <> <s_hdr>-s_dimall.
    <s_huhdr>-s_dimall = <s_hdr>-s_dimall.
    <s_huhdr>-updkz = 'U'.
    CHECK <s_huhdr>-vhi IS INITIAL.  "message only for real HU
    MESSAGE w094(/scwm/ccheck) WITH <s_huhdr>-huident INTO lv_msg.
    go_log->add_message2log( EXPORTING ip_detlvl = '2'
                                     ip_loghandle = gv_logh ).
    ADD 1 TO cv_hdr.
    IF gp_sim = abap_true.
      APPEND is_lagp TO gt_bin.
    ENDIF.
  ENDLOOP.
ENDFORM.                    "hu_capa
*---------------------------------------------------------------------
FORM bin_capa USING    is_t331  TYPE /scwm/t331
                       it_huhdr TYPE /scwm/tt_huhdr_int
                       it_huitm TYPE /scwm/tt_huitm_int
              CHANGING cs_lagp  TYPE /scwm/lagp
                       cv_bin   TYPE i.
  DATA: lt_huhdr TYPE /scwm/tt_huhdr_int.
  DATA: ls_dim   TYPE /scwm/s_capa_result.
  DATA: lv_capa  TYPE /scwm/lagp_rkapv,
        lv_kzler TYPE abap_bool,
        lv_kzvol TYPE abap_bool,
        lv_tanum TYPE /scwm/tanum,
        lv_msg   TYPE string,
        lv_maxle TYPE /scwm/lagp_maxle.
  FIELD-SYMBOLS: <s_huhdr> TYPE /scwm/s_huhdr_int.
  lv_maxle = cs_lagp-maxle.
  lv_kzvol = cs_lagp-kzvol.
  lt_huhdr = it_huhdr.
  DELETE lt_huhdr WHERE top IS INITIAL.
  LOOP AT lt_huhdr ASSIGNING <s_huhdr>.
    IF gp_anzle IS INITIAL.
      ls_dim-weight = ls_dim-weight + <s_huhdr>-g_weight.
      ls_dim-volum  = ls_dim-volum  + <s_huhdr>-g_volume.
      CASE is_t331-kapap.
        WHEN wmegc_capa_mat.
          ls_dim-capa = ls_dim-capa + <s_huhdr>-n_capa.
        WHEN wmegc_capa_let.
          ls_dim-capa = ls_dim-capa + <s_huhdr>-t_capa.
        WHEN wmegc_capa_mat_let.
          ls_dim-capa = ls_dim-capa + <s_huhdr>-g_capa.
        WHEN OTHERS.
      ENDCASE.
    ENDIF.
    CHECK <s_huhdr>-vhi CA ' E'.
    ADD 1 TO ls_dim-nanzl.
  ENDLOOP.
  IF ls_dim IS INITIAL.
* check for stock on dummy HU
    READ TABLE it_huitm TRANSPORTING NO FIELDS
                        WITH KEY guid_parent = cs_lagp-guid_hu
                        BINARY SEARCH.
    IF NOT sy-subrc IS INITIAL AND is_t331-nocapaupd IS INITIAL.
      IF is_t331-put_rule = wmegc_prl_free.
* for free storage types, KZLER is always updated at WT confirmation
        lv_kzler = abap_true.
      ELSE.
* get open WT to determine empty flag
        SELECT SINGLE tanum FROM  /scwm/ordim_o INTO  lv_tanum
                            WHERE lgnum = cs_lagp-lgnum
                            AND nltyp = cs_lagp-lgtyp
                            AND nlpla = cs_lagp-lgpla.
        IF NOT sy-subrc IS INITIAL.
          SELECT SINGLE tanum FROM  /scwm/ordim_o INTO  lv_tanum
                              WHERE lgnum = cs_lagp-lgnum
                              AND vltyp = cs_lagp-lgtyp
                              AND vlpla = cs_lagp-lgpla.
          IF NOT sy-subrc IS INITIAL.
* no stock and no open WT for putaway or picking
            lv_kzler = abap_true.
            IF is_t331-behav = wmegc_behav_pallet.
              CLEAR lv_kzvol.
            ENDIF.
            IF is_t331-behav = wmegc_behav_block.
              CLEAR lv_maxle.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
  IF gp_anzle IS INITIAL.
    IF cs_lagp-max_capa > 0.
      lv_capa = cs_lagp-max_capa - ls_dim-capa.
    ENDIF.
    CHECK cs_lagp-weight <> ls_dim-weight OR
          cs_lagp-volum  <> ls_dim-volum  OR
          cs_lagp-fcapa  <> lv_capa   OR
          cs_lagp-anzle  <> ls_dim-nanzl OR
          cs_lagp-kzler  <> lv_kzler OR
          cs_lagp-kzvol  <> lv_kzvol.
    cs_lagp-weight = ls_dim-weight.
    cs_lagp-volum  = ls_dim-volum.
    cs_lagp-fcapa  = lv_capa.
    cs_lagp-anzle  = ls_dim-nanzl.
    cs_lagp-kzler  = lv_kzler.
    cs_lagp-kzvol  = lv_kzvol.
    IF lv_kzler = abap_true AND cs_lagp-ptwy_date IS NOT INITIAL.
      CLEAR cs_lagp-ptwy_date.
    ENDIF.
  ELSE.
    CHECK cs_lagp-anzle  <> ls_dim-nanzl OR
          cs_lagp-kzler  <> lv_kzler OR
          cs_lagp-kzvol  <> lv_kzvol.
    cs_lagp-anzle  = ls_dim-nanzl.
    cs_lagp-kzler  = lv_kzler.
    cs_lagp-kzvol  = lv_kzvol.
    IF lv_kzler = abap_true AND cs_lagp-ptwy_date IS NOT INITIAL.
      CLEAR cs_lagp-ptwy_date.
    ENDIF.
  ENDIF.
  IF is_t331-behav = wmegc_behav_block.
    cs_lagp-maxle  = lv_maxle.
  ENDIF.
  MESSAGE w017(/scwm/l1) WITH cs_lagp-lgpla INTO lv_msg.
  go_log->add_message2log( EXPORTING ip_detlvl = '2'
                                     ip_loghandle = gv_logh ).
  ADD 1 TO cv_bin.
  APPEND cs_lagp TO gt_bin.
ENDFORM.                    "bin_capa
*&---------------------------------------------------------------------*
*&      Form  bin_lock
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IS_T331    text
*      <--CT_LAGP    text
*----------------------------------------------------------------------*
FORM bin_lock USING    is_t331 TYPE /scwm/t331
              CHANGING ct_lagp TYPE /scwm/tt_lagp.
  DATA: lv_msg   TYPE string.
  FIELD-SYMBOLS <s_lagp> TYPE /scwm/lagp.
  CHECK gp_sim = abap_false.
  CHECK is_t331-nocapaupd IS INITIAL.
* collect all lockes to call enqueue server only once.
  LOOP AT ct_lagp ASSIGNING <s_lagp>.
    CALL FUNCTION 'ENQUEUE_/SCWM/ELAQUAX'
      EXPORTING
        mode_/scwm/aquax = 'E'
        lgnum            = <s_lagp>-lgnum
        loc_type         = 'B'
        location         = <s_lagp>-lgpla
        _collect         = 'X'
      EXCEPTIONS
        system_failure   = 2
        OTHERS           = 99.
    IF sy-subrc <> 0.
      go_log->add_message2log( EXPORTING ip_detlvl = '2'
                                         ip_loghandle = gv_logh ).
      MESSAGE 'error on locking - no data are processed' TYPE 'S'.
      go_log->add_message2log( EXPORTING ip_detlvl = '2'
                                         ip_loghandle = gv_logh ).
      CLEAR: ct_lagp.
      RETURN.
    ENDIF.
  ENDLOOP.
  CALL FUNCTION 'FLUSH_ENQUEUE'
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 99.
  CASE sy-subrc.
    WHEN 0.
    WHEN 1.
* lock each bin seperatly
      LOOP AT ct_lagp ASSIGNING <s_lagp>.
        CALL FUNCTION 'ENQUEUE_/SCWM/ELAQUAX'
          EXPORTING
            mode_/scwm/aquax = 'E'
            lgnum            = <s_lagp>-lgnum
            loc_type         = 'B'
            location         = <s_lagp>-lgpla
          EXCEPTIONS
            foreign_lock     = 1
            OTHERS           = 99.
        CHECK NOT sy-subrc IS INITIAL.
        MESSAGE e170(/scwm/l1) WITH <s_lagp>-lgpla INTO lv_msg.
        go_log->add_message2log( EXPORTING ip_detlvl = '2'
                                           ip_loghandle = gv_logh ).
        DELETE ct_lagp.   "bin cannot be processed
      ENDLOOP.
    WHEN OTHERS.
      CLEAR: ct_lagp.
      go_log->add_message2log( EXPORTING ip_detlvl = '2'
                                         ip_loghandle = gv_logh ).
  ENDCASE.
ENDFORM.                    "bin_lock
*&---------------------------------------------------------------------*
*&      Form  setup_for_second
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM setup_for_second.
  FIELD-SYMBOLS: <s_lagp> TYPE /scwm/lagp.
  gp_sim = abap_false.  "in second processing it's no simulation any more
* setup for selecting only faulty bins
  CLEAR: gp_lgpla, gp_lgpla[], gt_t331.
  LOOP AT gt_bin ASSIGNING <s_lagp>.
    gp_lgpla-sign = 'I'.
    gp_lgpla-option = 'EQ'.
    gp_lgpla-low = <s_lagp>-lgpla.
    APPEND gp_lgpla TO gp_lgpla.
  ENDLOOP.
  CHECK sy-subrc IS INITIAL.
  SORT gt_bin BY lgtyp.
  DELETE ADJACENT DUPLICATES FROM gt_bin COMPARING lgtyp.
  SELECT * FROM /scwm/t331 INTO TABLE gt_t331
                           FOR ALL ENTRIES IN gt_bin
                           WHERE lgnum = gp_lgnum AND
                                 lgtyp = gt_bin-lgtyp.
  CLEAR: gt_bin, gt_hdr, gt_itm.
  MESSAGE 'simulation finished - start analysis for update' TYPE 'S'.
  go_log->add_message2log( EXPORTING ip_detlvl = '1'
                                     ip_loghandle = gv_logh ).
ENDFORM.                    "setup_for_second
*----------------------------------------------------------------------
FORM table_update.
  DATA: ls_lagp TYPE /scwm/lagp.
  FIELD-SYMBOLS: <s_lagp> TYPE /scwm/lagp.
  CHECK gp_sim = abap_false.
  LOOP AT gt_bin ASSIGNING <s_lagp>.
    SELECT SINGLE FOR UPDATE * FROM /scwm/lagp INTO ls_lagp
                      WHERE lgnum = <s_lagp>-lgnum AND
                            lgpla = <s_lagp>-lgpla.
    IF NOT sy-subrc IS INITIAL.
      DELETE gt_bin.
    ENDIF.
  ENDLOOP.
  IF gp_anzle IS INITIAL.
    IF NOT gt_hdr IS INITIAL.
      UPDATE /scwm/huhdr FROM TABLE gt_hdr.
    ENDIF.
    IF NOT gt_itm IS INITIAL.
      UPDATE /scwm/quan  FROM TABLE gt_itm.
    ENDIF.
  ENDIF.
  IF NOT gt_bin IS INITIAL.
    UPDATE /scwm/lagp  FROM TABLE gt_bin.
  ENDIF.
ENDFORM.                    "table_update
*&---------------------------------------------------------------------*
*&      Form  PALLET_MAIN_HU_UPDATE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_<S_LAGP>  text
*      <--P_ENDLOOP  text
*----------------------------------------------------------------------*
FORM pallet_main_update USING    is_t331  TYPE /scwm/t331
                           CHANGING cs_lagp TYPE /scwm/lagp
                                    cv_bin TYPE i.
  DATA: lt_lagp_sub TYPE /scwm/tt_lagp,
        lv_lgpla    TYPE /scwm/de_lgpla,
        lv_kzler    TYPE abap_bool,
        lv_kzvol    TYPE abap_bool,
        lv_anzle    TYPE /scwm/lagp_anzle,
        lv_msg      TYPE string.
  FIELD-SYMBOLS: <lagpsub> TYPE /scwm/lagp.
  CONCATENATE cs_lagp-lgpla '/%' INTO lv_lgpla.
  lv_anzle = 0.
  lv_kzler = 'X'.
  SELECT * FROM /scwm/lagp INTO TABLE lt_lagp_sub
    WHERE lgnum = is_t331-lgnum
      AND lgtyp = cs_lagp-lgtyp
      AND lgpla LIKE lv_lgpla.
  IF lt_lagp_sub IS NOT INITIAL.
    lv_kzler = ' '.
    lv_kzvol = 'X'.
  ENDIF.
  LOOP AT lt_lagp_sub ASSIGNING <lagpsub> .
    lv_anzle = lv_anzle + <lagpsub>-anzle.
  ENDLOOP.
  IF lv_anzle > 0.
    lv_kzler = ' '.
  ENDIF.
  CHECK cs_lagp-anzle  <> lv_anzle OR
        cs_lagp-kzler  <> lv_kzler OR
        cs_lagp-kzvol  <> lv_kzvol.
  cs_lagp-anzle  = lv_anzle.
  cs_lagp-kzler  = lv_kzler.
  cs_lagp-kzvol  = lv_kzvol.
  MESSAGE w017(/scwm/l1) WITH cs_lagp-lgpla INTO lv_msg.
  go_log->add_message2log( EXPORTING ip_detlvl = '2'
                                     ip_loghandle = gv_logh ).
  ADD 1 TO cv_bin.
  APPEND cs_lagp TO gt_bin.
ENDFORM.                    " PALLET_MAIN_HU_UPDATE
