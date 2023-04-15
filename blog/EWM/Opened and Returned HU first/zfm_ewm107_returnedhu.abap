FUNCTION zfm_ewm107_returnedhu.
*"----------------------------------------------------------------------

*"  IMPORTING
*"     REFERENCE(IV_HUIDENT) TYPE  /SCWM/HUIDENT
*"  EXPORTING
*"     REFERENCE(EV_RETURNEDHU) TYPE  XFLAG
*"     REFERENCE(ET_RETURNED_NESTED_HU) TYPE  ZTT_EWM109_RETUR
*"----------------------------------------------------------------------

" Returned

  DATA:

    lv_huident            TYPE /scwm/huident,
    lt_hutree             TYPE /scwm/tt_hutree,
    lt_huhdr              TYPE /scwm/tt_huhdr_int,
    lt_returned_nested_hu TYPE ztt_ewm109_retur,
    lt_huref              TYPE /scwm/tt_huref_int,
    lr_huident            TYPE rseloption,
    lv_returnedhu         TYPE xflag.

  CLEAR:
     et_returned_nested_hu.


  lv_huident = iv_huident.
  ev_returnedhu = abap_false.

* Nested HU

  lr_huident = VALUE #( ( sign = 'I' option = 'EQ' low = lv_huident ) ).

  CALL FUNCTION '/SCWM/HU_SELECT_GEN'
    EXPORTING
      ir_huident   = lr_huident
    IMPORTING
      et_huhdr     = lt_huhdr
      et_hutree    = lt_hutree
    EXCEPTIONS
      wrong_input  = 1
      not_possible = 2
      error        = 99.

  IF sy-subrc <> 0.
    EXIT.
  ENDIF.

  READ TABLE lt_huhdr ASSIGNING FIELD-SYMBOL(<fs_huhdr>) WITH KEY huident = lv_huident.

  IF <fs_huhdr>-bottom IS NOT INITIAL. "Bottom-lvl.


    CALL FUNCTION 'ZFM_EWM109_RETURNEDHU_SINGLE'
      EXPORTING
        iv_huident_single    = lv_huident
      IMPORTING
        ev_returnedhu_single = lv_returnedhu
      EXCEPTIONS
        other                = 99.

    " Bottom-lvl
    IF lv_returnedhu = abap_true.
      ev_returnedhu = abap_true.
    ENDIF.

  ELSE. 

    LOOP AT lt_huhdr ASSIGNING FIELD-SYMBOL(<fs_huhdr_int>).

      IF <fs_huhdr_int>-bottom IS NOT INITIAL. 

        CALL FUNCTION 'ZFM_EWM109_RETURNEDHU_SINGLE'
          EXPORTING
            iv_huident_single    = <fs_huhdr_int>-huident
          IMPORTING
            ev_returnedhu_single = lv_returnedhu
          EXCEPTIONS
            other                = 99.


        IF lv_returnedhu = abap_true.           
          ev_returnedhu = abap_true.
          APPEND INITIAL LINE TO lt_returned_nested_hu ASSIGNING FIELD-SYMBOL(<fs_returned_nested_hu>).
          <fs_returned_nested_hu>-huident_nested = <fs_huhdr_int>-huident.
        ENDIF. 
      ENDIF.  
    ENDLOOP. 

    DELETE ADJACENT DUPLICATES FROM lt_returned_nested_hu COMPARING huident_nested.
    et_returned_nested_hu = lt_returned_nested_hu.
    CLEAR lt_returned_nested_hu.

  ENDIF.

ENDFUNCTION.