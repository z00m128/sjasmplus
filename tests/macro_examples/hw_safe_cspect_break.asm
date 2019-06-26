; The `s_break` macro is "safe" wrapper for CSpect breakpoint fake instruction `break`.
;
; On HW board (Z80N or regular Z80) the `break` opcode DD 01 will be processed
; as wrongly prefixed `ld bc,imm16`, eating further two bytes of the code after
; `break`, damaging value in BC register, and skipping two bytes of machine code.
;
; The `s_break` macro will produce 6 byte machine code which is "mostly harmless"
; on real HW except using stack to preserve BC value and taking 11+4+10+10 T cycles
; to execute. While in CSpect emulator with breakpoints enabled the code will still
; trigger the debugger (and add the "nop : nop : pop bc" extra instruction sequence
; after it).
;
; (I would still recommend to configure "debug" builds with exit/break enabled and
; having separate "release" configuration with `--zxnext` only, which will report
; any remaining break/exit instruction left in the source)
;
; (so this example is more like documentation that bad things happen if you forget
; CSpect `break` instruction somewhere and try such code on the HW board)
;

    MACRO s_break
        OPT push reset --zxnext=cspect
        push bc : break : nop : nop : pop bc
        OPT pop
    ENDM

        ; example of usage
        DEVICE ZXSPECTRUM48 : ORG $8000
start:
        ld      b,4
        xor     a
        s_break
myLoop:
        inc     a
        out     (254),a
        djnz    myLoop
        ; `exit` has opcode DD 00, which on regular Z80[N] works as 8T "nop" instruction
        OPT --zxnext=cspect : exit      ; i.e. no need for wrapping macro
        jr      $

        SAVESNA "break.sna", start : CSPECTMAP "break.map"
