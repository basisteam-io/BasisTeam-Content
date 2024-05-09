METHOD get_available_stock.
    DATA: lr_matnr          TYPE RANGE OF /scwm/de_matnr,
          lr_charg          TYPE RANGE OF /scwm/de_charg,
          lr_lgtyp          TYPE /scwm/tt_lgtyp_r,
          lt_stock_mon_btch TYPE /scwm/tt_stock_mon,
          lt_stock_mon      TYPE /scwm/tt_stock_mon.

    lr_lgtyp = VALUE #( FOR lgtyp IN mt_lgtyp_c ( sign    = rs_c_range_sign-including
                                                  option  = rs_c_range_opt-equal
                                                  low     = lgtyp-lgtyp ) ).
    IF it_prd_btch IS NOT INITIAL.
      LOOP AT it_prd_btch ASSIGNING FIELD-SYMBOL(<ls_prd_btch>).
        APPEND VALUE #( sign    = rs_c_range_sign-including
                        option  = rs_c_range_opt-equal
                        low     = <ls_prd_btch>-productno ) TO lr_matnr.

        APPEND VALUE #( sign    = rs_c_range_sign-including
                        option  = rs_c_range_opt-equal
                        low     = <ls_prd_btch>-batchno ) TO lr_charg.
      ENDLOOP.

      SORT: lr_matnr, lr_charg.
      DELETE ADJACENT DUPLICATES FROM: lr_matnr, lr_charg.

      DATA(lo_mon_stock) = NEW /scwm/cl_mon_stock( ms_input-lgnum ).


      lo_mon_stock->get_available_stock( EXPORTING  iv_skip_bin      = abap_false
                                                    iv_skip_resource = abap_true
                                                    iv_skip_tu       = abap_true
                                                    it_matnr_r       = lr_matnr[]
                                                    it_charg_r       = lr_charg[]
                                                    it_lgtyp_r       = lr_lgtyp[]
                                         IMPORTING  et_stock_mon     = lt_stock_mon_btch ).

      rt_data = CORRESPONDING #( lt_stock_mon_btch MAPPING  unit        = meins "#EC ENHOK
                                                            cat_txt     = cat_text
                                                            doccat      = stref_doccat
                                                            stock_docno = stock_docno_ext ).
    ENDIF.

    IF it_prd IS NOT INITIAL.
      CLEAR: lr_matnr.
      lr_matnr = VALUE #( FOR mat IN it_prd ( sign    = rs_c_range_sign-including
                                              option  = rs_c_range_opt-equal
                                              low     = mat-productno ) ).
      SORT: lr_matnr.
      DELETE ADJACENT DUPLICATES FROM: lr_matnr.

      lo_mon_stock->get_available_stock( EXPORTING  iv_skip_bin      = abap_false
                                                    iv_skip_resource = abap_true
                                                    iv_skip_tu       = abap_true
                                                    it_matnr_r       = lr_matnr[]
                                                    it_lgtyp_r       = lr_lgtyp[]
                                         IMPORTING  et_stock_mon     = lt_stock_mon ).

      LOOP AT lt_stock_mon ASSIGNING FIELD-SYMBOL(<ls_stock_mon>).
        IF NOT line_exists( lt_stock_mon_btch[ matnr = <ls_stock_mon>-matnr
                                               charg = <ls_stock_mon>-charg ] ).
          APPEND CORRESPONDING #( <ls_stock_mon> MAPPING  unit        = meins "#EC ENHOK
                                                          cat_txt     = cat_text
                                                          doccat      = stref_doccat
                                                          stock_docno = stock_docno_ext ) TO rt_data.
        ENDIF.
      ENDLOOP.
    ENDIF.


    IF rt_data IS INITIAL.
      MESSAGE e009 INTO DATA(lv_error).
      RAISE EXCEPTION TYPE zcx_ewm
        EXPORTING
          textid = CORRESPONDING #( sy ).
    ENDIF.
  ENDMETHOD.