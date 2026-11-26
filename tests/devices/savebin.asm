    DEVICE NONE
    SAVEBIN "fname",0,1     ; error because no device...

    DEVICE ZXSPECTRUM48
    ; syntax errors
    SAVEBIN "fname"
    SAVEBIN "fname",
    SAVEBIN "fname",&
    SAVEBIN "fname",-0x1'0001
    SAVEBIN "fname",+0x1'0000
    SAVEBIN "fname",,
    SAVEBIN "fname",0xC000,
    SAVEBIN "fname",0xC000,&
    SAVEBIN "fname",0xC000,-0x1'0000
    SAVEBIN "fname",0xC000,+0x1'0001
    SAVEBIN "savebin.$$$",-4,-4           ; end is not far enough, zero length -> write fails
        ; ^ this will still create empty file `savebin.$$$`

    ; expected syntax: SAVEBIN <filename>, <startaddr>[, <length>]
    ; valid range: for startaddr -0x1'0000..+0xFFFF, for length -0xFFFF..+0x1'0000
    ; start + length reaching outside of 64ki is silently clamped
    ; negative start means from end of RAM, zero or negative length means from end of RAM

    ; valid cases to verify negative start/end feature and basic functionality
    ORG $FFF0
    DB '0123456789ABCDEF'
    SAVEBIN "savebin.bin",$FFF0     ; default length is "to end of RAM" => 16 bytes here
    SAVEBIN "savebin.raw",$FFF0,4   ; '0123'
    SAVEBIN "savebin.tap",-8,-5     ; '89A'
