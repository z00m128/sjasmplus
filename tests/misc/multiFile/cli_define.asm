    ld      (hl),DEFINE_FROM_CLI
    ld      (DOUBLE_DASH_DEFINE),hl
    IFDEF DOUBLE_DASH_DEF2
        db      '1'
    ENDIF
    IFDEF DOUBLE_DASH_DEF3
        db      '2'
    ENDIF
