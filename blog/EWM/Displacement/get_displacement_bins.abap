  METHOD get_displacement_bins.
    DATA: lr_lgtyp      TYPE RANGE OF /scwm/lgtyp,
          lt_data       TYPE /scwm/tt_lagp_mon,
          lt_displ_bins TYPE /scwm/tt_lagp_mon.

    lr_lgtyp = VALUE #( FOR lg IN ct_pickdispl (  sign    = rs_c_range_sign-including
                                                  option  = rs_c_range_opt-equal
                                                  low     = lg-lgtyp_pick ) ).
    SORT lr_lgtyp.
    DELETE ADJACENT DUPLICATES FROM lr_lgtyp.

    DATA(lt_tab_range) = VALUE rsds_trange( ( tablename = '/SCWM/LAGP'
                                              frange_t  = VALUE rsds_frange_t( ( fieldname  = 'LGTYP'
                                                                                 selopt_t   = lr_lgtyp ) ) ) ).
    TRY.
        CALL FUNCTION '/SCWM/BIN_OVERVIEW_MON'
          EXPORTING
            iv_lgnum     = ms_input-lgnum " wh.number
            iv_mode      = '2'
          IMPORTING
            et_data      = lt_data
          CHANGING
            ct_tab_range = lt_tab_range.
      CATCH /scwm/cx_mon_noexec.    "
        RETURN.
    ENDTRY.

    LOOP AT ct_pickdispl ASSIGNING FIELD-SYMBOL(<ls_pickdispl>).
      LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>) WHERE lgnum = ms_input-lgnum
                                                          AND lgtyp = <ls_pickdispl>-lgtyp_pick
                                                          AND aisle = <ls_pickdispl>-aisle
                                                          AND kzler = abap_true
                                                          AND skzua <> abap_true
                                                          AND skzue <> abap_true.
        DELETE lt_data.
        DELETE TABLE ct_pickdispl FROM <ls_pickdispl>.
        EXIT.
      ENDLOOP.
      IF <ls_pickdispl> IS ASSIGNED AND sy-subrc <> 0.
        LOOP AT lt_data ASSIGNING <ls_data> WHERE lgnum = ms_input-lgnum
                                              AND lgtyp = <ls_pickdispl>-lgtyp_pick
                                              AND aisle = <ls_pickdispl>-aisle
                                              AND kzler <> abap_true
                                              AND skzua <> abap_true
                                              AND skzue <> abap_true.
          APPEND <ls_data> TO lt_displ_bins.
          DELETE lt_data.
          EXIT.
        ENDLOOP.
      ENDIF.
    ENDLOOP.

    IF lt_displ_bins IS NOT INITIAL.
      CALL FUNCTION '/SCWM/AVLSTOCK_OVERVIEW_MON'
        EXPORTING
          it_data_parent = lt_displ_bins
          iv_lgnum       = ms_input-lgnum
          iv_mode        = '2'
        IMPORTING
          et_data        = rt_displ_bins.
    ENDIF.
  ENDMETHOD.