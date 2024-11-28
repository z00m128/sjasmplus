; DOCS design (happened here, while working on it):
;
;     MMU <first slot number> [<last slot number>|<single slot option>], <page number>
;
; Maps memory page(s) to slot(s), similar to SLOT + PAGE combination, but allows to set up
; whole range of consecutive slots (with consecutive memory pages). Or when only single
; slot is specified, extra option can be used to extend particular slot functionality.
; The slot behaviour will stay set in the current DEVICE until reset by another MMU
; specifying same slot (even as part of range, that will clear the option to "default").
;
; Single slot option (default state is: no error/warning and no wrap = nothing special):
;     e = error on writing beyond last byte of slot
;     w = warning on writing beyond last byte of slot
;     n = wrap address back to start of slot, map next page
;

    DEVICE NONE         ; set "none" explicitly, to avoid "global device" feature
    MMU                 ;; warning about non-device mode
    DEVICE ZXSPECTRUM128

    ;; error messages (parsing test)
    MMU !
    MMU 1
    MMU 1 !
    MMU 1 x ; white space (or comma) after char to detect it as unknown option
    MMU 1 x,
    MMU 1 1
    MMU 0,
    MMU 0 1,
    MMU 0 e,
    MMU 0 e,!

    ;; correct syntax, invalid arguments
    MMU 0,8
    MMU 4,0
    MMU 3 4,0
    MMU 0 0,8
    MMU 1 0,0
    MMU 0 2,6   ; map pages 6, 7, 8 -> 8 is wrong

    ;; test functionality
    ; set init markers in pages 0, 5, 6 and 7
    DB  "77" : ORG 0xC000 : DB "00" : ORG 0xC000, 5 : DB "55" : ORG 0xC000, 6 : DB "66"
    PAGE 7 : ASSERT {0xC000} == "77" : PAGE 6 : ASSERT {0xC000} == "66"
    PAGE 5 : ASSERT {0xC000} == "55" : PAGE 0 : ASSERT {0xC000} == "00"

    ; test simple page-in
    MMU 0, 5    : ASSERT {0} == "55"
    MMU 1 3, 5  : ASSERT {0x4000} == "55" : ASSERT {0x8000} == "66" : ASSERT {0xC000} == "77"

    ;; test slot options (these are confined to single slot only, not to range)
    ; error option (guarding machine code write outside of current slot)
    MMU 1 e, 5  : ASSERT {0x4000} == "55"
    ORG 0x7FFF  : ld (hl),'s'   ; should be error, 2B opcode leaving slot memory
    ASSERT {0x8000} == "6s"     ; but damage is done in the virtual memory, that's how it is
    ; while escaping from slot through ORG should be legal
    ORG 0x7FFF  : nop : ORG 0x8000 : DB "66"
    ; changing page within tainted slot will keep the guarding ON
    SLOT 1 : PAGE 6 : ASSERT {0x4000} == "66"           ; map page 6 also into slot 1
    ORG 0x7FFF  : ld (hl),'s' : ASSERT {0x8000} == "6s" ; error + damage check

    ; verify clearing option by another MMU
    MMU 1, 5    : ASSERT {0x4000} == "55"
    ORG 0x7FFF  : ld (hl),'6' : ASSERT {0x8000} == "66" ; no error

    ; warning option (guarding machine code write outside of current slot)
    MMU 1 w, 5  : ASSERT {0x4000} == "55"
    ORG 0x7FFF  : ld (hl),'s'   ; should be warning, 2B opcode leaving slot memory
    ASSERT {0x8000} == "6s"     ; but damage is done in the virtual memory, that's how it is
    ; while escaping from slot through ORG should be legal
    ORG 0x7FFF  : nop : ORG 0x8000 : DB "66"
    ; changing page within tainted slot will keep the guarding ON
    SLOT 1 : PAGE 6 : ASSERT {0x4000} == "66"           ; map page 6 also into slot 1
    ORG 0x7FFF  : ld (hl),'s' : ASSERT {0x8000} == "6s" ; warning + damage check

    ; verify clearing option by another MMU when the slot is part of range
    MMU 0 2, 5  : ASSERT {0x4000} == "6s"
    ORG 0x7FFF  : ld (hl),'7' : ASSERT {0x8000} == "77" ; no warning

    ; next option making the memory wrap, automatically mapping in next page
    MMU 1 n, 2
    ORG 0x4000 : BLOCK 3*16384, 'n' ; fill pages 2, 3 and 4 with 'n'
    ASSERT {0x4000} == "55" && {0x8000} == "77" ; page 5 is mapped in after that block
    SLOT 1                      ; verify the block write
    PAGE 2 : ASSERT {0x4000} == "nn"
    PAGE 3 : ASSERT {0x4000} == "nn"
    PAGE 4 : ASSERT {0x4000} == "nn"

    ; do the wrap-around test with instructions, watch labels land into different pages
    MMU 1 n, 4
    ORG 0x7FFE
label0_p4:  scf
label1_p4:  scf
label2_p5:  db "55"     ; "55"      ; first two bytes of page 5
    BLOCK   16381, 's'  ; leaves last byte of page 5 unfilled
label3_p5:  ld sp,"66"  ; '166'     ; last byte of page 5, first two bytes of page 6
    ASSERT $ == 0x4002 && $$ == 6
    PAGE 4 : ASSERT {0x7FFE} == "77"
    PAGE 5 : ASSERT {0x4000} == "55" && {0x4002} == "ss" && {0x7FFE} == "1s"
    PAGE 6 : ASSERT {0x4000} == "66"

    LABELSLIST "mmu.lbl"

;-----------------------------------------------------------
; new part to test the optional third <address> argument
    ; syntax errors
    MMU 0 e,0,
    MMU 0 e,0,!
    MMU 0 e,0,0,

    ; valid syntax with address -exercise different code-paths
    ORG 0x1234
    MMU 0, 0, 0x4000
    ASSERT 0x4000 == $ && 6 == $$ && {0x0000} == "00" && {$} == "66"
    MMU 0, 5, 0x12345   ; warning about truncating the address
    ASSERT 0x2345 == $ && 5 == $$
    DISP 0x8765
    MMU 0, 7, 0x1234
    ASSERT 0x1234 == $ && 7 ==  $$
    MMU 0, 6, 0x3456    ; displacedorg-ok - suppress warning about ORG inside DISP
    ASSERT 0x3456 == $ && 6 ==  $$
    ENT
    ASSERT 0x2345 == $ && 6 ==  $$

;-----------------------------------------------------------
; new part to verify bugfix for #245

    ; error option (guarding machine code write outside of current slot)
    MMU 1 e, 5  : ASSERT {0x4000} == "55"
    ORG 0x7FFF  : ccf : ccf     ; should be error, second `ccf` left the slot memory
    ASSERT {0x8000} == "7?"     ; but damage is done in the virtual memory, that's how it is

;-----------------------------------------------------------
; new part: third ORG argument will now warn when it's outside of slot range

    MMU 0, 0, 0x3FFF
    MMU 0, 0, 0x4000            ; warn
    MMU 1, 5, 0x3FFF            ; warn
    MMU 1, 5, 0x4000
    MMU 1, 5, 0x7FFF
    MMU 1, 5, 0x8000            ; warn
    MMU 1 2, 5, 0x3FFF          ; warn
    MMU 1 2, 5, 0x4000
    MMU 1 2, 5, 0xBFFF
    MMU 1 2, 5, 0xC000          ; warn
    MMU 3, 7, 0xBFFF            ; warn
    MMU 3, 7, 0xC000
