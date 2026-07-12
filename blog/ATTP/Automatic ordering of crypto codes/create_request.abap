*&---------------------------------------------------------------------*
*&  Include           ZTTP_XXX_SEND_REQ_ERP_C01
*&---------------------------------------------------------------------*
CLASS lcl_proc IMPLEMENTATION.
  METHOD class_constructor.

    DATA:
      lv_date_del TYPE datum.

    lv_date_del = sy-datum + 30.

    grf_log = zcl_log=>gi(
      iv_object     = mc_object
      iv_subobject  = mc_subobject
      iv_date_del   = lv_date_del ).

    SELECT *
      FROM ztb_XXX_email
      INTO TABLE mt_email.

    IF mt_email[] IS INITIAL.
      MESSAGE e002 INTO gv_dummy.
      grf_log->add_msg( ).
    ENDIF.

  ENDMETHOD.  "class_constructor
  METHOD get_erp_rfc.

    DATA:
      lv_msg     TYPE text255,
      lv_rfcdest TYPE bdbapidst.

    lv_rfcdest = zcl_get_rfc=>get_rfc_by_subname( 'XXX' ).
* Get the list of GTINs and the required quantity of crypto codes for ERP
    CALL FUNCTION 'XXXX'
      DESTINATION lv_rfcdest
      IMPORTING
        et_tab                = mt_tab
      EXCEPTIONS
        system_failure        = 1 MESSAGE lv_msg
        communication_failure = 2 MESSAGE lv_msg
        OTHERS                = 3.
    CASE sy-subrc.
      WHEN 1 OR 2.
        MESSAGE e001 WITH lv_msg INTO gv_dummy.
        grf_log->add_msg( ).
        RAISE EXCEPTION TYPE zcx_appl.
      WHEN 3.
        MESSAGE e001 WITH 'xxx' INTO gv_dummy.
        grf_log->add_msg( ).
        RAISE EXCEPTION TYPE zcx_appl.
    ENDCASE.

  ENDMETHOD.  "get_erp_rfc
  METHOD get_statistics.

    DATA:
      lt_gtin           TYPE /sttp/t_gtin,
      ltr_status        TYPE /sttp/t_rng_snr_cry_status,
      lrf_messages      TYPE REF TO /sttp/cl_messages,
      lt_messages       TYPE /cdbasis/t_bal_msg,
      lt_messages_save  TYPE /cdbasis/t_bal_msg,
      lt_messages_total TYPE /cdbasis/t_bal_msg.

    lt_gtin[] = CORRESPONDING #( mt_tab[] ).
    ltr_status[] = VALUE #(
    ( sign = 'I' option = 'EQ' low = '2' ) ).

    /sttp/cl_snr_cry=>get_statistics_per_gtin(
      EXPORTING
        it_gtin                   = lt_gtin
        ir_status                 = ltr_status
      IMPORTING
        et_crypto_code_statistics = mt_crypto_code_statistics
      CHANGING
        co_messages               = lrf_messages ).

    lrf_messages->get_messages(
      IMPORTING
        et_messages       = lt_messages
        et_messages_save  = lt_messages_save
        et_messages_total = lt_messages_total ).

    grf_log->add_bal_t_msg( lt_messages ).
    grf_log->add_bal_t_msg( lt_messages_save ).
    grf_log->add_bal_t_msg( lt_messages_total ).

  ENDMETHOD.  "get_statistics
  METHOD create_request.

    DATA:
      lt_gtin_amnt      TYPE /sttp/t_crypto_req_gtin_amnt,
      lv_failed         TYPE flag,
      lrf_messages      TYPE REF TO /sttp/cl_messages,
      lt_messages       TYPE /cdbasis/t_bal_msg,
      lt_messages_save  TYPE /cdbasis/t_bal_msg,
      lt_messages_total TYPE /cdbasis/t_bal_msg.

    lt_gtin_amnt[] = CORRESPONDING #( mt_tab[] MAPPING quantity = gamng_q ).

    LOOP AT lt_gtin_amnt ASSIGNING FIELD-SYMBOL(<ls_gtin_amnt>).
      DATA(lv_tabix) = sy-tabix.
      LOOP AT mt_crypto_code_statistics ASSIGNING FIELD-SYMBOL(<ls_stat>)
        WHERE gtin = <ls_gtin_amnt>-gtin.
        LOOP AT <ls_stat>-quantities ASSIGNING FIELD-SYMBOL(<ls_quan>)
          WHERE status = '2'.
          SUBTRACT <ls_quan>-quantity FROM <ls_gtin_amnt>-quantity.
          IF <ls_gtin_amnt>-quantity <= 0.
            DELETE lt_gtin_amnt INDEX lv_tabix.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
    IF lt_gtin_amnt[] IS INITIAL.
      MESSAGE e003 INTO gv_dummy.
      grf_log->add_msg( ).
      RAISE EXCEPTION TYPE zcx_appl.
    ENDIF.
    /sttp/cl_snr_cry_proc=>create_request(
      EXPORTING
        it_gtin_amnt     = lt_gtin_amnt
      IMPORTING
        eb_failed        = lv_failed
      CHANGING
        co_messages      = lrf_messages ).

    IF lv_failed IS NOT INITIAL.
      lrf_messages->get_messages(
        IMPORTING
          et_messages       = lt_messages
          et_messages_save  = lt_messages_save
          et_messages_total = lt_messages_total ).

      grf_log->add_bal_t_msg( lt_messages ).
      grf_log->add_bal_t_msg( lt_messages_save ).
      grf_log->add_bal_t_msg( lt_messages_total ).
      RAISE EXCEPTION TYPE zcx_appl.
    ENDIF.

  ENDMETHOD.  "create_request
  METHOD get_data_search.

    DATA:
      lt_snr_cry_r      TYPE /sttp/t_snr_cry_r,
      lt_snr_cry_pr     TYPE /sttp/t_snr_cry_pr,
      lrf_messages      TYPE REF TO /sttp/cl_messages,
      lt_messages       TYPE /cdbasis/t_bal_msg,
      lt_messages_save  TYPE /cdbasis/t_bal_msg,
      lt_messages_total TYPE /cdbasis/t_bal_msg.

    LOOP AT mt_tab ASSIGNING FIELD-SYMBOL(<ls_tab>).
      REFRESH:
        lt_snr_cry_r,
        lt_snr_cry_pr.
      CLEAR lrf_messages.

      /sttp/cl_snr_cry_req=>get_data_search(
        EXPORTING
           iv_gtin                 = <ls_tab>-gtin
        IMPORTING
          et_snr_cry_r            = lt_snr_cry_r
          et_snr_cry_pr           = lt_snr_cry_pr
        CHANGING
          co_messages             = lrf_messages ).

      lrf_messages->get_messages(
        IMPORTING
          et_messages       = lt_messages
          et_messages_save  = lt_messages_save
          et_messages_total = lt_messages_total ).

      grf_log->add_bal_t_msg( lt_messages ).
      grf_log->add_bal_t_msg( lt_messages_save ).
      grf_log->add_bal_t_msg( lt_messages_total ).

    ENDLOOP.

  ENDMETHOD.  "get_data_search
  METHOD send_email.

    DATA:
      lt_mailtext        TYPE soli_tab,
      lt_email_recipient TYPE ztt_zemail_smtp_sd_sls_addr,
      lv_mail_subject	   TYPE so_obj_des.

    lt_email_recipient[] = CORRESPONDING #(  mt_email[] MAPPING email_addr = email ).
    lv_mail_subject = 'Crypto code order error'.

    lt_mailtext = VALUE #(
      ( line = |Good day!| && cl_abap_char_utilities=>cr_lf )
      ( line = cl_abap_char_utilities=>cr_lf )
      ( line = |An error occurred while ordering crypto codes.{ cl_abap_char_utilities=>cr_lf } | )
      ( line = |Please check the SLG1 log and take appropriate action.{ cl_abap_char_utilities=>cr_lf } | )
      ( line = cl_abap_char_utilities=>cr_lf )
      ( line = |This email is generated automatically. Please do not reply.| )
      ( line = cl_abap_char_utilities=>cr_lf ) ) .


    TRY.
        zcl_email=>gi( )->send(
          it_email_recipient    = lt_email_recipient
          iv_mail_subject       = lv_mail_subject
          it_mailtext           = lt_mailtext
          iv_send_immediately   = abap_true ).
      CATCH zcx_email .
        MESSAGE
          ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      CATCH cx_address_bcs.
        MESSAGE
          ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDTRY.

    COMMIT WORK.

  ENDMETHOD.  "send_email
ENDCLASS.