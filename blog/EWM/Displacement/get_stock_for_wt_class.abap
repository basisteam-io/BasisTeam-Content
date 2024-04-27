 METHOD get_stock_for_wt.
    DATA: ls_huhdr  TYPE /scwm/s_huhdr_int,
          lt_huhdr  TYPE /scwm/tt_huhdr_int,
          lt_ident  TYPE /scwm/tt_ident_int,
          lt_huitm  TYPE /scwm/tt_huitm_int,
          lt_hutree TYPE /scwm/tt_hutree.
    "
    IF mv_qty_req > mv_qty_total.
      CLEAR rs_data.
      RAISE EXCEPTION TYPE zcx_ewm.
    ENDIF.
    "
    WHILE mv_qty_req > mv_qty_min AND mt_available_stock IS NOT INITIAL AND mv_qty_min IS NOT INITIAL.
      SORT mt_available_stock BY quan DESCENDING.
      LOOP AT mt_available_stock INTO DATA(ls_available_stock) WHERE quan < mv_qty_req.
        mv_qty_req = mv_qty_req - ls_available_stock-quan.
        DELETE mt_available_stock.
        calc_min_max( ).
        EXIT.
      ENDLOOP.
    ENDWHILE.
    CHECK mt_available_stock[] IS NOT INITIAL.
    "
    IF mv_qty_req < mv_qty_min AND mv_qty_min IS NOT INITIAL.
      SORT mt_available_stock BY quan.
      ls_available_stock = mt_available_stock[ 1 ].
      "
      IF is_lgtyp_pick( iv_lgnum = ls_available_stock-lgnum
                        iv_lgtyp = ls_available_stock-lgtyp ) = abap_true.
        CLEAR rs_data.
        RAISE EXCEPTION TYPE zcx_ewm.
      ELSE.
        rs_data-lgtyp_pick = get_lgtyp_pick(  iv_lgnum      = ls_available_stock-lgnum
                                              iv_lgtyp      = ls_available_stock-lgtyp ).

        rs_data-lgtyp   = ls_available_stock-lgtyp.
        rs_data-lgpla   = ls_available_stock-lgpla.
        rs_data-qty_req = mv_qty_req.
        rs_data-aisle   = ls_available_stock-aisle.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.      