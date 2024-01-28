*&---------------------------------------------------------------------*
*&      Form  GET_DELIVERY_ITEM
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM get_delivery_item USING pt_docs     TYPE tty_docnr
                    CHANGING ct_data_out TYPE /scwm/tt_wip_whritem_out.

  DATA: lt_tab_range  TYPE rsds_trange,
        ls_tab_range  LIKE LINE OF lt_tab_range,
        ls_frange_t   LIKE LINE OF ls_tab_range-frange_t,
        lv_returncode TYPE xfeld,
        lv_variant    TYPE variant,
        ls_data_out   LIKE LINE OF ct_data_out.

  DATA: lr_date LIKE ls_frange_t-selopt_t,
        ls_date LIKE LINE OF lr_date,
        lr_coml TYPE RANGE OF /scwm/sp_stm_pl_picking_value.

  ls_date(3)   = 'IBT'.
  ls_date-low  = p_datfr && p_timfr.
  ls_date-high = p_datto && p_timto.
  APPEND ls_date TO lr_date.

  APPEND 'IEQ1' TO lr_coml.
  APPEND 'IEQ2' TO lr_coml.

  CLEAR: lt_tab_range[].
  ls_frange_t-fieldname  = 'DOCNO_H'.
  ls_frange_t-selopt_t[] = s_docno[].               
  APPEND LINES OF pt_docs TO ls_frange_t-selopt_t. 
  APPEND ls_frange_t TO ls_tab_range-frange_t.

  ls_frange_t-fieldname  = 'TSTFR_TDELIVERY_PLAN_H'.
  ls_frange_t-selopt_t[] = lr_date[].
  APPEND ls_frange_t TO ls_tab_range-frange_t.


  ls_frange_t-fieldname  = 'STATUS_VALUE_DER_I'.
  ls_frange_t-selopt_t[] = lr_coml[].
  APPEND ls_frange_t TO ls_tab_range-frange_t.

  ls_tab_range-tablename = '/SCWM/S_WIP_Q_WHR_OUTBOUND'.
  APPEND ls_tab_range TO lt_tab_range.

  CALL FUNCTION '/SCWM/WHRITEM_MON_OUT'
    EXPORTING
      iv_lgnum      = p_lgnum 
      iv_mode       = '2'
    IMPORTING
      ev_returncode = lv_returncode
      ev_variant    = lv_variant
      et_data       = ct_data_out
    CHANGING
      ct_tab_range  = lt_tab_range.
ENDFORM.