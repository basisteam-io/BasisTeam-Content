FUNCTION ZFM_EWM107_OPENHU_SINGLE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_HUIDENT_SINGLE)
*"  EXPORTING
*"     REFERENCE(EV_OPENHU_SINGLE) TYPE  XFLAG
*"  EXCEPTIONS
*"      HUIDENT_NOT_FOUND
*"----------------------------------------------------------------------


    DATA:
    lt_openned_nested_hu TYPE ztt_ewm107_openn,
    lv_huident_single           TYPE /scwm/huident,
    lt_ordim_c           TYPE /scwm/tt_ordim_c,
    lt_hutree            TYPE /scwm/tt_hutree,
    lt_huitm             TYPE /scwm/tt_huitm_int,
    lt_huhdr             TYPE /scwm/tt_huhdr_int,
    lr_huident           TYPE rseloption.


  FIELD-SYMBOLS:
  <ls_ordim_c>     TYPE /scwm/ordim_c.

  lv_huident_single = iv_huident_single.
  ev_openhu_single = abap_false.


  CALL FUNCTION '/SCWM/TO_READ_HU'
        EXPORTING
          iv_lgnum       = 'VL01'
          iv_huident     = lv_huident_single
        IMPORTING
          et_ordim_c_src = lt_ordim_c
        EXCEPTIONS
          other          = 99.

      IF sy-subrc <> 0.
        RAISE huident_not_found.
      ENDIF.


      LOOP AT lt_ordim_c ASSIGNING <ls_ordim_c>."Перебор складских задач

* Отбор сырья происходит в складском месте PBSPIS
* Вскрытая ЕО (ЕО с отбором проб) - это ЕО для которой
* Сушествует выполненная складская задача:
* /SCWM/ORDIM_C-TOSTAT = 'C'
* У которой:
*  /SCWM/ORDIM_C-NLPLA = 'PBSPIS'
* Принимающее складское место - комната отбора проб PBSPIS
* /SCWM/ORDIM_C-NLPLA = 'PBSPIS'
* ЕО источник и ЕО приёмник разные,
* т.е это не перемещение в PBSPIS, а отбор:
* /SCWM/ORDIM_C-VLENR < > /SCWM/ORDIM_C-NLENR

        IF <ls_ordim_c>-tostat = 'C' AND <ls_ordim_c>-nlpla = 'PBSPIS' "Был отбор
          AND <ls_ordim_c>-vlenr NE <ls_ordim_c>-nlenr.
          ev_openhu_single = abap_true.
        ENDIF."Был отбор
         ENDLOOP.   "Перебор складских задач

ENDFUNCTION.