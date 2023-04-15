FUNCTION zfm_ewm107_returnedhu_single.
*"----------------------------------------------------------------------:
*"  IMPORTING
*"     REFERENCE(IV_HUIDENT_SINGLE) TYPE  /SCWM/HUIDENT
*"  EXPORTING
*"     REFERENCE(EV_RETURNEDHU_SINGLE) TYPE  XFLAG
*"----------------------------------------------------------------------

*Returned HU

  DATA:

    lv_huident   TYPE /scwm/huident,
    lv_guid_hu   TYPE /scwm/guid_hu.


  lv_huident = iv_huident_single.
*SHIFT lv_huident LEFT DELETING LEADING '0'.
  ev_returnedhu_single = abap_false.

* IDART R (Returned)
  SELECT SINGLE
      huident~guid_hu
      FROM /scwm/hu_ident AS huident
      INTO @lv_guid_hu
      WHERE
    huident~huident = @lv_huident AND
    huident~idart = 'R'.


  IF lv_guid_hu IS NOT INITIAL.
    ev_returnedhu_single = abap_true.
    CLEAR lv_guid_hu.
  ENDIF.



ENDFUNCTION.