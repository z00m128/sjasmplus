    OPT --zxnext=cspect
    OUTPUT "op_cspect_emulator.bin"

    ;;; CSpect emulator extensions, instructions EXIT and BREAK
    ;;; available only with option `--zxnext=cspect`

    exit                            ; #DD00 ; CSpect CLI enable switch: -exit
    break                           ; #FD00 ; CSpect CLI enable switch: -brk

    ; since v3.0.1.5b (~2025-Feb), marking address range to trigger breakpoints

    ; type "tt": 0 exe, 1 read, 2 write, 3 outPort, 4 inPort
    ; start "bbbb" and end "eeee" are 16bit addresses, little endian
    setbrk $11, $4567, $ABCD        ; #ED01ttbbbbeeee ; CSpect CLI enable switch: -cspect
    clrbrk $22, $5678, $BCDE        ; #ED02ttbbbbeeee ; CSpect CLI enable switch: -cspect
