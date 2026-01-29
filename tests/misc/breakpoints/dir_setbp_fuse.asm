    device noslot64k

    org $8000

    setbp
    nop
    setbp $
    nop
    setbp $9000
    nop

    setbp   "z80:bc!=0"
    nop
    setbp $,"z80:de!=0"
    nop
    setbp   $A000,   'z80:hl=0'
    nop
    setbp $B000,""
    nop

    setbp &
    nop
    setbp "on monday" !WTF?
    nop
    setbp ,
    nop
    setbp , ""
    nop
    setbp $, ,
    nop

    bplist "dir_setbp_fuse.exp" fuse