FUNCTION zfm_ewm109_returnedhu_initupd.
*"----------------------------------------------------------------------

  TYPES:
    BEGIN OF ts_docno,
      docno TYPE /scdl/dl_docno_int,
    END OF ts_docno,
    BEGIN OF ts_docid,
      docid TYPE /scdl/dl_docid,
    END OF ts_docid,
    tt_docid TYPE STANDARD TABLE OF ts_docid WITH EMPTY KEY,
    tt_docno TYPE STANDARD TABLE OF ts_docno WITH EMPTY KEY.


  DATA: o_appl_log TYPE REF TO ztt_ewm_attp_appl_log.
  DATA: lt_guid_hu TYPE /scwm/tt_guid_hu,
        ls_guid_hu TYPE /scwm/s_guid_hu.
  DATA: lt_guid_hu_tmp TYPE /scwm/tt_guid_hu.
  DATA: lt_xid TYPE /scwm/tt_ident_int.
  DATA: lt_huhdr              TYPE /scwm/tt_huhdr_int.
  DATA: lt_huhdr_tmp             TYPE /scwm/tt_huhdr_int.
  DATA:   lt_hutree             TYPE /scwm/tt_hutree.
  "DATA: lt_ordim_c TYPE STANDARD TABLE OF /scwm/ordim_c.
  DATA:   lt_docno TYPE tt_docno.
  DATA:   lt_docid TYPE tt_docid.
  CONSTANTS lc_doccat      TYPE /scwm/de_doccat VALUE 'PDI'.
  CONSTANTS lc_lgnum       TYPE /scwm/lgnum     VALUE 'XXX'.

  SELECT docid INTO TABLE lt_docid
            FROM /scdl/db_proch_i AS proch
    WHERE proch~doctype = 'XXX' AND proch~partnerfrom_id = 'XXX'.


  SELECT *
        FROM /scwm/ordim_c
        INTO TABLE @DATA(lt_ordim_c)
        FOR ALL ENTRIES IN @lt_docid
        WHERE
      lgnum = @lc_lgnum
       AND
      rdoccat = 'PDI'
          AND
      rdocid = @lt_docid-docid.

  DELETE lt_ordim_c WHERE trart NE '5' OR tostat NE 'C' OR nlenr EQ space.
  SORT lt_ordim_c BY dguid_hu.
  DELETE ADJACENT DUPLICATES FROM lt_ordim_c COMPARING dguid_hu.


  LOOP AT lt_ordim_c INTO DATA(ls_ordim_c) WHERE dguid_hu IS NOT INITIAL.
    ls_guid_hu-guid_hu = ls_ordim_c-dguid_hu.
    APPEND ls_guid_hu TO lt_guid_hu.
  ENDLOOP.


  SORT lt_guid_hu.
  DELETE ADJACENT DUPLICATES FROM lt_guid_hu COMPARING guid_hu.

  CALL FUNCTION '/SCWM/HU_SELECT'
    EXPORTING
      it_guid_hu = lt_guid_hu
    IMPORTING
      et_huhdr   = lt_huhdr
      et_tree    = lt_hutree
    EXCEPTIONS
      not_found  = 01
      OTHERS     = 99.

  LOOP AT lt_guid_hu ASSIGNING FIELD-SYMBOL(<fs_guid_hu>).
    READ TABLE lt_hutree ASSIGNING FIELD-SYMBOL(<fs_hutree>) WITH KEY guid = <fs_guid_hu>-guid_hu.
    IF sy-subrc IS INITIAL.
      APPEND INITIAL LINE TO lt_guid_hu_tmp ASSIGNING FIELD-SYMBOL(<fs_guid_hu_tmp>).
      <fs_guid_hu_tmp>-guid_hu = <fs_hutree>-guid_parent.
    ENDIF.
  ENDLOOP.


  APPEND LINES OF lt_guid_hu_tmp TO lt_guid_hu.


  LOOP AT lt_huhdr ASSIGNING FIELD-SYMBOL(<fs_huhdr>).
    DATA(lv_tabix) = sy-tabix.
    READ TABLE lt_guid_hu TRANSPORTING NO FIELDS
    WITH KEY
     guid_hu = <fs_huhdr>-guid_hu.
    IF sy-subrc <> 0.
      DELETE lt_huhdr INDEX lv_tabix.
    ENDIF.
  ENDLOOP.


  CREATE OBJECT o_appl_log
    EXPORTING
      iv_log_object    = 'ZEWM_RETURNEDHU'
      iv_log_subobject = ''
      iv_mess_id       = 'ZEWM_RETURNEDHU'.
  o_appl_log->create_app_log( ).

  LOOP AT lt_huhdr ASSIGNING <fs_huhdr>. "Перебор EО для запаса

    APPEND INITIAL LINE TO lt_xid ASSIGNING FIELD-SYMBOL(<fs_xid>).
    <fs_xid>-mandt = sy-mandt.
    <fs_xid>-guid_hu = <fs_huhdr>-guid_hu.
    <fs_xid>-idart = 'R'.
    <fs_xid>-huident = <fs_huhdr>-huident.
    <fs_xid>-updkz = 'I'.


    o_appl_log->add_inform( no = 000            
                            v1 = <fs_huhdr>-huident ).


  ENDLOOP. 

  o_appl_log->save_app_log( ).

  SORT lt_xid BY mandt guid_hu idart huident updkz.
  DELETE ADJACENT DUPLICATES FROM lt_xid COMPARING ALL FIELDS.

  IF lt_xid[] IS INITIAL.
    RETURN.
  ENDIF.

  SELECT *
        FROM /scwm/hu_ident
        INTO TABLE @DATA(lt_huident)
        FOR ALL ENTRIES IN @lt_xid
        WHERE
    guid_hu = @lt_xid-guid_hu
       AND
    huident = @lt_xid-huident
          AND
      idart = @lt_xid-idart.


  LOOP AT lt_xid ASSIGNING <fs_xid>.
    DATA(lv_tabix2) = sy-tabix.
    READ TABLE lt_huident TRANSPORTING NO FIELDS
    WITH KEY
     guid_hu = <fs_xid>-guid_hu
     huident = <fs_xid>-huident
     idart = <fs_xid>-idart.

    IF sy-subrc IS INITIAL.
      DELETE lt_xid INDEX lv_tabix2.
    ENDIF.

  ENDLOOP.

  IF lt_xid[] IS INITIAL.
    RETURN.
  ENDIF.

  CALL FUNCTION '/SCWM/HU_POST'
    EXPORTING
      it_xid = lt_xid.
  CLEAR lt_xid.
  CLEAR lt_huident.
ENDFUNCTION.