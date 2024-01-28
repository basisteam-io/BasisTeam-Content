*&---------------------------------------------------------------------*
*&      Form  DIVIDE_INTO_2_LISTS
*&---------------------------------------------------------------------*
* 1.2.1. List of needs for products without batches - a list of unique PRODUCTNO,
*compiled based on records for which the BATCHNO parameter is not filled in
* 1.2.2. List of needs by product with batches - list of unique combinations
*PRODUCTNO – BATCHNO, compiled from records for which BATCHNO is not filled in and PRODUCTNO
*not included in list 1.2.1.
*----------------------------------------------------------------------*
FORM divide_into_2_lists  USING    pt_data_out TYPE /scwm/tt_wip_whritem_out
                          CHANGING ct_prd_btch TYPE tty_product_butch
                                   ct_prd      TYPE tty_product.

  DATA: ls_prd_btch TYPE ty_product_butch,
        ls_prd      TYPE ty_product.

  FIELD-SYMBOLS: <fs_data_out> LIKE LINE OF pt_data_out.

  LOOP AT pt_data_out ASSIGNING <fs_data_out>.
    CLEAR: ls_prd_btch, ls_prd.

    IF <fs_data_out>-batchno IS NOT INITIAL.
      MOVE-CORRESPONDING <fs_data_out> TO ls_prd_btch.
      COLLECT ls_prd_btch INTO ct_prd_btch.
    ELSE.
      MOVE-CORRESPONDING <fs_data_out> TO ls_prd.
      COLLECT ls_prd INTO ct_prd.
    ENDIF.
  ENDLOOP.

  SORT ct_prd_btch BY productno batchno.

ENDFORM.