 METHOD get_stock_for_wt.
    CLEAR: rt_data[].
    LOOP AT it_prd_btch ASSIGNING FIELD-SYMBOL(<ls_prd_btch>).
      TRY .
          rt_data = VALUE #( BASE rt_data ( <ls_prd_btch>-ref->get_stock_for_wt( ) ) ).
        CATCH zcx_ewm.
          CONTINUE.
      ENDTRY.
    ENDLOOP.
    LOOP AT it_prd ASSIGNING FIELD-SYMBOL(<ls_prd>).
      TRY .
          rt_data = VALUE #( BASE rt_data ( <ls_prd>-ref->get_stock_for_wt( ) ) ).
        CATCH zcx_ewm.
          CONTINUE.
      ENDTRY.
    ENDLOOP.
    SORT rt_data.
  ENDMETHOD.