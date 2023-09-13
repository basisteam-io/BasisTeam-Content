FORM process_file.
  DATA: lt_return   TYPE bapiret2_t,
        lt_messages TYPE /sttp/cl_messages=>tt_bal_msg.

  DATA(lo_conv) = NEW /sttp/cl_inbound_converter( iv_type = /sttp/cl_inbound_converter=>gc_type_epcis iv_xml = gv_xml_string ).

  lo_conv->process_message( CHANGING ct_return = lt_return ).

  go_messages->convert_bapi_2_log( EXPORTING it_bapiret  = lt_return
                                    IMPORTING et_messages = lt_messages ).
  go_messages->set_messages( it_messages = lt_messages ).


ENDFORM.