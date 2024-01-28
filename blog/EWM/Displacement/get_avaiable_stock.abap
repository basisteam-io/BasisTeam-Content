*&---------------------------------------------------------------------*
*&      Form  GET_AVAILABLE_STOCK
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM get_available_stock USING pt_prd_btch   TYPE tty_product_butch
                               pt_prd        TYPE tty_product
                      CHANGING ct_data_stock TYPE /scwm/tt_aqua_lagp_mon .

  DATA: lt_tab_range  TYPE rsds_trange,
        ls_tab_range  LIKE LINE OF lt_tab_range,
        ls_frange_t   LIKE LINE OF ls_tab_range-frange_t,
        lv_returncode TYPE xfeld,
        lv_variant    TYPE variant,
        lr_matnr      TYPE RANGE OF /scwm/de_matnr,
        ls_matnr      LIKE LINE OF lr_matnr.

  FIELD-SYMBOLS: <fs_prd>        LIKE LINE OF pt_prd,
                 <fs_prd_btch>   LIKE LINE OF pt_prd_btch,
                 <fs_data_stock> LIKE LINE OF ct_data_stock.

  ls_matnr(3) = 'INE'.
  LOOP AT pt_prd ASSIGNING <fs_prd>.
    ls_matnr-low = <fs_prd>-productno.
    COLLECT ls_matnr INTO lr_matnr.
  ENDLOOP.

* Продукт
  CLEAR: ls_tab_range-frange_t[].
  ls_frange_t-fieldname  = 'MATNR'.
  ls_frange_t-selopt_t[] = lr_matnr[].
  APPEND ls_frange_t TO ls_tab_range-frange_t.

  ls_tab_range-tablename = '/SCWM/AQUA'.
  APPEND ls_tab_range TO lt_tab_range.

  CALL FUNCTION '/SCWM/AVLSTOCK_OVERVIEW_MON'
    EXPORTING
      iv_lgnum      = p_lgnum  
      iv_mode       = '2'
    IMPORTING
      ev_returncode = lv_returncode
      ev_variant    = lv_variant
      et_data       = ct_data_stock
    CHANGING
      ct_tab_range  = lt_tab_range.

  LOOP AT ct_data_stock ASSIGNING <fs_data_stock>.
    READ TABLE pt_prd_btch ASSIGNING <fs_prd_btch> WITH KEY productno = <fs_data_stock>-matnr
                                                            batchno   = <fs_data_stock>-charg.
    IF sy-subrc = 0.
      CLEAR: <fs_data_stock>-matnr, <fs_data_stock>-charg.
    ENDIF.
  ENDLOOP.

  DELETE ct_data_stock WHERE matnr IS INITIAL AND charg IS INITIAL.
ENDFORM.