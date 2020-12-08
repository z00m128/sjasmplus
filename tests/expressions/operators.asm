    ; simple tests of each operator
    DW  +0x1234, -0x1234
    DW  ~0x1234
    DW  !0x1234, not 0x1234
    DW  low 0x1234, high 0x1234
    DW  0x123 + 0x4560, 0x123 - 0x4560
    DW  0x12 * 0x34, 0x3456 / 0x12
    DW  0x3456 % 0x12, 0x3456 mod 0x12
    DW  0x1234 << 3, 0x1234 shl 3
    DW  -17768 >> 3, -17768 shr 3   ; -17768 = 0xFFFFBA98
    DW  0xBA98 >> 3, 0xBA98 shr 3   ; expressions are calculated in 32b! 0xBA98 => positive
    DW  -17768 >>> 3, 0xBA98 >>> 3  ; first is 0xFFFFBA98u>>3 (warning!)
    DW  0x1234 & 0x5678, 0x5678 and 0x1234
    DW  0x1234 ^ 0x5678, 0x5678 xor 0x1234
    DW  0x1234 | 0x5678, 0x5678 or 0x1234
    DW  0x1234 <? 0x5678, 0x5678 <? 0x1234
    DW  0x1234 >? 0x5678, 0x5678 >? 0x1234
    DB  0x1234 < 0x5678, 0x5678 < 0x1234, 0x1234 < 0x1234
    DB  0x1234 > 0x5678, 0x5678 > 0x1234, 0x1234 > 0x1234
    DB  0x1234 <= 0x5678, 0x5678 <= 0x1234, 0x1234 <= 0x1234
    DB  0x1234 >= 0x5678, 0x5678 >= 0x1234, 0x1234 >= 0x1234
    DB  0x1234 = 0x5678, 0x5678 = 0x1234, 0x1234 = 0x1234
    DB  0x1234 == 0x5678, 0x5678 == 0x1234, 0x1234 == 0x1234
    DB  0x1234 != 0x5678, 0x5678 != 0x1234, 0x1234 != 0x1234
    DB  0x0012 && 0x3400, 0 && 0x3400, 0x0012 && 0, 0 && 0
    DB  0x0012 || 0x3400, 0 || 0x3400, 0x0012 || 0, 0 || 0
    DW  (2 * 3) + 4, 2 * (3 + 4)
    DW  $

    ; shifts vs 32bit evaluator, more (tricky) tests:
    DW  0xABCD1234 << 3, 0xABCD1234 shl 3
    DW  -1164413356 >> 19, -1164413356 shr 19   ; -1164413356 = 0xBA987654
    DW  0xBA987654 >> 19, 0xBA987654 shr 19
    DW  -1164413356 >>> 19, 0xBA987654 >>> 19

    ; simple error states
    DB ! : DB not : DB ~ : DB + : DB - : DB low : DB high
    DB 4 * : DB 5 / : DB 6 % : DB 7 mod
    DB 8 / 0 : DB 9 % 0 : DB 10 mod 0
    DB 11 + : DB 12 -
    DB 13 << : DB 14 shl : DB 15 >> : DB 16 shr : DB 17 >>>
    DB 18 & : DB 19 and : DB 20 ^ : DB 21 xor : DB 22 | : DB 23 or
    DB 24 <? : DB 25 >?
    DB 26 < : DB 27 > : DB 28 <= : DB 29 >= : DB 30 = : DB 31 == : DB 32 !=
    DB 33 && : DB 34 || : DB ( : DB )

    DEVICE NONE
    ORG 0
    DW  0x1234
    DW  $$      ; error when not in device mode
    DW  { 0 }
    DW  {b 0 }
    DEVICE ZXSPECTRUM48
    ORG 0
    DW  0x1234
    DW  $$      ; should be OK
    DW  { 0 }
    DW  {b 0 }


    ld  hl,?not     ; deprecated, use "@not" with full global name, or don't use keywords for label names at all

    ; new in v1.18.0
    DB  abs 16,abs -16,abs(32),abs(-32), abs ( 128 ) , abs ( -128 ),abs(256),abs(-256)
    DW  abs 16,abs -16,abs(32),abs(-32), abs ( 128 ) , abs ( -128 ),abs(65536),abs(-65536)

    DW  abs         ; warning about ABS being now new operator (to be removed ~Dec 2021)

; check all operator keywords to warn about their usage as labels
abs:
and:
high:
low:
mod:
norel:
not:
or:
shl:
shr:
@xor:   ; also global prefix "@" shouldn't matter, should still warn about it!

; Capitalized variant is ok. It's actually ok also all-caps variant, which should NOT be ok,
; but whoever uses label like XOR is beyond any good taste and I don't care about him.
Abs:
And:
High:
Low:
Mod:
Norel:
Not:
Or:
Shl:
Shr:
Xor:
