  METHOD sort_method.
    DATA:
      lv_openhu     TYPE xflag,
      lv_returnedhu TYPE xflag.

    LOOP AT ct_qmat_ad ASSIGNING FIELD-SYMBOL(<fs_qmat_ad>). " 
* Opened
      CALL FUNCTION 'ZFM_EWM107_OPENHU'
        EXPORTING
          iv_huident        = <fs_qmat_ad>-huident
        IMPORTING
          ev_openhu         = lv_openhu
        EXCEPTIONS
          huident_not_found = 4.

      IF lv_openhu IS NOT INITIAL. "Opened
        <fs_qmat_ad>-prob = 'X'.
        CLEAR lv_openhu.
      ENDIF.

* Returned
      CALL FUNCTION 'ZFM_EWM107_RETURNEDHU'
        EXPORTING
          iv_huident    = <fs_qmat_ad>-huident
        IMPORTING
          ev_returnedhu = lv_returnedhu.

      IF lv_returnedhu IS NOT INITIAL. "Returned
        <fs_qmat_ad>-returned_hu = 'X'.
        CLEAR lv_returnedhu.
      ENDIF.

    ENDLOOP."


*vfdat -Shelf Life Expiration Date 
*wdatu_date - Date and Time of Goods Receipt

    SORT ct_qmat_ad BY
      vfdat ASCENDING
      wdatu_date ASCENDING
      returned_hu DESCENDING
      prob DESCENDING
  ENDMETHOD.