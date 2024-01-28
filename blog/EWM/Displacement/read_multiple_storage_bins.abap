*&---------------------------------------------------------------------*
*&      Form  READ_MULTIPLE_STORAGE_BINS
*&---------------------------------------------------------------------*
* It is necessary to check that storage bins are not blocked and that there are no storage bins available for them.
* open warehouse tasks. All lines with storage bins that did not pass the check are
* must be removed from the list of available stocks
*----------------------------------------------------------------------*
FORM read_multiple_storage_bins CHANGING ct_lgpla TYPE /scwm/tt_aqua_lagp_mon
                                         ct_lagp  TYPE /scwm/tt_lagp.

  DATA: lt_lgpla       TYPE /scwm/tt_lagp_key,
        ls_lgpla       LIKE LINE OF lt_lgpla,
        lt_ordim_o_des TYPE /scwm/tt_ordim_o,
        lt_ordim_o_src TYPE /scwm/tt_ordim_o,
        lt_lgpla_t     TYPE /scwm/tt_lgpla.

  FIELD-SYMBOLS: <fs_lgpla> LIKE LINE OF ct_lgpla,
                 <fs_lagp>  LIKE LINE OF ct_lagp,
                 <fs_o>     TYPE /scwm/ordim_o.

  ls_lgpla-lgnum = p_lgnum.
  LOOP AT ct_lgpla ASSIGNING <fs_lgpla>.
    ls_lgpla-lgpla = <fs_lgpla>-lgpla. 
    COLLECT ls_lgpla INTO lt_lgpla.
  ENDLOOP.

  CALL FUNCTION '/SCWM/LAGP_READ_MULTI'
    EXPORTING
      it_lgpla      = lt_lgpla
    IMPORTING
      et_lagp       = ct_lagp
    EXCEPTIONS
      wrong_input   = 1
      not_found     = 2
      enqueue_error = 3
      OTHERS        = 4.


* delete where:
* 1) storage bin is blocked for release
* 2) the storage location is blocked by inventory
  DELETE ct_lagp WHERE skzua = 'X' OR skzsi = 'X'.

  LOOP AT ct_lagp ASSIGNING <fs_lagp>.
    CLEAR: lt_ordim_o_des[], lt_ordim_o_src[].


    CALL FUNCTION '/SCWM/TO_READ_DES'
      EXPORTING
        iv_lgnum     = p_lgnum
        iv_lgpla     = <fs_lagp>-lgpla
      IMPORTING
        et_ordim_o   = lt_ordim_o_des
      EXCEPTIONS
        wrong_input  = 1
        not_found    = 2
        foreign_lock = 3
        OTHERS       = 4.
    IF lt_ordim_o_src[] IS NOT INITIAL.
      CLEAR: <fs_lagp>-lgnum, <fs_lagp>-lgpla.
    ELSE.

      CALL FUNCTION '/SCWM/TO_READ_SRC'
        EXPORTING
          iv_lgnum     = p_lgnum
          iv_lgpla     = <fs_lagp>-lgpla
        IMPORTING
          et_ordim_o   = lt_ordim_o_src
        EXCEPTIONS
          wrong_input  = 1
          not_found    = 2
          foreign_lock = 3
          OTHERS       = 4.
      IF lt_ordim_o_src[] IS NOT INITIAL.
        CLEAR: <fs_lagp>-lgnum, <fs_lagp>-lgpla.
      ENDIF.
    ENDIF.
  ENDLOOP.

  DELETE ct_lagp  WHERE lgnum IS INITIAL AND lgpla IS INITIAL.
  LOOP AT ct_lgpla ASSIGNING <fs_lgpla>.
    READ TABLE ct_lagp ASSIGNING <fs_lagp> WITH KEY lgnum = p_lgnum lgpla = <fs_lgpla>-lgpla.
    IF sy-subrc NE 0.
      CLEAR: <fs_lgpla>-lgpla.
    ENDIF.
  ENDLOOP.

  DELETE ct_lgpla WHERE lgpla IS INITIAL.

ENDFORM.