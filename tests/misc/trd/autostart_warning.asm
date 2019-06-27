;; separate test using the ordinary test-runner script and listing file to verify the warnings situation
;; (binary wise this is not testing anything, the binary tests are in savetrd**.asm tests)
    DEVICE ZXSPECTRUM128
    EMPTYTRD "autostart_warning.trd"
    ; warning about "autostart" for BASIC only
    SAVETRD "autostart_warning.trd","ok.B",$C001,$100,$1234
    SAVETRD "autostart_warning.trd","warn.C",$C001,$100,$1234
    SAVETRD "autostart_warning.trd","warn2.B",$C001,$100,10000  ; warning because max line is 9999
    ; other errors
    SAVETRD "autostart_warning.trd","err1.C",$C001,0        ; zero length
    SAVETRD "autostart_warning.trd","err2.C",0,$FF01        ; 0xFF01 length (length in sectors is 0x100+ = error)
    SAVETRD "autostart_warning.trd","ok2.C",$C000,$4000     ; OK: 0xC000+0x4000 = 0x10000
    SAVETRD "autostart_warning.trd","err3.C",$C000,$4001    ; err: 0xC000+0x4001 = 0x10001
    SAVETRD "autostart_warning.trd","ok3.C",0,$FF00         ; OK: FF00 length = just fits (last one)
    SAVETRD "autostart_warning.trd","err4.B",0,$FEFD,$1234  ; err: FEFD length + autostart = too many sectors (0x100+)
    SAVETRD "autostart_warning.trd","warn.X",1,2            ; warning about invalid extension
