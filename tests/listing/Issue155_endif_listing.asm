; Wrong address calculation in listing for lines with ENDIF keyword
 org 0

 align 16 : if 1 : block 0, $ff : endif  ; OK
 align 16 : if 1 : block 1, $ff : endif  ; OK
 align 16 : if 1 : block 2, $ff : endif  ; OK
 align 16 : if 1 : block 3, $ff : endif  ; OK
 align 16 : if 1 : block 4, $ff : endif  ; OK
 align 16 : if 1 : block 5, $ff : endif	 ; =$44 -> WRONG, MUST BE $45
 align 16 : if 1 : block 15, $ff : endif ; =$54 -> WRONG, MUST BE $5F

; nested condition

 align 16 : if 1 : if 1 : block 0, $ff : endif : endif  ; OK
 align 16 : if 1 : if 1 : block 1, $ff : endif : endif  ; OK
 align 16 : if 1 : if 1 : block 2, $ff : endif : endif  ; OK
 align 16 : if 1 : if 1 : block 3, $ff : endif : endif  ; OK
 align 16 : if 1 : if 1 : block 4, $ff : endif : endif  ; OK
 align 16 : if 1 : if 1 : block 5, $ff : endif : endif  ; =$A4 -> WRONG, MUST BE $A5
 align 16 : if 1 : if 1 : block 15, $ff : endif : endif ; =$B4 -> WRONG, MUST BE $BF
