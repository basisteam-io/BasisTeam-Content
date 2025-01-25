*&---------------------------------------------------------------------*
*& Report GET_STOCK_DATA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT get_stock_data.

INCLUDE get_stock_data_top.

SELECT-OPTIONS:
  s_sscc  FOR l_sscc_sel NO INTERVALS,
  s_gtin  FOR gs_scr-gtin NO INTERVALS,
  s_sgtin FOR gs_scr-sgtin NO INTERVALS,
  s_lotno FOR gs_scr-lotno NO INTERVALS,
  s_docs  FOR gs_scr-docnum NO INTERVALS.

PARAMETERS:
  p_exact AS CHECKBOX, 
  p_ewm_f AS CHECKBOX,    
  p_sgtin AS CHECKBOX,    
  p_nbrct AS CHECKBOX,    
  p_cont  TYPE flag RADIOBUTTON GROUP gr1 DEFAULT 'X',
  p_stat  TYPE flag RADIOBUTTON GROUP gr1,
  p_docs  TYPE flag RADIOBUTTON GROUP gr1.

*--------------------------------------------------------------------*
START-OF-SELECTION.

  IF s_sscc IS NOT INITIAL
    OR s_gtin IS NOT INITIAL
    OR s_sgtin IS NOT INITIAL
    OR s_lotno IS NOT INITIAL
    OR s_docs IS NOT INITIAL.

    LOOP AT s_sscc INTO DATA(ls_s_sscc).
      APPEND INITIAL LINE TO et_sscc ASSIGNING FIELD-SYMBOL(<fs_sscc>).
      DATA(lv_strlen) = strlen( ls_s_sscc-low ).
      IF lv_strlen < 20.
        "convert to char20
        l_char20 = |{ ls_s_sscc-low ALPHA = IN }|.
        <fs_sscc> = l_char20.
      ELSE.
        <fs_sscc> = ls_s_sscc-low.
      ENDIF.
    ENDLOOP.

    IF s_docs IS NOT INITIAL.
      "pre read assigned SSCC to entered docs, add to SSCC list
      LOOP AT s_docs INTO DATA(ls_s_docs).
        CALL FUNCTION 'ZTT_INT_GET_DOC_OBJ'
          EXPORTING
            iv_doctpe          = l_doctpe
            iv_docnum          = ls_s_docs-low
            iv_read_not_native = 'X'    
          IMPORTING
            et_object          = it_docs_sscc.
        IF it_docs_sscc IS NOT INITIAL.
          APPEND LINES OF it_docs_sscc TO et_sscc.
        ENDIF.
      ENDLOOP.
    ENDIF.

    CASE 'X'.
      WHEN p_cont.

        IF p_sgtin IS NOT INITIAL.
          CALL FUNCTION 'ZGET_STOCK_DATA'
            EXPORTING
              it_sscc            = et_sscc
              it_gtin            = s_gtin[]
              it_sgtin           = s_sgtin[]
              it_lotno           = s_lotno[]
              iv_format_for_ewm  = p_ewm_f
              iv_exact_sscc_box  = p_exact
              iv_exact_sgtin_box = p_sgtin
              iv_nbrct           = p_nbrct
            IMPORTING
              et_stock_sgtin     = gt_stock_sgtin.

          ls_layout-colwidth_optimize = 'X'.
          ls_layout-numc_sum = 'X'. "enable total

          lt_sort = VALUE #(
            ( spos = 1 fieldname = 'SSCC_PAL' down = 'X' )
            ( spos = 2 fieldname = 'SSCC_BOX' down = 'X' )
            ).

          ls_variant-report = sy-repid.
          ls_variant-handle = '4'.
          "LOG_GROUP

          CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
            EXPORTING
              i_structure_name = 'ZTT_S_STOCK_SGTIN'
              is_layout        = ls_layout
              it_sort          = lt_sort
              i_save           = 'A'
              is_variant       = ls_variant
            TABLES
              t_outtab         = gt_stock_sgtin.
          RETURN.
        ELSE.
          CALL FUNCTION 'ZGET_STOCK_DATA'
            EXPORTING
              it_sscc           = et_sscc
              it_gtin           = s_gtin[]
              it_lotno          = s_lotno[]
              iv_format_for_ewm = p_ewm_f
              iv_exact_sscc_box = p_exact
              iv_nbrct          = p_nbrct
            IMPORTING
              et_stock          = gt_stock.

          ls_layout-colwidth_optimize = 'X'.
          ls_layout-numc_sum = 'X'. "enable total

          lt_sort = VALUE #(
            ( spos = 1 fieldname = 'SSCC_PAL' down = 'X' )
            ( spos = 2 fieldname = 'SSCC_BOX' down = 'X' )
          ).

          ls_variant-report = sy-repid.
          ls_variant-handle = '1'.
   

          CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
            EXPORTING
              i_structure_name = 'ZTT_S_STOCK'
              is_layout        = ls_layout
              it_sort          = lt_sort
              i_save           = 'A'
              is_variant       = ls_variant
            TABLES
              t_outtab         = gt_stock.
          RETURN.
        ENDIF.
      WHEN p_stat.
        IF et_sscc IS NOT INITIAL.
          CALL FUNCTION 'ZGET_STOCK_DATA'
            EXPORTING
              it_sscc           = et_sscc
              iv_format_for_ewm = p_ewm_f
              iv_exact_sscc_box = p_exact
              iv_only_statuses  = 'X'
              iv_get_stat_desc  = 'X'
              iv_nbrct          = p_nbrct
            IMPORTING
              et_statuses       = gt_statuses.

          ls_layout-colwidth_optimize = 'X'.
          ls_layout-numc_sum = 'X'. "enable total

          ls_variant-report = sy-repid.
          ls_variant-handle = '2'.

          CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
            EXPORTING
              i_structure_name = 'ZTT_S_STOCK_STATUS'
              is_layout        = ls_layout
              i_save           = 'A'
              is_variant       = ls_variant
            TABLES
              t_outtab         = gt_statuses.

          RETURN.

        ENDIF.
      WHEN p_docs.
        IF et_sscc IS NOT INITIAL.

          CALL FUNCTION 'ZGET_STOCK_DATA'
            EXPORTING
              it_sscc           = et_sscc
              iv_format_for_ewm = p_ewm_f
              iv_exact_sscc_box = p_exact
              iv_get_docs       = 'X'
              iv_nbrct          = p_nbrct
            IMPORTING
              et_docs           = gt_docs.

          LOOP AT gt_docs ASSIGNING FIELD-SYMBOL(<fs_docs>).
            IF <fs_docs>-sscc_pal = <fs_docs>-sscc_box.
              CLEAR: <fs_docs>-sscc_box.
            ENDIF.
          ENDLOOP.

          ls_layout-colwidth_optimize = 'X'.
          ls_layout-numc_sum = 'X'. "enable total

          lt_sort = VALUE #(
            ( spos = 1 fieldname = 'SSCC_PAL' down = 'X' )
            ( spos = 2 fieldname = 'SSCC_BOX' down = 'X' )
            ( spos = 3 fieldname = 'DOCNUM' down = 'X' )
          ).

          ls_variant-report = sy-repid.
          ls_variant-handle = '3'.

          CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
            EXPORTING
              i_structure_name = 'ZTT_S_SSCC_DOCNUM'
              is_layout        = ls_layout
              it_sort          = lt_sort
              i_save           = 'A'
              is_variant       = ls_variant
            TABLES
              t_outtab         = gt_docs.

          RETURN.

        ENDIF.

    ENDCASE.

  ENDIF.