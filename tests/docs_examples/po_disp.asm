    DEVICE ZXSPECTRUM48
SCREEN  EQU $4000
        ORG $8000
        LD HL,BEGIN
        LD DE,SCREEN
        LD BC,ENDOFPROG-BEGIN
        LDIR
        JP SCREEN
BEGIN   DISP SCREEN ;code will compile for address $4000, but to the current ORG
MARKA       DEC A
            HALT
            JP NZ,MARKA
            DI
            HALT
        ENT
ENDOFPROG

    ASSERT $800E == BEGIN && $8015 == ENDOFPROG && $4000 == MARKA
    ASSERT $76 == {B $800F}     ; HALT instruction lands at $800F (BEGIN+1)
