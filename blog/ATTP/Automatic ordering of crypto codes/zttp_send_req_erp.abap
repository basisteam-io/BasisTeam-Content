&---------------------------------------------------------------------
*& Report ZTTP_SEND_REQ_ERP
&---------------------------------------------------------------------
*& Order crypto codes
* The program is designed for periodic background execution
&---------------------------------------------------------------------
REPORT zttp_send_req_erp MESSAGE-ID zttp_XXXX.
DATA:
  grf_log  TYPE REF TO zcl_log,
  gv_dummy TYPE string.
INCLUDE:
  zttp_XXXX_send_req_erp_cls,
  zttp_XXXX_send_req_erp_c01.  "lcl_proc implementation
--------------------------------------------------------------------
START-OF-SELECTION.
  TRY.
      lcl_proc=>get_erp_rfc( ).
      lcl_proc=>get_statistics( ).
      lcl_proc=>create_request( ).
*      lcl_proc=>get_data_search( ).
    CATCH zcx_appl.
      grf_log->save_log( ).
      lcl_proc=>send_email( ).
      COMMIT WORK.
      RETURN.
  ENDTRY.
  grf_log->save_log( ).
  COMMIT WORK.