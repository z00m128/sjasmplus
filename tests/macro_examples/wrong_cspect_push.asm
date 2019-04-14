; macro to emit Z80N `push imm16` opcode either in big endian (HW board), or little
; endian (CSpect emulator) way.

    MACRO PUSH_IMM16 _value?
        DB  $ED, $8A
        IFDEF CSPECT : DB low (_value?), high (_value?)
        ELSE : DB high (_value?), low (_value?) : ENDIF
    ENDM

    OUTPUT "wrong_cspect_push.bin"
    push        0x1234
    PUSH_IMM16  0x1234          ; should emit identical opcode as the sjasmplus itself
    PUSH_IMM16  (0x123<<4) + 4  ; check expression evaluation in macro

    DEFINE CSPECT   ; uncomment, or provide option `-DCSPECT` on CLI to get wrong opcode
    PUSH_IMM16  0x1234          ; should emit opcode with reversed HI/LO bytes
    PUSH_IMM16  (0x123<<4) + 4  ; check expression evaluation in macro
