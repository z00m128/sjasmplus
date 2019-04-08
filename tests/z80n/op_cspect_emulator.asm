    OUTPUT "op_cspect_emulator.bin"

    ;;; CSpect emulator extensions, instructions EXIT and BREAK
    ;;; available only with option `--zxnext=cspect`

    exit                            ; #DD00
    break                           ; #DD01
