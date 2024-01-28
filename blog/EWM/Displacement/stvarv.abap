  METHOD READ_PARAM.

    DATA param_value TYPE tvarvc-low.
    SELECT SINGLE low
    FROM tvarvc
    INTO param_value
    WHERE name = _i_var_name AND
    TYPE = mc_var_type_parameter.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_tvarvc
      EXPORTING
        textid     = zcx_tvarvc=>parameter_not_found
        m_var_name = _i_var_name.
    ENDIF.


    TRY.
      _e_value = param_value.
    CATCH cx_root.
      RAISE EXCEPTION TYPE zcx_tvarvc
      EXPORTING
        textid     = zcx_tvarvc=>conversion_error
        m_var_name = _i_var_name.

    ENDTRY.

  ENDMETHOD.
  
  
  
    METHOD READ_PARAMETER.
    DATA: lv_value TYPE tvarvc-low.

    SELECT SINGLE low INTO lv_value FROM tvarvc
    WHERE name = i_name
    AND TYPE = 'P'.

    IF sy-subrc = 0.
      r_value  = lv_value.
    ENDIF.

  ENDMETHOD.
  
    METHOD READ_SET.
    DATA t_values TYPE ty_t_values.

    SELECT SIGN opti low high
    FROM tvarvc
    INTO TABLE t_values
    WHERE name = _i_var_name
    AND TYPE = mc_var_type_set.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_tvarvc
      EXPORTING
        textid     = zcx_tvarvc=>set_not_found
        m_var_name = _i_var_name.
    ENDIF.


    FIELD-SYMBOLS <wa_value> TYPE ty_s_value.
    LOOP AT t_values ASSIGNING <wa_value>.
      FIELD-SYMBOLS <wa_range> TYPE ANY.
      IF <wa_value>-SIGN IS INITIAL OR
      <wa_value>-option IS INITIAL.
        RAISE EXCEPTION TYPE zcx_tvarvc
        EXPORTING
          textid     = zcx_tvarvc=>set_not_correct
          m_var_name = _i_var_name.
      ENDIF.

      TRY.
        APPEND INITIAL LINE TO _et_range ASSIGNING <wa_range>.
        MOVE-CORRESPONDING <wa_value> TO <wa_range>.
      CATCH cx_root.
        RAISE EXCEPTION TYPE zcx_tvarvc
        EXPORTING
          textid     = zcx_tvarvc=>conversion_error
          m_var_name = _i_var_name.

      ENDTRY.

    ENDLOOP.


  ENDMETHOD.
  
    METHOD RETURN_SET.
    DATA t_values TYPE ty_t_values.

    SELECT SIGN opti low high
    FROM tvarvc
    INTO TABLE t_values
    WHERE name = _i_var_name
    AND TYPE = mc_var_type_set.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_tvarvc
      EXPORTING
        textid     = zcx_tvarvc=>set_not_found
        m_var_name = _i_var_name.
    ENDIF.


    FIELD-SYMBOLS <wa_value> TYPE ty_s_value.
    LOOP AT t_values ASSIGNING <wa_value>.
      FIELD-SYMBOLS <wa_range> TYPE ANY.
      IF <wa_value>-SIGN IS INITIAL OR
      <wa_value>-option IS INITIAL.
        RAISE EXCEPTION TYPE zcx_tvarvc
        EXPORTING
          textid     = zcx_tvarvc=>set_not_correct
          m_var_name = _i_var_name.
      ENDIF.

      TRY.
        APPEND INITIAL LINE TO _rt_range ASSIGNING <wa_range>.
        MOVE-CORRESPONDING <wa_value> TO <wa_range>.
      CATCH cx_root.
        RAISE EXCEPTION TYPE zcx_tvarvc
        EXPORTING
          textid     = zcx_tvarvc=>conversion_error
          m_var_name = _i_var_name.

      ENDTRY.

    ENDLOOP.


  ENDMETHOD.	


*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations


TYPES:
BEGIN OF ty_s_value,
  SIGN   TYPE tvarv_sign,
  option TYPE tvarv_opti,
  low    TYPE tvarv_val,
  high   TYPE tvarv_val,
END OF ty_s_value,

ty_t_values TYPE TABLE OF ty_s_value.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations


TYPES:
BEGIN OF ty_s_value,
  SIGN   TYPE tvarv_sign,
  option TYPE tvarv_opti,
  low    TYPE tvarv_val,
  high   TYPE tvarv_val,
END OF ty_s_value,

ty_t_values TYPE TABLE OF ty_s_value.