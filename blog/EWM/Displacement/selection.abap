 METHOD selection.
    DATA: lr_docn  TYPE ty_docnr,
          lt_lagp  TYPE /scwm/tt_lagp,
          lv_aisle TYPE /scwm/lagp-aisle,
          lv_dummy TYPE c.

* 1. If the “Wave” report input parameter is filled in, search for wave positions by wave numbers and warehouse number
    IF ms_input-wave IS NOT INITIAL.
      APPEND LINES OF get_wave( ) TO lr_docn.
      SORT lr_docn.
      DELETE ADJACENT DUPLICATES FROM lr_docn.
    ENDIF.
* 2.  If deliveries are found by wave, then filter by data from the screen; if the “Wave” parameter is not specified, then add delivery numbers from the screen
    IF lr_docn IS INITIAL.
      APPEND LINES OF ms_input-docno TO lr_docn.
    ELSE.
      DELETE lr_docn WHERE low NOT IN ms_input-docno.
    ENDIF.
*3.	If deliveries were not found, then we look for the picking status *Not started* for the period specified on the screen or the default period.
    IF lr_docn IS INITIAL.
      APPEND LINES OF get_zerogi_delivery( ) TO lr_docn.
    ENDIF.
*4. If supplies are not found, we complete the method
    IF lr_docn IS INITIAL.
      MESSAGE e002 INTO DATA(lv_error).
      RAISE EXCEPTION TYPE zcx_ewm
        EXPORTING
          textid = CORRESPONDING #( sy ).
    ENDIF.
*5.Search for outbound delivery order items (lines)
    DATA(lt_data)     = get_delivery_item( lr_docn ).

*6. After executing the query, you need to create 2 lists from its result
    DATA(lt_prd_btch) = get_item_with_batch( lt_data ).
    DATA(lt_prd)      = get_item_with_out_batch( lt_data ).

*7. Search for available stock in warehouse
    DATA(lt_data_stock) = get_available_stock( it_prd_btch = lt_prd_btch
                                               it_prd      = lt_prd ).

*8. Perform storage bin check
    read_multiple_storage_bins( CHANGING ct_lgpla = lt_data_stock
                                         ct_lagp  = lt_lagp ).
*9. We sort out the available stock according to the product lists.
    set_stock_with_batch( it_stock = lt_data_stock
                          it_data  = lt_prd_btch ).
    set_stock_with_out_batch( it_stock    = lt_data_stock
                              it_prd_btch = lt_prd_btch
                              it_data     = lt_prd ).
*10. Make a list of places (stocks) in the storage area from which warehouse tasks for picking boxes will be created.
    DATA(lt_stock_for_wt) = get_stock_for_wt( it_prd_btch = lt_prd_btch
                                              it_prd      = lt_prd
                                              it_lagp     = lt_lagp ).

    mt_main_data = get_displacement_bins( CHANGING ct_pickdispl  = lt_stock_for_wt ).

  ENDMETHOD.