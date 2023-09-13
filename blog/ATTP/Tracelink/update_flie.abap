FORM update_flie.
  DATA: lcl_xml       TYPE REF TO cl_xml_document.

  IF gv_xml_string IS INITIAL.
     MESSAGE s087(ztt) INTO DATA(lv_dummy).
     go_messages->set_message( ).
     EXIT.
  ENDIF.

  IF p_ibd IS INITIAL.
     MESSAGE s088(ztt) INTO lv_dummy.
     go_messages->set_message( ).
     EXIT.
  ENDIF.

  CREATE OBJECT lcl_xml.

*XML File to DOM
  CALL METHOD lcl_xml->parse_string
    EXPORTING
      stream = gv_xml_string.

  CALL METHOD lcl_xml->find_node_table
*    EXPORTING
*      tabname =
*      root    =
    IMPORTING
      t_nodes = DATA(lt_nodes)
*     retcode =
    .

  DATA(lo_node_one) = lcl_xml->find_node( name = 'EventList' ).
  DATA(lo_child_first_level) = lo_node_one->get_children( ).
  DATA(lo_itr) = lo_child_first_level->create_iterator( ).
  DATA(lo_child) = lo_itr->get_next( ).
  DATA: l_leave.
  DATA: lv_counter TYPE i.

  WHILE lo_child IS NOT INITIAL.

    lv_counter = 0.

    DATA(lv_name)  = lo_child->get_name( ).
    DATA(lv_value) = lo_child->get_value( ).
    IF lv_name = 'ObjectEvent'.
      DATA(lo_evt_itr) = lo_child->create_iterator( ).
      DATA(lo_evt_child) = lo_evt_itr->get_next( ).
      WHILE     lo_evt_child IS NOT INITIAL.
        lv_name  = lo_evt_child->get_name( ).
        IF lv_name = 'bizStep'.
          lv_value = lo_evt_child->get_value( ).
          IF lv_value = 'urn:epcglobal:cbv:bizstep:shipping'.
            DATA(lv_ok) = 'X'.
          ELSE.
            EXIT.
          ENDIF.
        ENDIF.
        IF lv_name = 'bizTransactionList' AND lv_ok IS NOT INITIAL.
          DATA(lo_doc_ref) = lo_evt_itr->get_next( ).
          WHILE lo_doc_ref IS NOT INITIAL.
            lv_name = lo_doc_ref->get_name( ).
            IF lv_name = 'bizTransaction'.
              DATA(lo_ibd) = lo_doc_ref->clone(  ).

              lv_value = lo_ibd->get_value( ).
              lv_value = p_ibd.
              lo_ibd->set_value( lv_value ).
              DATA(lo_attr) = lo_ibd->get_attributes( ).
              DATA(lo_type) = lo_attr->get_named_item_ns( name = 'type' ).
              lo_type->set_value('urn:epcglobal:cbv:btt:recadv' ).
              lo_attr->set_named_item_ns( lo_type ).
              DATA(l_new_res) = lo_evt_child->append_child( lo_ibd ).
              DATA(l_leave_loop) = 'X'.
              MESSAGE s089(ztt) WITH p_ibd INTO lv_dummy.
              go_messages->set_message( ).

              EXIT.
            ENDIF.
            lo_doc_ref = lo_evt_itr->get_next( ).
          ENDWHILE.
        ENDIF.
        IF l_leave_loop IS NOT INITIAL.
          EXIT.
        ENDIF.
        lo_evt_child = lo_evt_itr->get_next( ).
      ENDWHILE.
    ENDIF.
    IF l_leave_loop IS NOT INITIAL.
      EXIT.
    ENDIF.
    lo_child = lo_itr->get_next( ).
  ENDWHILE.
  DATA: l_debug.
  IF l_debug = 'X'.
    lcl_xml->display( ).
  ENDIF.
  CALL METHOD lcl_xml->render_2_string
*    EXPORTING
*      pretty_print = 'X'
     IMPORTING
*      retcode      =
       stream       = gv_xml_string
*      size         =
      .


ENDFORM.