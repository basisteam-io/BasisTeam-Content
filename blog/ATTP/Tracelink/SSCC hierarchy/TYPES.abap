TYPES:
  ttr_gtin  TYPE RANGE OF /sttp/e_gs1_gtin,
  ttr_sgtin TYPE RANGE OF zde_ttp_d001_sgtin,
  ttr_serno TYPE RANGE OF /sttp/e_serno,
  ttr_lotno TYPE RANGE OF /sttp/e_lotno,
  BEGIN OF ts_hrh,
    objid        TYPE /sttp/e_objid,
    gs1_es_b     TYPE /sttp/e_gs1_element_string_ui,
    status_pack  TYPE /sttp/e_stat_pack,
    status_stock TYPE /sttp/e_stat_stock,
    disposition  TYPE /sttp/e_cdisposno,
    objid_parent TYPE /sttp/e_objid,
  END OF ts_hrh,

  ts_hry_sgtin TYPE /sttp/s_hry_object,

  tt_hry_sgtin TYPE STANDARD TABLE OF ts_hry_sgtin
                 WITH NON-UNIQUE SORTED KEY objid    COMPONENTS objid
                 WITH NON-UNIQUE SORTED KEY objtype  COMPONENTS objtype,

  tt_hrh       TYPE STANDARD  TABLE OF ts_hrh
    WITH NON-UNIQUE SORTED KEY objid
    COMPONENTS objid
    WITH NON-UNIQUE SORTED KEY objid_parent
    COMPONENTS objid_parent,

  BEGIN OF ts_aggtin,
    objid_parent TYPE /sttp/e_objid,
    gtin         TYPE /sttp/e_gs1_gtin,
    lotno        TYPE /sttp/e_lotno,
    status_pack  TYPE /sttp/e_stat_pack,
    status_stock TYPE /sttp/e_stat_stock,
    disposition  TYPE /sttp/e_cdisposno,
    quantity     TYPE /sttp/e_qty,
  END OF ts_aggtin,

  tt_aggtin TYPE HASHED TABLE OF ts_aggtin WITH UNIQUE KEY objid_parent gtin lotno status_pack status_stock disposition,

  BEGIN OF ts_aggtin_sgtin,
    objid_parent TYPE /sttp/e_objid,
    gtin         TYPE /sttp/e_gs1_gtin,
    lotno        TYPE /sttp/e_lotno,
    sgtin        TYPE zde_ttp_d001_sgtin,
    status_pack  TYPE /sttp/e_stat_pack,
    status_stock TYPE /sttp/e_stat_stock,
    disposition  TYPE /sttp/e_cdisposno,
    datex        TYPE sydatum,
    quantity     TYPE /sttp/e_qty,
  END OF ts_aggtin_sgtin,

  tt_aggtin_sgtin TYPE HASHED TABLE OF ts_aggtin_sgtin WITH UNIQUE KEY objid_parent gtin lotno sgtin status_pack status_stock disposition datex.


DATA:
  gtr_status_pack TYPE RANGE OF /sttp/e_stat_pack.