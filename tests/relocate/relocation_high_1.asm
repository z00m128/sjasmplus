        OPT --zxnext

        STRUCT RELSTRUCT
Byte        BYTE        $11
Word        WORD        $2233
Tribyte     D24         $445566
Dword       DWORD       $778899AA
Text        TEXT        6, { "Hello", 0 }
        ENDS

; first section is not part of relocation table
; =============================================

        ORG $8000
        ; same as the relocatable block, but outside of RELOCATE_START -> RELOCATE_END
            ld      hl,label1
            ld      hl,(label1)
            ld      (label1),hl
            ld      iy,label1
            ld      iy,(label1)
            ld      (label1),iy
            ld      de,label1
            ld      de,(label1)
            ld      (label1),de
            ld      a,(label1)
            ld      (label1),a
            call    label1
            jp      label1
            add     hl,label1
            RELSTRUCT {,label1,,,{"text",0}}
            DW      s1, s1.end, s1.Tribyte, s1.Text, $
            push    label2
            push    high label2
            ld      b,high label2
            ld      c,high label2
            ld      d,high label2
            ld      e,high label2
            ld      l,high label2
            ld      h,high label2
            ld      (hl),high label2
            ld      a,high label2
            add     a,high label2
            adc     a,high label2
            sub     high label2
            sbc     a,high label2
            and     high label2
            xor     high label2
            or      high label2
            cp      high label2
            test    high label2
            nextreg $00,high label2
            ld      ixh,high label2
            ld      ixl,high label2
            ld      (ix+123),high label2
            ld      iyh,high label2
            ld      iyl,high label2
            ld      (iy+123),high label2
            RELSTRUCT {high label2,high label2,,,{"ZX",0}}
            DB      high s2, high s2.end, high s2.Tribyte, high s2.Text, high $
            ABYTE   123 high label2-123
            ABYTEZ  123 high label2-123
            add     a,l2_high
            ld      hl,l2_high
            ld      hl,(l2_high)
            ld      (l2_high),hl
            ld      iy,l2_high
            ld      iy,(l2_high)
            ld      (l2_high),iy
            ld      de,l2_high
            ld      de,(l2_high)
            ld      (l2_high),de
            ld      a,(l2_high)
            ld      (l2_high),a
            call    l2_high
            jp      l2_high
            add     de,l2_high
            RELSTRUCT {,l2_high,,,{"text",0}}
            DW      high s4, high s4.end, high s4.Tribyte, high s4.Text, high $

; resulting relocation data
; =========================

        DW      relocate_count, relocate_size

        RELOCATE_TABLE      ; provides relocation addresses pointing directly at the high byte

        RELOCATE_TABLE +1   ; provides relocation addresses pointing one byte ahead of the high byte

; second section does test relocation
; ===================================

    RELOCATE_START HIGH
        ORG $0000
        ; relocation cases - word immediate instructions (relocation points at high byte)
            ld      hl,label1
            ld      hl,(label1)
            ld      (label1),hl
            ld      iy,label1
            ld      iy,(label1)
            ld      (label1),iy
            ld      de,label1
            ld      de,(label1)
            ld      (label1),de
            ld      a,(label1)
            ld      (label1),a
label1:
            call    label1
            jp      label1
            add     hl,label1           ; z80n extras
s1          RELSTRUCT {,label1,,,{"text",0}}
.end:
            DW      s1, s1.end, s1.Tribyte, s1.Text, $

        ORG $0FF0
        ; super special z80n extra, not working in regular full-word relocation mode
            push    label2              ; but these are possible in HIGH mode
            push    high label2

        ORG $1101
        ; relocation cases - byte immediate instructions (relocation points at immediate (high byte))
            ld      b,high label2
            ld      c,high label2
            ld      d,high label2
            ld      e,high label2
label2:
            ld      l,high label2
            ld      h,high label2
            ld      (hl),high label2
            ld      a,high label2
            add     a,high label2
            adc     a,high label2
            sub     high label2
            sbc     a,high label2
            and     high label2
            xor     high label2
            or      high label2
            cp      high label2
            test    high label2         ; z80n extras
            nextreg $00,high label2     ; z80n extras
            ; IX block
            ld      ixh,high label2
            ld      ixl,high label2
            ld      (ix+123),high label2
            ; IY block
            ld      iyh,high label2
            ld      iyl,high label2
            ld      (iy+123),high label2
s2          RELSTRUCT {high label2,high label2,,,{"ZX",0}}
.end:
            DB      high s2, high s2.end, high s2.Tribyte, high s2.Text, high $
            ABYTE   123 high label2-123
            ABYTEZ  123 high label2-123

            ; test EQU "transitiviness" and test word instruction with high byte only
        ORG $1380
l2_high     EQU     high label2
            add     a,l2_high           ; is equ transitive (keeping high/regular knowledge)?
            ld      hl,l2_high
            ld      hl,(l2_high)
            ld      (l2_high),hl
            ld      iy,l2_high
            ld      iy,(l2_high)
            ld      (l2_high),iy
            ld      de,l2_high
            ld      de,(l2_high)
            ld      (l2_high),de
            ld      a,(l2_high)
            ld      (l2_high),a
            call    l2_high
            jp      l2_high
            add     de,l2_high           ; z80n extras
s4          RELSTRUCT {,l2_high,,,{"text",0}}
.end:
            DW      high s4, high s4.end, high s4.Tribyte, high s4.Text, high $

        ORG $2200
        ; no relocation cases
            rst     $08
            DB      low label2, low s2, low s2.end, low s2.Tribyte, low s2.Text, low $
            ld      bc,label2 - label1
            ld      a,low label2
            ld      a,high label2 - high label1
            ld      (hl),high label2 - high label1
            ; IX block
            ld      (ix+low label2),123
            ld      (ix+123),low label2
            add     a,(ix+low label2)
            adc     a,(ix+low label2)
            sub     (ix+low label2)
            sbc     a,(ix+low label2)
            and     (ix+low label2)
            xor     (ix+low label2)
            or      (ix+low label2)
            cp      (ix+low label2)
            bit     0,(ix+low label2)
            bit     7&low label2,(ix+123)
            res     0,(ix+low label2)
            res     7&low label2,(ix+123)
            set     0,(ix+low label2)
            set     7&low label2,(ix+123)
            ; IY block
            ld      (iy+low label2),123
            ld      (iy+123),low label2
            add     a,(iy+low label2)
            adc     a,(iy+low label2)
            sub     (iy+low label2)
            sbc     a,(iy+low label2)
            and     (iy+low label2)
            xor     (iy+low label2)
            or      (iy+low label2)
            cp      (iy+low label2)
            bit     0,(iy+low label2)
            bit     7&low label2,(iy+123)
            res     0,(iy+low label2)
            res     7&low label2,(iy+123)
            set     0,(iy+low label2)
            set     7&low label2,(iy+123)

        ORG $4400
        ; unstable/can't be relocated by +offset mechanics
            out     (high label2),a     ; exception: out (imm8),a is never relocatable
            in      a,(high label2)     ; exception: in a,(imm8) is never relocatable
            nextreg high label2,$00     ; z80n extras - register number is never relocatable
            nextreg high label2,a       ; z80n extras - register number is never relocatable
            ; 16bit relocation should be warned against when only high-byte is possible
            ld      b,label1            ; even if the label is 8bit value like $0026
            ld      c,label1
            ld      d,label1
            ld      e,label1
            ld      l,label1
            ld      h,label1
            ld      (hl),label1
            ld      a,label1
            add     a,label1
            adc     a,label1
            sub     label1
            sbc     a,label1
            and     label1
            xor     label1
            or      label1
            cp      label1
            test    label1              ; z80n extras
            nextreg $00,label1          ; z80n extras
s3          RELSTRUCT {label1,,,,{"ZX",0}}
            DB      label1
            ; IX block
            ld      ixh,label1
            ld      ixl,label1
            ld      (ix+123),label1
            ld      (ix+high label2),123
            add     a,(ix+high label2)
            adc     a,(ix+high label2)
            sub     (ix+high label2)
            sbc     a,(ix+high label2)
            and     (ix+high label2)
            xor     (ix+high label2)
            or      (ix+high label2)
            cp      (ix+high label2)
            rlc     (ix+high label2)
            rrc     (ix+high label2)
            rl      (ix+high label2)
            rr      (ix+high label2)
            sla     (ix+high label2)
            sra     (ix+high label2)
            sli     (ix+high label2)
            srl     (ix+high label2)
            bit     0,(ix+high label2)
            bit     7&high label2,(ix+123)
            res     0,(ix+high label2)
            res     7&high label2,(ix+123)
            set     0,(ix+high label2)
            set     7&high label2,(ix+123)
            ; IY block
            ld      iyh,label1
            ld      iyl,label1
            ld      (iy+123),label1
            ld      (iy+high label2),123
            add     a,(iy+high label2)
            adc     a,(iy+high label2)
            sub     (iy+high label2)
            sbc     a,(iy+high label2)
            and     (iy+high label2)
            xor     (iy+high label2)
            or      (iy+high label2)
            cp      (iy+high label2)
            rlc     (iy+high label2)
            rrc     (iy+high label2)
            rl      (iy+high label2)
            rr      (iy+high label2)
            sla     (iy+high label2)
            sra     (iy+high label2)
            sli     (iy+high label2)
            srl     (iy+high label2)
            bit     0,(iy+high label2)
            bit     7&high label2,(iy+123)
            res     0,(iy+high label2)
            res     7&high label2,(iy+123)
            set     0,(iy+high label2)
            set     7&high label2,(iy+123)
            ; can't be relocated by +offset
            ld      hl,label2+label2
            ld      hl,label2>>1
            ld      a,high label2 + high label2
            ; transitive EQU
l1_regular  EQU     label1
            add     a,l1_regular

            ; ABYTE variants should report unstable when relocatable value is used for "offset" argument
            ABYTE   high label1 1, 2
            ABYTEZ  high label1 3

    RELOCATE_END

    RELOCATE_START      ; check if regular-mode emits error about mixing modes
