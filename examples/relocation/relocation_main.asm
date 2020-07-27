    OPT --syntax=abfw
    DEVICE  ZXSPECTRUM48, $5D00

    ; prepare the code from address 0 to have table of offsets "from current address"
    ; (but store the resulting code from $8000)
    ORG     $8000
    DISP    $0000
    RELOCATE_START

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; relocator code, using address in BC as where the code did land
;; ("RANDOMIZE USR xyz" will provide BC=xyz)
;; the relocator will use the RELOCATE_TABLE data to adjust all instructions
;; as needed for the actual address where the code was loaded
;; (the relocator itself doesn't produce any relocation data)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

relocator_code:
; start of relocator
    ASSERT 0 < relocate_count   ; (for zero relocation_count the relocator is not needed!)
    ; BASIC sets BC to the address of start (after "RANDOMIZE USR x" BC=x upon entry)
        di
    ; preserve current SP into IX
        ld      ix,0
        add     ix,sp
    ; set SP to the relocation table data
        ld      hl,relocator_table-relocator_code   ; offset from start to the table
        add     hl,bc                               ; absolute address of table
        ld      sp,hl
    ; process the full table of relocation data (A + A' is counter of relocation values)
        ld      a,1+high relocate_count
        ex      af,af
        ld      a,1+low relocate_count
        jr      .relocate_loop_entry
.relocate_loop_outer:
        ex      af,af
.relocate_loop:
    ; relocate single record from the relocate table
        pop     hl
        add     hl,bc       ; HL = address of machine code to modify
        ld      e,(hl)
        inc     hl
        ld      d,(hl)      ; DE = value to modify
        ex      de,hl
        add     hl,bc       ; relocate the value
        ex      de,hl
        ld      (hl),d      ; patch the machine code in memory
        dec     hl
        ld      (hl),e
.relocate_loop_entry:
    ; loop until all "relocate_count" records were processed
        dec     a
        jr      nz,.relocate_loop
        ex      af,af
        dec     a
        jr      nz,.relocate_loop_outer
    ; restore SP
        ld      sp,ix
; end of relocator

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; "user code" - some code which needs to be relocated after loading at some
;; dynamic address (the relocation is done by code above, the following code
;; is just small graphics effect using some hard-coded addresses which need
;; relocation - as demonstration of the functionality)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; user code (will be relocated by relocator)
start:
    ; black border
        xor     a
        out     (254),a
    ; clear VRAM
        ld      hl,$4000
        ld      de,$4001
        ld      bc,$1800
        ld      (hl),l
        ldir
        ld      (hl),$40|4  ; bright green ink on black paper
        ld      bc,$300-1
        ldir
    ; print the graphics with "SjASMPlus" bitmap
        ld      hl,gfx_data
        ld      d,high $4800    ; $4800 address
        ld      a,8
draw_line
        ld      e,3*32 + 12 ; put it almost into middle of screen
        ld      bc,gfx_data.lineSz
        ldir
        inc     d
        dec     a
        jp      nz,draw_line
    ; keep the graphics scrolling around forever
scroll_loop:
        ei
        halt
        di
        ld      (.restore_sp),sp
        ld      sp,scroll_addresses
        ld      c,8
.one_line:
        pop     hl
        ld      a,(hl)      ; first byte value (to wrap around)
        pop     hl
        ld      b,gfx_data.lineSz
        rla
.one_line_loop:
        rl      (hl)
        dec     hl
        djnz    .one_line_loop
        dec     c
        jp      nz,.one_line
.restore_sp EQU $+1
        ld      sp,0
        jp      scroll_loop

gfx_data:
    DG  -***--**----*-----***--*-----*-*****--**----------------
    DG  **--*-**---***---**--*-**---**-**--**-**----------------
    DG  **---------***---**----***-***-**--**-**-**--**--****---
    DG  -***--**--**--*---***--**-*-**-*****--**-**--**-**------
    DG  ---**--*--*****-----**-**-*-**-**-----**-**--**--***----
    DG  *--**--*-**----*-*--**-**---**-**-----**-**--**----**---
    DG  -***---*-**----*--***--**---**-**------**-*****-****----
    DG  -----**-------------------------------------------------
.lineSz EQU     ($ - gfx_data)/8

scroll_addresses:
vram_line_first_byte = $4800 + 3*32 + 12
    DUP     8
        DW  vram_line_first_byte                        ; first byte of line
        DW  vram_line_first_byte + gfx_data.lineSz - 1  ; last byte of line
vram_line_first_byte = vram_line_first_byte + $100
    EDUP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; relocation data table is at the end of the code block
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

relocator_table:
    RELOCATE_TABLE

; total size of code block
code_size   EQU     $ - relocator_code
    RELOCATE_END
    ENT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BASIC loader for TAP file (in include file)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    INCLUDE "relocation_basic.i.asm"

    MakeTape "relocate.tap", "relocate", $8000, code_size

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ZX48 SNA file for debugging (enable by "IF 1" change)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    IF 0    ; DEBUG use "1" to produce ZX48 snapshot file (simpler to debug in CSpect)
        SAVESNA "relocate.sna", $8000
    ENDIF
