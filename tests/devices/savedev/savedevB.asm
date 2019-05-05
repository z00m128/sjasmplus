; future docs designed here:
; SAVEDEV <filename>,<startPage>,<startOffset>,<length>
;   Works only in real device emulation mode. See <link linkend="po_device">DEVICE</link>.
;
;   Like <link linkend="po_savebin">SAVEBIN</link>, saves the block of device RAM.
;
;   But it allows lengths over 64ki, and the offset value goes directly into device
;   virtual memory (where pages are allocated consecutively), ignoring current slot
;   "mapping". I.e. page=2,offset=0 will start saving data from page 2 at its beginning,
;   going through pages 3, 4, 5, ... until the requested length of data is saved.
;
;   The offset is not limited to page size, i.e. arguments page=1,offset=0x500 are equal
;   to arguments page=0,offset=0x4500 for ZXSPECTRUM128 device (has page size 0x4000).
;
    DEVICE NONE
    SAVEDEV "savedevB.bin",0,0,1
    DEVICE ZXSPECTRUM128
    ; test error messages of SAVEDEV - missing arguments
    SAVEDEV
    SAVEDEV "savedevB.bin"
    SAVEDEV "savedevB.bin",
    SAVEDEV "savedevB.bin",0
    SAVEDEV "savedevB.bin",0,
    SAVEDEV "savedevB.bin",0,0
    SAVEDEV "savedevB.bin",0,0,

    ; test error messages of SAVEDEV - wrong arguments
    SAVEDEV "savedevB.bin",-1,0,1      ; wrong page
    SAVEDEV "savedevB.bin",8,0,1       ; wrong page
    SAVEDEV "savedevB.bin",0,0,0       ; should be just warning about zero length (no file)
    SAVEDEV "savedevB.bin",0,-1,0      ; negative offset
    SAVEDEV "savedevB.bin",1,-0x4001,0 ; negative offset
    SAVEDEV "savedevB.bin",0,0x20000,0 ; offset beyond ZX128 memory
    SAVEDEV "savedevB.bin",7,0x4000,0  ; offset beyond ZX128 memory
    SAVEDEV "savedevB.bin",0,9,-1      ; negative length
    SAVEDEV "savedevB.bin",7,0x3FFF,2  ; length is +1 byte more than possible
