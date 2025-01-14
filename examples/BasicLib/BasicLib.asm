;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Basic writing library ;; Busy soft ;; 14.01.2025 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; This library can be used for (relative)
;; easy writing basic programs in SjASMPlus.
;;
;; Macros:
;;
;;   LINE ... begin of basic line
;;   LEND ... end of basic line
;;   NUM .... include number value into basic
;;   DEC .... Convert value to sequence of decadic digits only
;;
;; Control variables:
;;
;;   line_useval ... Enable use VAL "..." for macro NUM
;;   line_number ... Actual line number for actual basic line
;;   line_step ..... Increment for automatic numbering of lines
;;
;; Typical usage:
;;
;;   LINE : db bright : NUM 1        : LEND
;;   LINE : db print,'"Hello world"' : LEND
;;
;; ... generates this program:
;;
;;   10 BRIGHT 1
;;   20 PRINT "Hello world"
;;
;; Please see examples for more info.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Basic token definitions
;;
;;  Note:  absx notx orx andx  are used
;;  due to conflict with SjASMPlus operators
;;
;;  If you have conflict with another labels
;;  you can encapsulate your basic by this way:
;;
;;    MODULE basic
;;      INCLUDE BasicLib.asm
;;      LINE : ...... : LEND
;;      LINE : ...... : LEND
;;    ENDMODULE
;;
;;  You can create more basic programs
;;  in your source code by this way.

spectrum	equ	#A3
play		equ	#A4
rnd		equ	#A5
inkey		equ	#A6
pi		equ	#A7
fn		equ	#A8
point		equ	#A9
screen		equ	#Aa
attr		equ	#Ab
at		equ	#Ac
tab		equ	#Ad
valS		equ	#Ae
code		equ	#Af
val		equ	#B0
len		equ	#B1
sin		equ	#B2
cos		equ	#B3
tan		equ	#B4
asn		equ	#B5
acs		equ	#B6
atn		equ	#B7
ln		equ	#B8
exp		equ	#B9
int		equ	#Ba
sqr		equ	#Bb
sgn		equ	#Bc
absx		equ	#Bd
peek		equ	#Be
in		equ	#Bf
usr		equ	#C0
str		equ	#C1
chr		equ	#C2
notx		equ	#C3
bin		equ	#C4
orx		equ	#C5
andx		equ	#C6
line		equ	#Ca
then		equ	#Cb
to		equ	#Cc
step		equ	#Cd
deffn		equ	#Ce
cat		equ	#Cf
format		equ	#D0
move		equ	#D1
erase		equ	#D2
open		equ	#D3
close		equ	#D4
merge		equ	#D5
verify		equ	#D6
beep		equ	#D7
circle		equ	#D8
ink		equ	#D9
paper		equ	#Da
flash		equ	#Db
bright		equ	#Dc
inverse		equ	#Dd
over		equ	#De
out		equ	#Df
lprint		equ	#E0
llist		equ	#E1
stop		equ	#E2
read		equ	#E3
data		equ	#E4
restore		equ	#E5
new		equ	#E6
border		equ	#E7
cont		equ	#E8
continue	equ	#E8
dim		equ	#E9
rem		equ	#Ea
for		equ	#Eb
goto		equ	#Ec
gosub		equ	#Ed
input		equ	#Ee
load		equ	#Ef
list		equ	#F0
let		equ	#F1
pause		equ	#F2
next		equ	#F3
poke		equ	#F4
print		equ	#F5
plot		equ	#F6
run		equ	#F7
save		equ	#F8
rand		equ	#F9
randomize	equ	#F9
if		equ	#Fa
cls		equ	#Fb
draw		equ	#Fc
clear		equ	#Fd
return		equ	#Fe
copy		equ	#Ff

;; Basic UDG definitions

udg_a	  equ	#90	;; 144
udg_b	  equ	#91	;; 145
udg_c	  equ	#92	;; 146
udg_d	  equ	#93	;; 147
udg_e	  equ	#94	;; 148
udg_f	  equ	#95	;; 149
udg_g	  equ	#96	;; 150
udg_h	  equ	#97	;; 151
udg_i	  equ	#98	;; 152
udg_j	  equ	#99	;; 153
udg_k	  equ	#9A	;; 154
udg_l	  equ	#9B	;; 155
udg_m	  equ	#9C	;; 156
udg_n	  equ	#9D	;; 157
udg_o	  equ	#9E	;; 158
udg_p	  equ	#9F	;; 159
udg_q	  equ	#A0	;; 160
udg_r	  equ	#A1	;; 161
udg_s	  equ	#A2	;; 162
udg_t	  equ	#A3	;; 163
udg_u	  equ	#A4	;; 164

;; Basic control codes

comma	  equ	#06	;; db print,'"X',comma,'Y"'
left	  equ	#08	;; db print,'"',border,left,left,'L V',border,left,'I"'
right	  equ	#09	;; (does not work due to bug in zx rom)
enter	  equ	#0D	;; end of basic line, cannot be used inside of line normally
number	  equ	#0E	;; db '65535',number,0,0,#FF,#FF,0   ;;   But you can use: NUM 65535
s_ink	  equ	#10	;; db print,'"',s_ink    ,2,'Hello world!"'
s_paper	  equ	#11	;; db print,'"',s_paper  ,5,'Hello world!"'
s_flash	  equ	#12	;; db print,'"',s_flash  ,1,'Hello world!"'
s_bright  equ	#13	;; db print,'"',s_bright ,1,'Hello world!"'
s_inverse equ	#14	;; db print,'"',s_inverse,1,'Hello world!"'
s_over	  equ	#15	;; db print,'"',s_over   ,1,'Hello world!"'
s_at	  equ	#16	;; db print,'"',s_at,10,10 ,'Hello world!"'
s_tab	  equ	#17	;; db print,'"',s_tab,10,0 ,'Hello world!"'

;; Default setting of control variables

line_useval	=	0
line_number	=	10
line_step	=	10

  IFNDEF  BASICLIB_MACROS_DEFINED
  DEFINE  BASICLIB_MACROS_DEFINED

;; Begin of basic line

LINE  MACRO
	ASSERT line_number < #4000 , Line number overflows
	db	high line_number
	db	low line_number
	LUA ALLPASS
	sj.parse_code('dw line_' .. tostring(sj.calc("line_number")) .. '_length')
	sj.parse_line(   'line_' .. tostring(sj.calc("line_number")) .. '_begin')
	ENDLUA
      ENDM

;; End of basic line

LEND  MACRO
	db	#0D
	LUA ALLPASS
	sj.parse_line('line_'
		.. tostring(sj.calc("line_number"))
		.. '_length = $ - line_'
		.. tostring(sj.calc("line_number"))
		.. '_begin')
	ENDLUA
line_number  =	line_number + line_step
      ENDM

;; Include number value into basic line

NUM   MACRO	value
	IF line_useval
	  db	val,'"'
	ENDIF
	  LUA ALLPASS
	  sj.parse_code('db	"' .. tostring(sj.calc("value")) .. '"')
	  ENDLUA
	IF line_useval
	  db	'"'
	ELSE
	  db	#0E,0,0
	  dw	value
	  db	#00
	ENDIF
      ENDM

;; Convert value to sequence of decadic digits only

DEC	MACRO	value
	  LUA ALLPASS
	  sj.parse_code('db	"' .. tostring(sj.calc("value")) .. '"')
	  ENDLUA
	ENDM

  ENDIF		;; BASICLIB_MACROS_DEFINED ;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
