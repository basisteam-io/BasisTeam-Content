DATA:
  BEGIN OF gs_scr,
    lgnum TYPE /scwm/lagp-lgnum,
  END OF gs_scr,

lv_wave  type /scwm/de_wave,
lv_docno type /scwm/sp_docno_pdo.

PARAMETERS: p_lgnum LIKE gs_scr-lgnum OBLIGATORY DEFAULT 'XXX'. "WH Numver


SELECTION-SCREEN BEGIN OF BLOCK b1.
SELECT-OPTIONS: s_wave  FOR lv_wave, "WAVE
                s_docno FOR lv_docno. "Outbound deliveries

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN: COMMENT (33) text-t01 FOR FIELD p_datfr.
PARAMETERS: p_datfr TYPE /scwm/sp_deldate,
            p_timfr TYPE t.
SELECTION-SCREEN: COMMENT (4) text-t02 FOR FIELD p_datto.
PARAMETERS: p_datto TYPE datum,
            p_timto TYPE t.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.