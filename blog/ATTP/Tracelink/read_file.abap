FORM read_file.
  gv_filename = 'c:\test.xml'.

  CALL FUNCTION 'GUI_FILE_LOAD_DIALOG'
*   EXPORTING
*     WINDOW_TITLE            =
*     DEFAULT_EXTENSION       =
*     DEFAULT_FILE_NAME       =
*     WITH_ENCODING           =
*     FILE_FILTER             =
*     INITIAL_DIRECTORY       =
    IMPORTING
*     FILENAME = gv_filename
*     PATH     =
      fullpath = gv_filename
*     USER_ACTION             =
*     FILE_ENCODING           =
    .


*Upload XML file
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename            = gv_filename
      filetype            = 'BIN'
      has_field_separator = ' '
      header_length       = 0
    IMPORTING
      filelength          = gv_size
    TABLES
      data_tab            = gt_xml
    EXCEPTIONS
      OTHERS              = 1.

*Convert uploaded data to string
  CALL FUNCTION 'SCMS_BINARY_TO_STRING'
    EXPORTING
      input_length = gv_size
    IMPORTING
      text_buffer  = gv_xml_string
    TABLES
      binary_tab   = gt_xml
    EXCEPTIONS
      failed       = 1
      OTHERS       = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.