*&---------------------------------------------------------------------*
*& Report zttp_get_requarement_erp
*&---------------------------------------------------------------------*
*& Get ordered crypto codes
*& The program is designed for periodic background execution
*&---------------------------------------------------------------------*
REPORT zttp_get_requarement_erp MESSAGE-ID zttp_XXX.

DATA:
  grf_log     TYPE REF TO zcl_log,
  gv_dummy    TYPE string,
  gv_failed   TYPE flag,
  gv_date_del TYPE datum,
  ltr_status  TYPE RANGE OF /sttp/e_snr_cry_retrieval_stat.

gv_date_del = sy-datum + 30.

grf_log = zcl_log=>gi(
  iv_object     = 'ZTTP_XXX'
  iv_subobject  = 'CRY_CODE'
  iv_date_del   = gv_date_del ).

ltr_status = VALUE #(
  ( sign = 'I' option = 'EQ' low = '1' )
  ( sign = 'I' option = 'EQ' low = '2' )
).

" Take only unique GTINs to avoid duplicate work!
SELECT DISTINCT gtin
  FROM /sttp/snr_cry_pr
  WHERE status IN @ltr_status
  INTO TABLE @DATA(gt_cry_pr).

IF sy-subrc IS NOT INITIAL.
* no records with ordered status, exit.
  RETURN.
ENDIF.

DATA:
  lt_snr_cry_r      TYPE /sttp/t_snr_cry_r,
  lt_snr_cry_pr     TYPE /sttp/t_snr_cry_pr,
  lrf_messages      TYPE REF TO /sttp/cl_messages,
  lt_messages       TYPE /cdbasis/t_bal_msg,
  lt_messages_save  TYPE /cdbasis/t_bal_msg,
  lt_messages_total TYPE /cdbasis/t_bal_msg.

LOOP AT gt_cry_pr ASSIGNING FIELD-SYMBOL(<ls_tab>).
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

  LOOP AT lt_snr_cry_r ASSIGNING FIELD-SYMBOL(<ls_snr_cry_r>).
    /sttp/cl_snr_cry_proc=>create_retrieval(
      EXPORTING
        iv_cry_req_id          = <ls_snr_cry_r>-cry_req_id
        iv_gtin                = <ls_tab>-gtin
      IMPORTING
        eb_failed              = gv_failed
      CHANGING
        co_messages            = lrf_messages ).

    lrf_messages->get_messages(
      IMPORTING
        et_messages       = lt_messages
        et_messages_save  = lt_messages_save
        et_messages_total = lt_messages_total ).

    grf_log->add_bal_t_msg( lt_messages ).
    grf_log->add_bal_t_msg( lt_messages_save ).
    grf_log->add_bal_t_msg( lt_messages_total ).

    " =========================================================================
    " BEGIN: SMART INTERCEPTION OF COMMUNICATION ERRORS (HTTP 400 etc.)
    " =========================================================================
    
    " Read lt_messages (ONLY new errors of this step!), not the entire basket lt_messages_total
    LOOP AT lt_messages INTO DATA(ls_err_msg) WHERE msgty = 'E' OR msgty = 'A'.
      DATA: lv_err_text TYPE string.

      " Format error text
      MESSAGE ID ls_err_msg-msgid TYPE ls_err_msg-msgty NUMBER ls_err_msg-msgno
              WITH ls_err_msg-msgv1 ls_err_msg-msgv2 ls_err_msg-msgv3 ls_err_msg-msgv4
              INTO lv_err_text.

      " Filter AIF/ABAP technical garbage
      CHECK lv_err_text NP '*ZFM_AIF_OMS*'.
      CHECK lv_err_text NP '*/AIF/SAPLFILE*'.

      " Spam check: have we already sent an email for this specific order?
      DATA: lv_already_sent TYPE /sttp/e_snr_cry_req_id.
      SELECT SINGLE cry_req_id FROM ztb_XXX_alerts INTO @lv_already_sent
        WHERE cry_req_id = @<ls_snr_cry_r>-cry_req_id.

      " If there is no record in the table - it means we are here for the first time
      IF sy-subrc <> 0.

        DATA: lt_email TYPE STANDARD TABLE OF ztb_XXX_email.
        SELECT * FROM ztb_XXX_email INTO TABLE @lt_email.

        IF lt_email IS NOT INITIAL.
          DATA(lt_recps) = CORRESPONDING ztt_zemail_smtp_sd_sls_addr( lt_email MAPPING email_addr = email ).
          
          DATA: lt_mailtext     TYPE soli_tab,
                lv_mail_subject TYPE so_obj_des. 

          " Format email subject
          lv_mail_subject = |OMS. Error for GTIN { <ls_tab>-gtin }|.

          lt_mailtext = VALUE #(
            ( line = |Hello!| && cl_abap_char_utilities=>cr_lf )
            ( line = cl_abap_char_utilities=>cr_lf )
            ( line = |OMS error.| && cl_abap_char_utilities=>cr_lf )
            ( line = |Comm error.| && cl_abap_char_utilities=>cr_lf )
            ( line = |REQ_ID): { <ls_snr_cry_r>-cry_req_id }| && cl_abap_char_utilities=>cr_lf )
            ( line = |GTIN: { <ls_tab>-gtin }| && cl_abap_char_utilities=>cr_lf )
            ( line = |Detail: { lv_err_text }| && cl_abap_char_utilities=>cr_lf )
            ( line = cl_abap_char_utilities=>cr_lf )
            ( line = |Automatic e-mail.| ) ).

          TRY.
              zcl_email=>gi( )->send(
                it_email_recipient  = lt_recps
                iv_mail_subject     = lv_mail_subject
                it_mailtext         = lt_mailtext
                iv_send_immediately = abap_true ).

              " Write to our "memory" that the email for this order has been sent
              DATA: ls_alert_log TYPE ztb_XXX_alerts.
              ls_alert_log-cry_req_id = <ls_snr_cry_r>-cry_req_id.
              ls_alert_log-erdat      = sy-datum.
              ls_alert_log-erzet      = sy-uzeit.
              INSERT ztb_XXX_alerts FROM ls_alert_log.
              
            CATCH cx_root.
          ENDTRY.
        ENDIF.

      ENDIF. " End of spam check

      " Exit the error loop
      EXIT.
    ENDLOOP. 
    " =========================================================================
    " END: SMART INTERCEPTION
    " =========================================================================

  ENDLOOP.
ENDLOOP.

grf_log->save_log( ).
COMMIT WORK.