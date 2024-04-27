REPORT zewm_cleanup MESSAGE-ID zewm_cleanup.

INCLUDE: zewm_cleanup_t01,
         zewm_cleanup_s01,
         zewm_cleanup_o01,
         zewm_cleanup_i01,
         zewm_cleanup_f01,
         zewm_cleanup_cld,
         zewm_cleanup_cli.

INITIALIZATION.

AT SELECTION-SCREEN ON BLOCK b1.

START-OF-SELECTION.
  DATA(go_report) = NEW lcl_report( is_input = VALUE #( lgnum  = p_lgnum
                                                        wave   = s_wave[]
                                                        docno  = s_docno[]
                                                        date   = s_date[] ) ).
  TRY.
      go_report->create_log( ).
      go_report->selection( ).
      NEW lcl_view( go_report )->dysplay( ).
      go_report->save_log_in_db( ).
    CATCH zcx_ewm INTO DATA(gcx_err).
      MESSAGE gcx_err TYPE 'E'.
  ENDTRY.