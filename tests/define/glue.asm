  OUTPUT "glue.bin"
  ORG $4040
  DEFINE  FOO   FEE
  DEFINE  BAR   BER
  DEFINE  FEEBER   "Ahoy"
  DB  FOO  _  BAR
; -> FEE \032 BAR   ; not concatenated yet
; -> FEE \032 BER
; -> no more subs, now concat
; -> FEEBER
; -> "Ahoy"

FEE123:
  ld hl,FOO _ 123
; -> FEE \032 123
; -> no more subs
; -> FEE123

; solution for OP using such new operator
    MACRO M_TOTO arg
        LD HL,blah. _ arg
    ENDM

blah.argValue:
    M_TOTO argValue
    ; -> LD HL,blah.argValue

; _ vs substitution priority is issue without parentheses to resolve something like this to get "Ahoy"Z
FEEBERZ EQU '%'
  DB FOO _ BAR _ Z
; -> FEE \032 BAR _ Z
; -> FEE \032 BER \032 Z
; -> no more subs, now concat
; -> FEEBERZ
; -> at no point there is "FEEBER _ Z" to create "Ahoy"Z

  DB FOO _ BAR _ _ Z
; -> FEE \032 BAR _ _ Z
; -> FEE \032 BER \032 _ Z
; -> no more subs, now concat
; -> FEEBER_ Z
; -> "Ahoy"_ Z
; -> argh ... it will lose whitespace, still fails, and that's the point of the op to glue operands together

  DEFINE STR_ZERO_SUFFIX _ Z
  DB FOO _ BAR STR_ZERO_SUFFIX
; -> FEE \032 BAR STR_ZERO_SUFFIX
; -> FEE \032 BER STR_ZERO_SUFFIX
; -> FEE \032 BER _ Z
; -> no more subs, now concat
; -> FEEBER _ Z
; -> "Ahoy" \032 Z
; -> no more subs, now concat
; -> "Ahoy"Z
; **SUCCESS**

; tests for leading trailing glue char, should be restored to '_' as there's nothing to glue from one side
  _ FOO
  FOO _
  _ FOO _
; EOL comments are out of the equation as well
  ; _ FOO
  FOO _ ;
; more combinations of sparse define triggering glue on both sides (against static text)
  1 _ FOO
  FOO _ 2
  3 _ FOO _ 4
  5 _ FOO _ 6 _ 7 _ BAR _ 8     ; 6 _ 7 is *not* a glue and must be preserved
; check robustness of parser code when substituting at start/end of buffer
FOO
 FOO ;
_ FOO _
 _ FOO _ ;

; make implementation thorough to process glues which become part of quoted string
; first version was using binary tag \x1A, but that can be part of user's source code in binary form
; after some attempts for complex fix, I reverted to old idea of abusing some other binary tag: 0x0A
; 0x0A can't be part of source code, as it is CR character doing new lines, so in source form it must be always \n or numeric literal
  DEFINE QUOTE "
  DB QUOTE _ FOO _ QUOTE        ; expected result: DB "FEE"
  DB "!  !" .. QUOTE _ FOO _ QUOTE .. "!  !"    ; (obsolete) but do NOT replace user's binary tags \x1A, only original `_` glues!
  DB "! \n !" .. QUOTE _ FOO _ QUOTE .. "! \n !"  ; (duh!) but do NOT replace user's \n, only original `_` glues!
  ; expected result: DB "FEE" .. "FEE" .. "FEE" with lot of spaces removed around glues
  DB QUOTE _ FOO \
     _ QUOTE .. QUOTE _ \
     FOO _\
     QUOTE .. QUOTE       _            FOO                 _                \
                                                              QUOTE
