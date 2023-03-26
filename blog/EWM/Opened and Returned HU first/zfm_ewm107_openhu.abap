FUNCTION zfm_ewm107_openhu.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_HUIDENT) TYPE  /SCWM/HUIDENT
*"  EXPORTING
*"     REFERENCE(EV_OPENHU) TYPE  XFLAG
*"     REFERENCE(ET_OPEN_NESTED_HU) TYPE  ZTT_EWM107_OPENN
*"  EXCEPTIONS
*"      HUIDENT_NOT_FOUND
*"----------------------------------------------------------------------


  DATA:
    lt_openned_nested_hu TYPE ztt_ewm107_openn,
    lv_huident           TYPE /scwm/huident,
    lt_ordim_c           TYPE /scwm/tt_ordim_c,
    lt_hutree            TYPE /scwm/tt_hutree,
    lt_huitm             TYPE /scwm/tt_huitm_int,
    lt_huhdr             TYPE /scwm/tt_huhdr_int,
    lr_huident           TYPE rseloption,
    lv_openhu            TYPE xflag.




  FIELD-SYMBOLS:
  <ls_ordim_c>     TYPE /scwm/ordim_c.

  lv_huident = iv_huident.
  ev_openhu = abap_false.


  CLEAR:
     et_open_nested_hu.

* Определим вложенность для ЕО

  lr_huident = VALUE #( ( sign = 'I' option = 'EQ' low = lv_huident ) ).

  CALL FUNCTION '/SCWM/HU_SELECT_GEN'
    EXPORTING
      ir_huident   = lr_huident
    IMPORTING
      et_huitm     = lt_huitm
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

  IF <fs_huhdr>-bottom IS NOT INITIAL. "Это ТМ, TMK. Вложеность определять не нужно.



    CALL FUNCTION 'ZFM_EWM107_OPENHU_SINGLE'
      EXPORTING
        iv_huident_single = lv_huident
      IMPORTING
        ev_openhu_single  = lv_openhu
      EXCEPTIONS
        other             = 99.

    " ЕО нижнего уровня вскрыта, возвращаем признак вскрытой ЕО
    IF lv_openhu = abap_true.
      ev_openhu = abap_true.
    ENDIF.



  ELSEIF <fs_huhdr>-bottom IS INITIAL. " "Это паллета. Перебираем ЕО на паллете

    LOOP AT lt_huhdr ASSIGNING FIELD-SYMBOL(<fs_huhdr_int>).

      IF <fs_huhdr_int>-bottom IS NOT INITIAL. " работаем только с ТМ на паллете

        CALL FUNCTION 'ZFM_EWM107_OPENHU_SINGLE'
          EXPORTING
            iv_huident_single = <fs_huhdr_int>-huident
          IMPORTING
            ev_openhu_single  = lv_openhu
          EXCEPTIONS
            other             = 99.


        IF lv_openhu = abap_true. " Вложенная ЕО вскрыта
          " Возвращаем признак вскрытой
          ev_openhu = abap_true.
          " Готовим список вскрытых вложенных ЕО
          APPEND INITIAL LINE TO lt_openned_nested_hu ASSIGNING FIELD-SYMBOL(<fs_openned_nested_hu>).
          <fs_openned_nested_hu>-huident_nested = <fs_huhdr_int>-huident.
        ENDIF. " Вложенная ЕО вскрыта
      ENDIF.  " Работаем только с ТМ на паллете
    ENDLOOP. " Перебор EО вложености

    DELETE ADJACENT DUPLICATES FROM lt_openned_nested_hu COMPARING huident_nested.
    et_open_nested_hu = lt_openned_nested_hu.
    CLEAR lt_openned_nested_hu.

  ENDIF." Это паллета


ENDFUNCTION.