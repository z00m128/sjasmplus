; -Wall and -Wno-all test

    OPT -Wall   ; enable all extra warnings
abs:    ld hl,abs
    DEVICE ZXSPECTRUMNEXT, $8000
    DEVICE NOSLOT64K, $8000
    DEVICE ZXSPECTRUM48, $8000 : DEVICE ZXSPECTRUM48, $8001
    DISP 123 : ORG 345 : ENT
    ORG 123, 0

    IF fwd_ref_label : ENDIF    ; it's W_EARLY warning, emitted before last pass, look at start of listing

    lua pass3
        _pc("nop")
    endlua

    DEVICE ZXSPECTRUMNEXT : ORG $8000 : ret : SAVENEX OPEN "all_W.nex", $8000, $8002 : SAVENEX CLOSE
    ; omitting "nexbmppal" test because it requires too many prerequisites (has dedicated tests any way)
    ; omitting "sna48" and "sna128" tests (have dedicated test any way)
    ; omitting "trdext", "trdext3", "trdextb" and "trddup" tests (have dedicated test)
    RELOCATE_START : ALIGN 2 : RELOCATE_END
    ld  a,(255)
    ; omitting "reldiverts" and "relunstable" test (relocation has many dedicated+updated tests)
    ; omitting "dispmempage" test (has dedicated test (non-trivial))
    SETBREAKPOINT
    out (c),0
    INCBIN "back\slash.bin"
    ld hl,de


    ORG 0       ; start again at zero offset
    OPT -Wno-all    ; disable all extra warnings
    ld hl,abs

    ; impossible to re-test zxnramtop and noslotramtop, because they are emitted just once

    ; devramtop
    DEVICE ZXSPECTRUM48, $8002

    ; displacedorg
    DISP 101 : ORG 201 : ENT

    ; orgpage
    ORG 123, 0

    ; fwdref
    IF fwd_ref_label : ENDIF

    ; luamc
    lua pass3
        _pc("nop")
    endlua

    ; nexstack
    DEVICE ZXSPECTRUMNEXT : SAVENEX OPEN "all_W.nex", $8000, $8002 : SAVENEX CLOSE

    ; relalign
    RELOCATE_START : ALIGN 2 : RELOCATE_END

    ; rdlow
    ld  a,(255)

    ; bpfile
    SETBREAKPOINT

    ; out0
    out (c),0

    ; backslash
    INCBIN "back\slash.bin"

    ; fake
    ld hl,de

fwd_ref_label:  EQU $1234
