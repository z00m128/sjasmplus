; various -W<warning_id> combinations (hopefully all of them, if possible)

; the default is "enabled" for all warnings - exercise all of them
abs:    ld hl,@abs ; placeholder for removed `ld hl,abs` (-Wabs removed in v1.20.0)
    DEVICE ZXSPECTRUMNEXT, $8000
    DEVICE NOSLOT64K, $8000
    DEVICE ZXSPECTRUM48, $8000 : DEVICE ZXSPECTRUM48, $8001
    DISP 123 : ORG 345 : ENT
    ORG 123, 0

    IF fwd_ref_label : ENDIF    ; it's W_EARLY warning, emitted before last pass, look at start of listing

    lua pass3
        _pc("nop")
    endlua

    DEVICE ZXSPECTRUMNEXT : ORG $8000 : ret : SAVENEX OPEN "various_W.nex", $8000, $8002 : SAVENEX CLOSE
    ; omitting "nexbmppal" test because it requires too many prerequisites (has dedicated tests any way)
    ; omitting "sna48" and "sna128" tests (have dedicated test any way)
    ; omitting "trdext", "trdext3", "trdextb" and "trddup" tests (have dedicated test)
    RELOCATE_START : ALIGN 2 : RELOCATE_END
    ld  a,(255)
    ; omitting "reldiverts" and "relunstable" test (relocation has many dedicated+updated tests)
    ; omitting "dispmempage" test (has dedicated test (non-trivial))
    SETBREAKPOINT
    out (c),0
















    ORG 0       ; start again at zero offset
; disable/enable specific warning and test specific-suppression in eol comment

    ; abs
    ; placeholder for removed -Wabs test to minimize diff
    ld hl,@abs

    ld hl,@abs
    ld hl,@abs

    ; impossible to re-test zxnramtop and noslotramtop, because they are emitted just once

    ; devramtop
    OPT -Wno-devramtop
    DEVICE ZXSPECTRUM48, $8002
    OPT -Wdevramtop
    DEVICE ZXSPECTRUM48, $8003  ; luamc-ok - some other id, should not suppress devramtop
    DEVICE ZXSPECTRUM48, $8004  ; but devramtop-ok should suppress it

    ; displacedorg
    DISP 101
    OPT -Wno-displacedorg
    ORG 201
    OPT -Wdisplacedorg
    ORG 202     ; luamc-ok - some other id, should not suppress displacedorg
    ORG 203     ; but displacedorg-ok should suppress it
    ENT

    ; orgpage
    OPT -Wno-orgpage
    ORG 123, 0
    OPT -Worgpage
    ORG 123, 0  ; luamc-ok - some other id, should not suppress orgpage
    ORG 123, 0  ; but orgpage-ok should suppress it

    ; fwdref
    OPT -Wno-fwdref
    IF fwd_ref_label
    ENDIF
    OPT -Wfwdref
    IF fwd_ref_label    ; luamc-ok - some other id, should not suppress fwdref
    ENDIF
    IF fwd_ref_label    ; but fwdref-ok should suppress it
    ENDIF

    ; luamc
    OPT -Wno-luamc
    lua pass3
        _pc("nop")
    endlua
    OPT -Wluamc
    lua pass3   ; devramtop-ok - some other id, should not suppress luamc
        _pc("nop")
    endlua
    lua pass3   ; but luamc-ok should suppress it
        _pc("nop")
    endlua
    lua pass3
        _pc("nop")
    endlua      ; but luamc-ok should suppress it (also at "endlua" line)

    ; nexstack
    DEVICE ZXSPECTRUMNEXT
    OPT -Wno-nexstack
    SAVENEX OPEN "various_W.nex", $8000, $8002
    SAVENEX CLOSE
    OPT -Wnexstack
    SAVENEX OPEN "various_W.nex", $8000, $8002  ; devramtop-ok - some other id, should not suppress nexstack
    SAVENEX CLOSE
    SAVENEX OPEN "various_W.nex", $8000, $8002  ; but nexstack-ok should suppress it
    SAVENEX CLOSE

    ; relalign
    RELOCATE_START
    OPT -Wno-relalign
    ALIGN 2
    OPT -Wrelalign
    ALIGN 4     ; devramtop-ok - some other id, should not suppress relalign
    ALIGN 8     ; but relalign-ok should suppress it
    RELOCATE_END

    ; rdlow
    OPT -Wno-rdlow
    ld  a,(255)
    OPT -Wrdlow
    ld  a,(255)  ; devramtop-ok - some other id, should not suppress rdlow
    ld  a,(255)  ; but rdlow-ok should suppress it

    ; bpfile
    OPT -Wno-bpfile
    SETBREAKPOINT
    OPT -Wbpfile
    SETBREAKPOINT   ; devramtop-ok - some other id, should not suppress bpfile
    SETBREAKPOINT   ; but bpfile-ok should suppress it

    ; out0
    OPT -Wno-out0
    out (c),0
    OPT -Wout0
    out (c),0   ; devramtop-ok - some other id, should not suppress out0
    out (c),0   ; but out0-ok should suppress it

; testing corner-case states possible with the -W option (test coverage)
    OPT -W -Wnon-existent-warning-id-to-cause-warning
fwd_ref_label:  EQU $1234
