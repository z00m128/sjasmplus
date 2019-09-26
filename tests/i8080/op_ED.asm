    ; all of these should fail on i8080
    ; (some will emit damaged machine code of legit i8080 instruction, like LD A,R)

    in      b,(c)       ; #ED40
    out     (c),b       ; #ED41
    sbc     hl,bc       ; #ED42
    ld      (#100),bc   ; #ED430001
    neg                 ; #ED44
    retn                ; #ED45
    im 0                ; #ED46
    ld      i,a         ; #ED47
    in      c,(c)       ; #ED48
    out     (c),c       ; #ED49
    adc     hl,bc       ; #ED4A
    ld      bc,(#100)   ; #ED4B0001
    reti                ; #ED4D
    ld      r,a         ; #ED4F

    in      d,(c)       ; #ED50
    out     (c),d       ; #ED51
    sbc     hl,de       ; #ED52
    ld      (#100),de   ; #ED530001
    im 1                ; #ED56
    ld      a,i         ; #ED57
    in      e,(c)       ; #ED58
    out     (c),e       ; #ED59
    adc     hl,de       ; #ED5A
    ld      de,(#100)   ; #ED5B0001
    ld      a,r         ; #ED5F

    in      h,(c)       ; #ED60
    out     (c),h       ; #ED61
    sbc     hl,hl       ; #ED62
    rrd                 ; #ED67
    in      l,(c)       ; #ED68
    out     (c),l       ; #ED69
    adc     hl,hl       ; #ED6A
    rld                 ; #ED6F

    in      f,(c)       ; #ED70
    out     (c),0       ; #ED71
    sbc     hl,sp       ; #ED72
    ld      (#100),sp   ; #ED730001
    in      a,(c)       ; #ED78
    out     (c),a       ; #ED79
    adc     hl,sp       ; #ED7A
    ld      sp,(#100)   ; #ED7B0001

    ldi                 ; #EDA0
    cpi                 ; #EDA1
    ini                 ; #EDA2
    outi                ; #EDA3
    ldd                 ; #EDA8
    cpd                 ; #EDA9
    ind                 ; #EDAA
    outd                ; #EDAB

    ldir                ; #EDB0
    cpir                ; #EDB1
    inir                ; #EDB2
    otir                ; #EDB3
    lddr                ; #EDB8
    cpdr                ; #EDB9
    indr                ; #EDBA
    otdr                ; #EDBB
