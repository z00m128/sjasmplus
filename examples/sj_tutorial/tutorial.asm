;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; QUICK tutorial showcasing base syntax / style of sjasmplus source for Z80 assembly
;;; for full description of all features, refer to sjasmplus `documentation.html`

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; suggested way to assemble this tutorial (to get also listing file for examination of result)
;;; from repo root: sjasmplus --lst --lstlab=sort examples/sj_tutorial/tutorial.asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
// comments to end-of-line can be started with `;` or `//`
/* block comments /* work too, but */ they are nested! */       ; so close all of the open blocks

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; numeric, string and other literals syntax
        DW 123, 1'234, -4_5_6       ; decimal integers, you separate digits groups freely by ' or _
        DW $CB'38, #F_FFF, 0x1277   ; hexadecimal integers
        DB %1100, 0b0101'0011       ; binary integers
        DB 0q1'5'0                  ; octal integer
        DB "quoted string can contain escape sequences\rlike \"enter\"(13) here\r"
        DB 'single quote doesn''t escape anything except '' itself, \n is "backslash,n", not value 10'
        ; more details: https://z00m128.github.io/sjasmplus/documentation.html#c_constants

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; labels must start at beginning of line, trailing colon is optional:
label                   ; first char is letter or underscore, for more details see:
                        ; https://z00m128.github.io/sjasmplus/documentation.html#s_labels
.local:                 ; local labels append to previous main label

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; instructions can NOT start at beginning of line, must be indented (otherwise it's label):
        ret             ; for instructions classic Zilog syntax is used
; there is multi-arg feature for most of the instructions, allowing to reuse same instruction
        push hl,de      ; emits: push hl : push de
; TRAP - with default syntax vs Zilog syntax of instructions this may lead to unexpected results:
        xor a,c         ; emits: xor a : xor c
; I strongly recommend switching syntax to hide multi-arg feature behind double comma
    OPT --syntax=a      ; multi-arg delimiter is now `,,`
        xor a,c         ; xor c (with `a,` parsed silently instead of implicit register A)
        xor b,,c        ; xor b : xor c with multi-arg feature
        pop bc,,de,hl   ; pop bc : pop de : pop hl - single comma still works for pop/push/inc/dec
; other syntax helper to report incorrect memory address usage in some cases
    OPT --syntax=b      ; whole expression in parentheses is legal only for memory access
        ld bc,(label)   ; legal, works
    ;   ld b,(label)    ; error: Illegal instruction (can't access memory): (label)
        ld b,+(label)   ; not a memory access, just immediate value expression
; fake instructions: https://z00m128.github.io/sjasmplus/documentation.html#s_fake_instructions
        sub hl,bc       ; or a : sbc hl,bc
    OPT reset --syntax=f; restore default syntax, then add warning to fake instruction usage
        sub hl,bc       ; fake-ok ; suppressing "warning[fake]: Fake instruction: sub hl,bc" by "fake-ok"
; multiple instruction on same line can be split by colon (works as fake new line, but without label)
        ldi:ldi:ldi     ; 3x `ldi` instruction
; undocumented Z80 instructions syntax (some examples, others are similar to these):
        sli b : sll b   ; opcode CB30 (shift left setting bottom bit to 1)
        in (c)          ; opcode ED70
        out (c),0       ; opcode ED71 ; "out0-ok" to suppress warning[out0]
        inc ixh,xh,hx   ; opcode DD24 (3x). Other: IXL (or XL, LX), IYH (YH, HY), IYL (YL, LY)
        rlc (ix+1),b    ; opcode DDCB0100 ; rotate left memory at IX+1 and copy result also to B
        res 0,(ix+2),a  ; opcode DDCB0287 ; reset lowest bit if (IX+2) and copy result also to A
    OPT --syntax=abf    ; **RECOMMENDED** syntax setting for new projects

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; assembler directives
; are entered in similar way as instructions, indent them with whitespace
data:   DB  1,2,3       ; define bytes 1, 2, 3
        ; CLI option `--dirbol` enables directives also at beginning of line (not recommended)
symbol: EQU $C123       ; gives value $C123 to symbol (aka label) `symbol`, no machine code
; conditional assembling
        IF 1 > 2        ; evaluates as false -> skipping block until ELSE/ELSEIF/ENDIF
            lalalala    ; other checks: IFN, IFDEF, IFNDEF, IFUSED, IFNUSED
        ENDIF
; macro definitions to create custom instructions (arguments are substituted as text)
        MACRO setsplitcounter repeats?
            ld bc,pair(low(repeats?), high((repeats?)-1)+1)
        ENDM
        setsplitcounter 200 + 56        ; -> `ld bc,pair(low(200 + 56), high((200 + 56)-1)+1)` -> ld bc,0x0001
loop:   djnz loop : dec c : jp nz,loop  ; loop 200+56 times
; DUP directive repeats anonymous-macro-block N times
        DUP 3, index
            DB index
            DB $FF
        EDUP            ; results in array: 00 FF 01 FF 02 FF
        .4 ldi          ; dot-repeater will repeat single instruction (4x `ldi` in this case)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; substitution system - happens before line is parsed, defined "ids" are replaced recursively
; setup for showcasing
        MACRO hltopassword password ; defined before global `password`
            ld hl,v_password
        ENDM
v_blue  DB "blue"Z      ; zero terminated string (string suffix `Z`)
v_red   DB "red"C       ; string with last char having bit 7 set (string suffix `C`)
        DEFINE password red     ; define "id" `password` to have value `red`
; default substitution works with sub-word matching
        ld hl,v_password; sub-word substitution happens at `_` boundaries
        ; so the line will be substituted to `ld hl,v_red` before being assembled
        ; you can see fully substituted line in listing file
; macro arguments overshadow the global defines (temporarily until `ENDM` end of macro)
        hltopassword blue   ; inside macro the `password` is `blue` -> `ld hl,v_blue`
; sub-word substitution does confuse some users and they prefer whole-word only
    OPT --syntax=s      ; switch OFF sub-word substitution
v_password  EQU 123     ; does define symbol `v_password`, not `v_red`
        ld hl,v_password; no sub-word substitution here -> `ld hl,123`
; there are several predefined defines: https://z00m128.github.io/sjasmplus/documentation.html#s_predefined
; and there is "glue" operator `_` to concatenate multiple defines together
        DEFINE QUOTE "
        DISPLAY QUOTE _ __FILE__ contains examples of basic syntax and features of sjasmplus"
        ; after substitution this becomes: DISPLAY "tutorial.asm contains examples..."

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; virtual devices
    DEVICE ZXSPECTRUM128, $7FFF ; virtual ZX Spectrum 128 with RAMTOP 0x7FFF, provides 128kiB of memory
        ; check documentation for devices: https://z00m128.github.io/sjasmplus/documentation.html#po_device
        ; default mapping of pages for ZX 128 is: 7, 5, 2, 0
    MMU $8000, 3, $8000 ; map page (aka bank) 3 at address $8000 and do ORG $8000 to assemble from there
        ret             ; this modified virtual device memory in page 3 at its offset 0 (currently mapped at $8000)
    ; SAVEBIN "ret.bin", $8000, 128 ; would save 128 bytes of *current* content of device memory (ie. `ret` instruction)
        ORG $8000
        rst 0           ; overwrite `ret` instruction with `rst 0` in the virtual device memory (still page 3)
    ; SAVEBIN "other.bin", $8000, 1 ; would save 1 byte of *current* content of device memory (`rst 0` instruction)
    MMU $8000, 5, $8000 ; map page 5 (same which is already mapped at $4000 by default) and ORG there
        DB  %0101'0101  ; writes into page 5 (this value is now "visible" both at $4000 and $8000, page 5 mapped in two different regions)
        ; this does NOT overwrite `rst 0` instruction in page 3
        ; that one is still there just un-mapped, not "visible" in 16 bit address space with current mapping
    ; SAVESNA "test.sna", $8000 ; snapshot with start at $8000 (the interrupts are disabled and sysvars may differ from expectations)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; and there's more: structures (`STRUCT`), Lua scripting, modules, temporary labels, ...
;;; check the full documentation for details
