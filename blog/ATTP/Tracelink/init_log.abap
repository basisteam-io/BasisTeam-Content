FORM init_log.
  go_messages = /sttp/cl_message_ctrl=>create(
    EXPORTING
      iv_object    = 'ZXXX'
      iv_subobject = 'MANUAL_EVENT'
      iv_extnumber = 'ZSCN_UPLOAD'
      iv_title     = 'ZSCN_UPLOAD'
      iv_loglevel  = '1' ).
ENDFORM.