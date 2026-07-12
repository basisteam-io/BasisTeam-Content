METHOD get_orders.

    DATA:
      lv_date_from    TYPE datum,
      lv_date_to      TYPE datum,
      ltr_gstrp       TYPE RANGE OF pm_ordgstrp,
      ltr_country_ref TYPE RANGE OF	/sttpec/e_pr_rel_country.

    IF mv_days IS INITIAL.
      MESSAGE e001.
      RAISE EXCEPTION TYPE zcx_appl.
    ENDIF.

    lv_date_from = sy-datum.

    CALL FUNCTION 'WDKAL_DATE_ADD_FKDAYS'
      EXPORTING
        i_date  = lv_date_from
        i_fkday = CONV fkday( mv_days )
        i_fabkl = 'R2'
      IMPORTING
        e_date  = cv_date_to
      EXCEPTIONS
        error   = 1
        OTHERS  = 2.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_appl USING MESSAGE.
    ENDIF.

    ltr_gstrp = VALUE #(
    ( sign = 'I' option = 'BT' low = lv_date_from high = cv_date_to ) ).

    ltr_country_ref = VALUE #( FOR country IN mt_inc_quan ( sign    = rs_c_range_sign-including
                                                            option  = rs_c_range_opt-equal
                                                            low     = country-country_ref ) ).

    SELECT FROM afko AS ko
      INNER JOIN aufk AS ku
        ON ku~aufnr = ko~aufnr
      INNER JOIN afpo AS po
        ON po~aufnr = ko~aufnr
       AND po~posnr = '0001'
      INNER JOIN mara AS ma
        ON ma~matnr = po~matnr
      INNER JOIN marm AS mr
        ON mr~matnr = po~matnr
       AND mr~meinh = ma~meins
      FIELDS
        ko~aufnr,
        ko~gstrp,
        ko~gamng,
        ku~objnr,
        po~matnr,
        ko~gmein AS meins,
        mr~/sttpec/gtin AS gtin,
        ma~/sttpec/country_ref AS country_ref
      WHERE ko~gstrp               IN @ltr_gstrp
        AND ko~sfcpf                = '1001'
        AND ma~/sttpec/country_ref IN @ltr_country_ref[]
        AND ma~/sttpec/sertype      = '3' 
      INTO TABLE @ct_orders.
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION TYPE zcx_appl.
    ENDIF.

  ENDMETHOD.  "get_orders
  METHOD check_statuses.

    DATA:
      lt_status TYPE tt_jstat.

    LOOP AT ct_orders ASSIGNING FIELD-SYMBOL(<ls_orders>).
      REFRESH lt_status.
      DATA(lv_tabix) = sy-tabix.

      CALL FUNCTION 'STATUS_READ'
        EXPORTING
          objnr            = <ls_orders>-objnr
          only_active      = 'X'
        TABLES
          status           = lt_status
        EXCEPTIONS
          object_not_found = 1
          OTHERS           = 2.
      IF sy-subrc <> 0.
        DELETE ct_orders INDEX lv_tabix.
      ENDIF.
      SORT lt_status BY stat.
      IF check_order_status( lt_status ) IS INITIAL.
        DELETE ct_orders INDEX lv_tabix.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.  "check_statuses
  METHOD check_order_status.

    DATA:
      lt_pair_stat TYPE tt_pair_stat.
* получим шаблон парных статусов
    lt_pair_stat[] = mt_pair_stat[].

    LOOP AT it_status ASSIGNING FIELD-SYMBOL(<ls_status>)
      WHERE inact IS INITIAL.
      IF <ls_status>-stat = mv_mtku.
        RETURN.
      ENDIF.
      IF <ls_status>-stat IN mtr_estat.   
        LOOP AT lt_pair_stat ASSIGNING FIELD-SYMBOL(<ls_pair_stat>)
          WHERE estat = <ls_status>-stat.
          <ls_pair_stat>-e_falg = 'X'. 
        ENDLOOP.
      ENDIF.
      IF <ls_status>-stat IN mtr_istat.  
        LOOP AT lt_pair_stat ASSIGNING <ls_pair_stat>
          WHERE istat = <ls_status>-stat.
          <ls_pair_stat>-i_falg = 'X'. 
        ENDLOOP.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_pair_stat TRANSPORTING NO FIELDS
      WHERE e_falg = 'X'
        AND i_falg = 'X'.
      EXIT.
    ENDLOOP.
    IF sy-subrc IS INITIAL.
      rv_ok = 'X'.
    ENDIF.

  ENDMETHOD.  "check_order_status
  METHOD collect_orders_by_gtin.

    DATA:
      ls_gtin_collect TYPE ts_gtin_collect,
      lt_gtin_collect TYPE tt_gtin_collect.

    LOOP AT it_orders ASSIGNING FIELD-SYMBOL(<ls_order>).
      MOVE-CORRESPONDING <ls_order> TO ls_gtin_collect.
      COLLECT ls_gtin_collect INTO lt_gtin_collect.
    ENDLOOP.

    rt_tab[] = CORRESPONDING #( lt_gtin_collect[] ).

    LOOP AT rt_tab ASSIGNING FIELD-SYMBOL(<ls_tab>).
      <ls_tab>-date_from  = iv_date_from.
      <ls_tab>-date_to    = iv_date_to.

      READ TABLE mt_inc_quan ASSIGNING FIELD-SYMBOL(<ls_inc_quan>)
        WITH KEY country_ref = <ls_tab>-country_ref.
      IF sy-subrc IS INITIAL.
        <ls_tab>-gamng_q = <ls_tab>-gamng + ( <ls_tab>-gamng * <ls_inc_quan>-inc_quan ) / 100.
        <ls_tab>-inc_quan = <ls_inc_quan>-inc_quan.
      ELSE.
        <ls_tab>-gamng_q = <ls_tab>-gamng.
      ENDIF.

    ENDLOOP.


  ENDMETHOD.  "collect_orders_by_gtin

ENDCLASS. "lcl_data