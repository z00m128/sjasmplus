MARK_PAGE   MACRO page?
                MMU $C000, page?, $C000
                DB "page: ", '0' + page? / 10, '0' + page? % 10
            ENDM

    DEVICE AMSTRADCPCPLUS
    DUP 32, page_i
        MARK_PAGE page_i
    EDUP
    SAVECPR "savecpr.cpr"       ; default size = 32
    SAVECPR "savecpr.bin", 2    ; try also explicit size 2
