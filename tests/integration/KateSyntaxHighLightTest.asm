;; This is not test of sjasmplus itself, but this is used to check Kate-syntax-highlight
;; The syntax highlight rules are in "asm-z80-sj.xml" file in the project root directory

    device zxspectrum48     ; directive of sjasmplus
    org     $A8, 0xA8, #A8  ; hexa, also: 0A8h
    disp    43008, 43008d   ; decimal
With relaxed syntax of Z80 assemblers, "label" is usually default result of anything

    ld      hl, %10011100, de, 0b10011100   ; binary, also: 0011b
    ld      de, 7777o, bc, 0q7777           ; octal, also: 77q
    ld      bc, %1111'0000  ; C++ num-group separator
    db      'apostrophe''s "text"', "quotes\'\\\"\? 'text'", 0
    ldirx
    bsra    de,b            ; NEXT opcodes of course added (can have different colour)
    cp      ''''            ;"TODO" in comments exists (also FIXME and FIX ME).
s:  ; some label
// also C line comments supported
    call    s, s            ; conditional call/jp/jr/ret highlights also condition
        ; "s" is actually unofficial alias for "m" supported by some assembler ("ns"=p)
    ret     nz              ; control-flow instructions are extra colour
    rlc     (ix-128),e      ; unofficial Z80 instructions are highlighted extra
    res     5,(ix+6),a      ; (but it goes also over arguments, maybe shouldn't, TODO)
    res     5,(ix+30)       ; compared to official instruction

    and     7+(3<<1)
    and     low .localLab   ; FIXME: operators are mostly defined, but rules are missing

    MACRO leMacron _arg0?
        defb    $DD, 1
        nextreg $15, $0
    ENDM

    ; in case you accidentally write non-instruction, it will highlight as label! :D
    jnz     s               ; still makes it easier to catch
    leMacron arg0           ; but so do also correctly used macros
.localLab:
    hex     F32712bcd3561   ; unpaired digit or non-digit is highlighted as "error"
!!alsoThisInvalidLabel
    dg      ..##..##  #$01!-._  ; DG bit map is highlights as "data" (0) vs "number" (1)
