FORM create_tasks.

  DATA: lt_create_int TYPE /scwm/tt_to_create_int,
        lt_prc        TYPE STANDARD TABLE OF zewm_cleanup_prc,
        lv_tanum      TYPE /scwm/tanum.

  DATA: lt_ltap_vb  TYPE  /scwm/tt_ltap_vb,
        lt_doc      TYPE  /scwm/tt_pdenial_attr,
        lt_bapiret  TYPE  bapirettab,
        lv_severity TYPE  bapi_mtype,
        lv_dummy    TYPE  c,
        lt_huhdr    TYPE  STANDARD TABLE OF /scwm/huhdr.

  FIELD-SYMBOLS: <fs_lines> LIKE LINE OF gt_rows,
                 <fs_creat> LIKE LINE OF lt_create_int,
                 <fs_data>  LIKE LINE OF gt_main_data,
                 <fs_prc>   TYPE zewm_cleanup_prc,
                 <fs_huhdr> TYPE /scwm/huhdr.

  IF gt_main_data[] IS NOT INITIAL.
    SELECT lgnum lgtyp procty
       FROM zewm_cleanup_prc
       INTO CORRESPONDING FIELDS OF TABLE lt_prc
       FOR ALL ENTRIES IN gt_main_data
       WHERE lgnum = gt_main_data-lgnum AND
             lgtyp = gt_main_data-lgtyp.

    SELECT guid_hu huident letyp
      FROM /scwm/huhdr
      INTO CORRESPONDING FIELDS OF TABLE lt_huhdr
      FOR ALL ENTRIES IN gt_main_data
      WHERE huident = gt_main_data-huident.

    SORT lt_prc   BY lgnum lgtyp.
    SORT lt_huhdr BY huident.
  ENDIF.

  IF zcl_tvarvc=>read_parameter( i_name = 'ZEWM_CLEANUP_NEW' ) IS NOT INITIAL.

    DATA lt_create_hu TYPE /scwm/tt_to_crea_hu.
    FIELD-SYMBOLS <fs_create_hu> LIKE LINE OF lt_create_hu.
    IF gt_rows[] IS INITIAL.
      LOOP AT gt_main_data ASSIGNING <fs_data>.
        APPEND INITIAL LINE TO lt_create_hu ASSIGNING <fs_create_hu>.
        MOVE-CORRESPONDING <fs_data> TO <fs_create_hu>.
        READ TABLE lt_prc ASSIGNING <fs_prc> WITH KEY lgnum = <fs_data>-lgnum lgtyp = <fs_data>-lgtyp BINARY SEARCH.
        IF sy-subrc = 0.
          <fs_create_hu>-procty = <fs_prc>-procty.
        ENDIF.


      ENDLOOP.
    ELSE.
      LOOP AT gt_rows ASSIGNING <fs_lines>.
        APPEND INITIAL LINE TO lt_create_hu ASSIGNING <fs_create_hu>.
        READ TABLE gt_main_data ASSIGNING <fs_data> INDEX <fs_lines>.
        IF sy-subrc = 0.
          MOVE-CORRESPONDING <fs_data> TO <fs_create_hu>.
          READ TABLE lt_prc ASSIGNING <fs_prc> WITH KEY lgnum = <fs_data>-lgnum lgtyp = <fs_data>-lgtyp BINARY SEARCH.
          IF sy-subrc = 0.
            <fs_create_hu>-procty = <fs_prc>-procty.
          ENDIF.

        ENDIF.
      ENDLOOP.
    ENDIF.

    CALL FUNCTION '/SCWM/TO_CREATE_MOVE_HU'
      EXPORTING
        iv_lgnum       = p_lgnum
        iv_update_task = 'X'
        iv_commit_work = 'X'
        it_create_hu   = lt_create_hu
      IMPORTING
        ev_tanum       = lv_tanum
        et_ltap_vb     = lt_ltap_vb
        et_bapiret     = lt_bapiret
        ev_severity    = lv_severity.
    .
    IF lv_severity CA 'EXA'.
      MESSAGE s006 INTO lv_dummy. "Task created
      PERFORM move_messg_to_log.
      PERFORM move_messg_to_log2 USING lt_bapiret.
    ELSE.
      MESSAGE s005 INTO lv_dummy WITH lv_tanum. "Task created
      PERFORM move_messg_to_log.
    ENDIF.

    EXIT.

  ENDIF.


  IF gt_rows[] IS INITIAL.
    LOOP AT gt_main_data ASSIGNING <fs_data>.
      APPEND INITIAL LINE TO lt_create_int ASSIGNING <fs_creat>.
      MOVE-CORRESPONDING <fs_data> TO <fs_creat>.
      READ TABLE lt_prc ASSIGNING <fs_prc> WITH KEY lgnum = <fs_data>-lgnum lgtyp = <fs_data>-lgtyp BINARY SEARCH.
      IF sy-subrc = 0.
        <fs_creat>-procty = <fs_prc>-procty.
      ENDIF.

      READ TABLE lt_huhdr ASSIGNING <fs_huhdr> WITH KEY huident = <fs_data>-huident BINARY SEARCH.
      IF sy-subrc = 0.
        <fs_creat>-letyp = <fs_huhdr>-letyp.
      ENDIF.

      <fs_creat>-anfme = <fs_data>-quan.
*      <fs_creat>-letyp = 'E1'.
      <fs_creat>-owner_role = 'BP'.
      <fs_creat>-entitled_role = 'BP'.
      <fs_creat>-vlpla = <fs_data>-lgpla.
*      <fs_creat>-vltyp = <fs_data>-lgtyp.
    ENDLOOP.
  ELSE.
    LOOP AT gt_rows ASSIGNING <fs_lines>.
      APPEND INITIAL LINE TO lt_create_int ASSIGNING <fs_creat>.
      READ TABLE gt_main_data ASSIGNING <fs_data> INDEX <fs_lines>.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING <fs_data> TO <fs_creat>.
        READ TABLE lt_prc ASSIGNING <fs_prc> WITH KEY lgnum = <fs_data>-lgnum lgtyp = <fs_data>-lgtyp BINARY SEARCH.
        IF sy-subrc = 0.
          <fs_creat>-procty = <fs_prc>-procty.
        ENDIF.

        READ TABLE lt_huhdr ASSIGNING <fs_huhdr> WITH KEY huident = <fs_data>-huident BINARY SEARCH.
        IF sy-subrc = 0.
          <fs_creat>-letyp = <fs_huhdr>-letyp.
        ENDIF.

        <fs_creat>-anfme = <fs_data>-quan.
*        <fs_creat>-letyp = 'E1'.
        <fs_creat>-owner_role = 'BP'.
        <fs_creat>-entitled_role = 'BP'.
        <fs_creat>-vlpla = <fs_data>-lgpla.
*        <fs_creat>-vltyp = <fs_data>-lgtyp.
      ENDIF.
    ENDLOOP.
  ENDIF.

  CALL FUNCTION '/SCWM/TO_CREATE'
    EXPORTING
      iv_lgnum    = p_lgnum
      iv_wtcode   = 'T'
      it_create   = lt_create_int
    IMPORTING
      ev_tanum    = lv_tanum
      et_ltap_vb  = lt_ltap_vb
      et_bapiret  = lt_bapiret
      ev_severity = lv_severity.
  IF lv_severity CA 'EXA'.
    MESSAGE s006 INTO lv_dummy. "Task created
    PERFORM move_messg_to_log.
    PERFORM move_messg_to_log2 USING lt_bapiret.
  ELSE.
    MESSAGE s005 INTO lv_dummy WITH lv_tanum. "Task created
    PERFORM move_messg_to_log.
  ENDIF.
ENDFORM.
