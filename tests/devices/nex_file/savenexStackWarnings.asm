    DEVICE ZXSPECTRUMNEXT

    ORG $8004-12
    DB  $12
    DS  11, 0
    jr  $       ; bank 2, $8004

    ORG $C004-12
    DB  $12
    DS  11, 0
    jr  $       ; bank 0, $C004

    MMU 0, 10*2, $0004
    jr  $       ; bank 10, $C004 (the taint ahead is already there)

    MMU 0 7, 100 ; map the Z80 address space to completely unrelated pages

;; OPEN <filename>[,<startAddress>[,<stackAddress>[,<entryBank 0..111>[,<fileVersion 2..3>]]]]
    ; warning about ROM area
    SAVENEX OPEN "savenexStackWarnings.nex", $8004, $0001 : SAVENEX CLOSE
    SAVENEX OPEN "savenexStackWarnings.nex", $8004, $4009 : SAVENEX CLOSE

    ; byte-check warnings (valid + tainted for various slot/banks)
    SAVENEX OPEN "savenexStackWarnings.nex" : SAVENEX CLOSE     ; PC=0, SP=0xFFFE

    ; check if wrap-around from $0000 targets correct bank (0 or entryBank) during check
    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $0000 : SAVENEX CLOSE
    MMU 0, 0*2+1, $1FFF : DB $23    ; taint end of Bank0
    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $0000 : SAVENEX CLOSE   ; warning

    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $0000, 10 : SAVENEX CLOSE
    MMU 0, 10*2+1, $1FFF : DB $34   ; taint end of Bank10
    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $0000, 10 : SAVENEX CLOSE   ; warning

    ; check other more regular crossings+taints of banks
    SAVENEX OPEN "savenexStackWarnings.nex", $8004, $400B : SAVENEX CLOSE
    MMU 0, 5*2, $000A : DB $45
    SAVENEX OPEN "savenexStackWarnings.nex", $8004, $400B : SAVENEX CLOSE   ; warning
    SAVENEX OPEN "savenexStackWarnings.nex", $8004, $400A : SAVENEX CLOSE
    MMU 0, 5*2, $0000 : DB $56
    SAVENEX OPEN "savenexStackWarnings.nex", $8004, $400A : SAVENEX CLOSE   ; warning

    SAVENEX OPEN "savenexStackWarnings.nex", $8004, $8004 : SAVENEX CLOSE
    MMU 0, 2*2, $0003 : DB $67
    SAVENEX OPEN "savenexStackWarnings.nex", $8004, $8004 : SAVENEX CLOSE   ; warning
    SAVENEX OPEN "savenexStackWarnings.nex", $8004, $8003 : SAVENEX CLOSE
    MMU 0, 5*2+1, $1FFF : DB $78
    SAVENEX OPEN "savenexStackWarnings.nex", $8004, $8003 : SAVENEX CLOSE   ; warning

    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $C004 : SAVENEX CLOSE
    MMU 0, 0*2, $0003 : DB $89
    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $C004 : SAVENEX CLOSE   ; warning
    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $C003 : SAVENEX CLOSE

    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $C004, 10 : SAVENEX CLOSE
    MMU 0, 10*2, $0003 : DB $9A
    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $C004, 10 : SAVENEX CLOSE   ; warning
    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $C003, 10 : SAVENEX CLOSE

    MMU 0, 2*2+1, $1FFF : DB $AB    ; taints both entryBank==0 and entryBank==10
    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $C003 : SAVENEX CLOSE   ; warning
    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $C003, 10 : SAVENEX CLOSE   ; warning
    SAVENEX OPEN "savenexStackWarnings.nex", $C004, $C003, 10 ; suppress: nexstack-ok
    SAVENEX CLOSE

    ASSERT 12 == __WARNINGS__
