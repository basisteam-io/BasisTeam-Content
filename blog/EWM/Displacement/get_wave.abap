*&---------------------------------------------------------------------*
*&      Form  GET_WAVE
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM get_wave CHANGING ct_docs TYPE tty_docnr.

  DATA: lt_tab_range  TYPE rsds_trange,
        ls_tab_range  LIKE LINE OF lt_tab_range,
        ls_frange_t   LIKE LINE OF ls_tab_range-frange_t,
        lv_returncode TYPE xfeld,
        lv_variant    TYPE variant,
        lt_data_wave  TYPE /scwm/tt_waveitm_det_mon_out,
        lt_selopt     TYPE rsds_selopt_t,
        wa_selopt     TYPE rsdsselopt,
        ls_docn       LIKE LINE OF ct_docs.

  FIELD-SYMBOLS: <fs_data_wave> LIKE LINE OF lt_data_wave.

  ls_frange_t-fieldname = 'WAVE'.

  CLEAR: lt_selopt, wa_selopt.

  LOOP AT s_wave INTO DATA(wa_wave).
    wa_selopt-sign    = wa_wave-sign.
    wa_selopt-option  = wa_wave-option.
    MOVE wa_wave-low TO wa_selopt-low  .
    MOVE wa_wave-high TO wa_selopt-high .
    APPEND wa_selopt TO lt_selopt.
  ENDLOOP.

  ls_frange_t-selopt_t = lt_selopt.
  APPEND ls_frange_t TO ls_tab_range-frange_t.
  ls_tab_range-tablename = '/SCWM/WAVEHDR'.
  APPEND ls_tab_range TO lt_tab_range.

  CALL FUNCTION '/SCWM/WAVEHDR_ITM_MON'
    EXPORTING
      iv_lgnum      = p_lgnum " WH number
      iv_mode       = '2'
    IMPORTING
      ev_returncode = lv_returncode
      ev_variant    = lv_variant
      et_data       = lt_data_wave
    CHANGING
      ct_tab_range  = lt_tab_range. " Wave numbers

  DELETE lt_data_wave WHERE rdoccat <> 'PDO'.

  LOOP AT lt_data_wave ASSIGNING <fs_data_wave>.
    ls_docn(3) = 'IEQ'.
    ls_docn-low = <fs_data_wave>-docno.
    APPEND ls_docn TO ct_docs.
  ENDLOOP.

ENDFORM.