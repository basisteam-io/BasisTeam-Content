 METHOD get_available_stock.
    DATA: lr_matnr       TYPE RANGE OF /scwm/de_matnr.


    lr_matnr = VALUE #( FOR mat IN it_prd ( sign    = rs_c_range_sign-including
*                                            option  = rs_c_range_opt-notequal
                                            option  = rs_c_range_opt-equal
                                            low     = mat-productno ) ).

    lr_matnr = VALUE #( BASE lr_matnr FOR mat_btch IN it_prd_btch ( sign    = rs_c_range_sign-including
*                                                                    option  = rs_c_range_opt-notequal
                                                                    option  = rs_c_range_opt-equal
                                                                    low     = mat_btch-productno ) ).

    SORT lr_matnr.
    DELETE ADJACENT DUPLICATES FROM lr_matnr.


    DATA: lt_stock_mon TYPE /scwm/tt_stock_mon.

    NEW /scwm/cl_mon_stock( ms_input-lgnum )->get_available_stock( EXPORTING  iv_skip_bin      = abap_false
                                                                              iv_skip_resource = abap_true
                                                                              iv_skip_tu       = abap_true
                                                                              it_matnr_r       = lr_matnr[]
                                                                   IMPORTING  et_stock_mon     = lt_stock_mon ).

    rt_data = CORRESPONDING #( lt_stock_mon MAPPING unit        = meins               "#EC ENHOK
                                                    cat_txt     = cat_text
                                                    doccat      = stref_doccat
                                                    stock_docno = stock_docno_ext ).

    IF rt_data IS INITIAL.
      MESSAGE e009 INTO DATA(lv_error).
      RAISE EXCEPTION TYPE zcx_ewm
        EXPORTING
          textid = CORRESPONDING #( sy ).
    ENDIF.
  ENDMETHOD.
