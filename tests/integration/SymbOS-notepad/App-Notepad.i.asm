;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                               N o t e p a d                                @
;@                                                                            @
;@             (c) 2012-2014 by Prodatron / SymbiosiS (Jörn Mika)             @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Todo
;- find nach doc-ende von vorne anfangen bis curpos
;- commands 29-31 focus setzen!


;--- PROGRAM-ROUTINES ---------------------------------------------------------
;### PRGKEY -> Check key
;### PRGINF -> show info-box
;### PRGEND -> quit application
;### PRGPAR -> Search for command line parameter (textfile)

;--- SUB-ROUTINES -------------------------------------------------------------
;### DIACNC -> Cancel dialogue
;### MSGGET -> check for message for application
;### CLCDEZ -> Converts byte into 2 decimal digits
;### CLCNUM -> Converts 16bit number into ASCII string (terminated by 0)
;### CLCR16 -> Converts string into 16bit number

;--- CONFIG-ROUTINES ----------------------------------------------------------
;### CFGGET -> Generates config path
;### CFGLOD -> Loads config
;### CFGINI -> Initialize config
;### CFGFNT -> Loads font
;### CFGSAV -> Save config
;### CFGOPN -> Open config-dialogue
;### CFGCOL -> Updates colour preview
;### CFGOKY -> Close config-dialogue and save config
;### CFGWRP -> Switch between "wrap at window border" and "no wrap"
;### CFGBAR -> Switches the status bar on/off

;--- FILE-ROUTINES ------------------------------------------------------------
;### FILMOD -> Ask for file-saving, if text has been modified
;### FILNEW -> New file
;### FILOPN -> Open file
;### FILSAS -> Save file as
;### FILSAV -> Save file
;### FILLOD -> load selected textfile
;### FILSTO -> save actual textfile
;### FILTIT -> Refreshes window title with filename

;--- EDIT-ROUTINES ------------------------------------------------------------
;### EDTCHG -> Editor changed
;### EDTCUT -> Edit Cut
;### EDTCOP -> Edit Copy
;### EDTPAS -> Edit Paste
;### EDTSAL -> Edit Select All
;### EDTDEL -> Edit Delete
;### EDTGOT -> Edit Goto
;### EDTTIM -> Edit Date/Time

;--- FIND- AND REPLACE-ROUTINES -----------------------------------------------
;### FNDFND -> Opens Find-Dialogue
;### FNDREP -> Opens Replace-Dialogue
;### FNDFOK -> Start Find
;### FNDROK -> Start Replace
;### FNDRDR -> Replace-Dialogue -> Replace
;### FNDRDA -> Replace-Dialogue -> Replace All
;### FNDRAL -> Start Replace all
;### FNDFNX -> Find next
;### FNDRPL -> Replaces text
;### FNDSEA -> Searches for text
;### FNDCAS -> Converts char into lcase, if case-flag is not set
;### FNDALN -> Checks, if word only + char is alphanumeric
;### FNDPLF -> Converts ^P into 13+10
;### FNDLFP -> Converts 13+10 into ^P
;### FNDGOT -> Goto

;--- DOCUMENT-ROUTINES --------------------------------------------------------
;### DOCINI -> initialise loaded document
;### DOCNEW -> clears and initialise document
;### DOCRFS -> refresh document display



;==============================================================================
;### CODE AREA ################################################################
;==============================================================================

;### PRGPRZ -> Application process
prgwin      db 0    ;main     window ID
diawin      db 0    ;dialogue window ID
windatsup   equ 51

prgprz  call prgpar
        call cfglod
        call cfgini
        call SySystem_HLPINI

        ld a,(prgbnknum)
        ld de,prgwindat
        call SyDesktop_WINOPN
        jp c,prgend             ;memory full -> quit process
        ld (prgwin),a           ;window has been opened -> store ID

        ld a,(prgparf)
        or a
        call nz,fillod
        call edtchg1

prgprz1 call msgget             ;*** check for messages
        jr c,prgprz2
        jr prgprz1
prgprz0 rst #30
        call msgget0
        jr c,prgprz2
        call edtchg0
        jr prgprz1
prgprz2 cp MSR_DSK_WCLICK       ;* window has been clicked?
        jr nz,prgprz0
        ld a,(diawin)
        cp (iy+1)
        ld a,(iy+2)
        jr nz,prgprz3
        cp DSK_ACT_CLOSE        ;* setup-close clicked
        jp z,diacnc
prgprz3 cp DSK_ACT_CLOSE        ;* main-close clicked
        jr z,prgend0
        cp DSK_ACT_MENU         ;* menu has been clicked
        jr z,prgprz4
        cp DSK_ACT_KEY          ;* key has been clicked
        jr z,prgkey
        cp DSK_ACT_CONTENT      ;* content clicked
        jr nz,prgprz0
prgprz4 ld l,(iy+8)
        ld h,(iy+9)
        ld a,l
        or h
        jr z,prgprz0
        ld a,(iy+3)             ;A=click type (0/1/2=mouse left/right/double, 7=keyboard)
        jp (hl)

;### PRGKEY -> Check key
prgkeya equ 8
prgkeyt db "N"-64:dw filnew ;CTRL+N = New
        db "O"-64:dw filopn ;CTRL+O = Open
        db "S"-64:dw filsav ;CTRL+S = Save
        db "F"-64:dw fndfnd ;CTRL+F = Find
        db 143:dw fndfnx    ;F3     = Find next
        db "R"-64:dw fndrep ;CTRL+R = Replace
        db "G"-64:dw edtgot ;CTRL+G = Goto
        db 145:dw edttim    ;F5     = Date/Time

prgkey  ld hl,prgkeyt
        ld b,prgkeya
        ld de,3
        ld a,(iy+4)
prgkey1 ld c,(hl)
        cp c
        jr z,prgkey2
        add hl,de
        djnz prgkey1
        jp prgprz0
prgkey2 inc hl
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld a,7
        jp (hl)

;### PRGHLP -> show help
prghlp  call SySystem_HLPOPN
        jp prgprz0

;### PRGINF -> show info-box
prginf  ld hl,prgtxtinf         ;*** info box
        ld b,1+128+64
prginf1 call prginf0
        jp prgprz0
prginf0 ld a,(prgbnknum)
        ld de,prgwindat
        jp SySystem_SYSWRN

;### PRGEND -> quit application
prgend0 call filmod
        jp c,prgprz0
prgend  ld hl,(prgcodbeg+prgpstnum)
        call SySystem_PRGEND
prgend1 rst #30                     ;wait for death
        jr prgend1

;### PRGPAR -> Search for command line parameter (textfile)
prgparf db 0                    ;flag, if command line parameter exists

prgpar  ld hl,(prgcodbeg)       ;search for command line parameter
        ld de,prgcodbeg
        dec h
        add hl,de               ;HL=code area end=path
        ld b,255
prgpar1 ld a,(hl)
        or a
        ret z
        cp 32
        jr z,prgpar2
        inc hl
        djnz prgpar1
        ret
prgpar2 ld (hl),0
        inc hl
        ld de,docpth
        ld bc,255
        ld a,c
        ld (prgparf),a
        ldir
prgpar3 ret


;==============================================================================
;### SUB-ROUTINES #############################################################
;==============================================================================

;### DIACNC -> Cancel dialogue
diacnc  ld a,(diawin)
        call SyDesktop_WINCLS
        jp prgprz0

;### MSGGET -> check for message for application
;### Output     CF=0 -> no message, CF=1 -> IXH=sender, (AppMsgB)=message, A=(AppMsgB+0), IY=AppMsgB
msgget  call msgget2            ;** sleep
        rst #08
        jr msgget1
msgget0 call msgget2            ;** no sleep
        rst #18                 ;get Message -> IXL=Status, IXH=sender ID
msgget1 or a
        db #dd:dec l
        ret nz
        ld iy,AppMsgB
        ld a,(iy+0)
        or a
        jp z,prgend
        scf
        ret
msgget2 ld a,(AppPrzN)
        db #dd:ld l,a           ;IXL=our own process ID
        db #dd:ld h,-1          ;IYL=sender ID (-1 = receive messages from any sender)
        ld iy,AppMsgB           ;IY=Messagebuffer
        ret

;### CLCDEZ -> Converts byte into 2 decimal digits
;### Input      A=Value
;### Output     L=10-digit, H=1-digit
;### Destroyed  AF
clcdez  ld l,0
clcdez1 sub 10
        jr c,clcdez2
        inc l
        jr clcdez1
clcdez2 add "0"+10
        ld h,a
        ld a,"0"
        add l
        ld l,a
        ret

;### CLCNUM -> Converts 16bit number into ASCII string (terminated by 0)
;### Input      IX=value, IY=address, E=max digits
;### Output     (IY)=last digit
;### Destroyed  AF,BC,DE,HL,IX,IY
clcnumt dw 1,10,100,1000,10000
clcnum  ld d,0
        ld b,e
        dec e
        push ix
        pop hl
        ld ix,clcnumt
        add ix,de
        add ix,de               ;IX=first divider
        dec b
        jr z,clcnum4
        ld c,0
clcnum1 ld e,(ix)
        ld d,(ix+1)
        dec ix
        dec ix
        ld a,"0"
        or a
clcnum2 sbc hl,de
        jr c,clcnum5
        inc c
        inc a
        jr clcnum2
clcnum5 add hl,de
        inc c
        dec c
        jr z,clcnum3
        ld (iy+0),a
        inc iy
clcnum3 djnz clcnum1
clcnum4 ld a,"0"
        add l
        ld (iy+0),a
        ld (iy+1),0
        ret

;### CLCR16 -> Converts string into 16bit number
;### Input      IX=string, A=terminator, BC=min (>=0), DE=max (<=65534)
;### Output     IX=string behind terminator, HL=number, CF=1 -> invalid (too big/small, wrong chars/terminator)
;### Destroyed  AF,DE,IYL
clcr16  ld hl,0
        db #fd:ld l,a
clcr161 ld a,(ix+0)
        inc ix
        db #fd:cp l
        jr z,clcr163
        sub "0"
        ret c
        cp 10
        ccf
        ret c
        push bc
        add hl,hl:jr c,clcr162
        ld c,l
        ld b,h
        add hl,hl:jr c,clcr162
        add hl,hl:jr c,clcr162
        add hl,bc:jr c,clcr162
        ld c,a
        ld b,0
        add hl,bc:ret c
        pop bc
        jr clcr161
clcr162 pop bc
        ret
clcr163 sbc hl,bc
        ret c
        add hl,bc
        inc de
        sbc hl,de
        ccf
        ret c
        add hl,de
        or a
        ret

SySystem_HLPFLG db 0    ;flag, if HLP-path is valid
SySystem_HLPPTH db "%help.exe "
SySystem_HLPPTH1 ds 128
SySHInX db ".HLP",0

SySystem_HLPINI
        ld hl,(prgcodbeg)
        ld de,prgcodbeg
        dec h
        add hl,de                   ;HL = CodeEnd = Command line
        ld de,SySystem_HLPPTH1
        ld bc,0
        db #dd:ld l,128
SySHIn1 ld a,(hl)
        or a
        jr z,SySHIn3
        cp " "
        jr z,SySHIn3
        cp "."
        jr nz,SySHIn2
        ld c,e
        ld b,d
SySHIn2 ld (de),a
        inc hl
        inc de
        db #dd:dec l
        ret z
        jr SySHIn1
SySHIn3 ld a,c
        or b
        ret z
        ld e,c
        ld d,b
        ld hl,SySHInX
        ld bc,5
        ldir
        ld a,1
        ld (SySystem_HLPFLG),a
        ret

SySystem_HLPOPN
        ld a,(SySystem_HLPFLG)
        or a
        ret z
        ld hl,SySystem_HLPPTH
        ld a,(prgbnknum)
        jp SySystem_PRGRUN


;==============================================================================
;### CONFIG-ROUTINES ##########################################################
;==============================================================================

cfgnam  db "notepad.dat",0
cfgnam0
cfgpth  dw 0

;### CFGGET -> Generates config path
cfgget  ld hl,(prgcodbeg)
        ld de,prgcodbeg
        dec h
        add hl,de           ;HL = CodeEnd = path
        ld (cfgpth),hl
        ld e,l
        ld d,h              ;DE=HL
        ld b,255
cfgget1 ld a,(hl)           ;search end of path
        or a
        jr z,cfgget2
        inc hl
        djnz cfgget1
        jr cfgget4
        ld a,255
        sub b
        jr z,cfgget4
        ld b,a
cfgget2 ld (hl),0
        dec hl              ;search start of filename
        call cfgget5
        jr z,cfgget3
        djnz cfgget2
        jr cfgget4
cfgget3 inc hl
        ex de,hl
cfgget4 ld hl,cfgnam        ;replace application filename with config filename
        ld bc,cfgnam0-cfgnam
        ldir
        ret
cfgget5 ld a,(hl)
        cp "/"
        ret z
        cp "\\"
        ret z
        cp ":"
        ret

;### CFGLOD -> Loads config
cfglod  call cfgget
        ld hl,(cfgpth)
        ld a,(prgbnknum)
        db #dd:ld h,a
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILOPN           ;open file
        ret c
        ld hl,cfgdat
        ld bc,16+128
        ld de,(prgbnknum)
        push af
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILINP           ;load configdata
        pop af
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILCLO           ;close file
        ret

;### CFGINI -> Initialize config
cfgini  ld hl,prgwinmen4+2
        ld de,cfgdatsta
        ld a,(de)
        add a
        res 1,(hl)
        or (hl)
        ld (hl),a
        and 2
        call cfgbar1
        jr nz,cfgini0
        ld de,10
        ld hl,(prgwindat+10)
        add hl,de
        ld (prgwindat+10),hl
cfgini0 ld hl,(cfgdatpap)
        ld a,h
        add a:add a:add a:add a
        add l
        ld (txtmulobj+texdatcol),a
        ld a,(cfgdattab)
        ld (txtmulobj+texdattab),a
        ld hl,txtmulobj+texdatfg2
        res 0,(hl)
        ld a,(cfgdatwrp)
        cp 1
        jr c,cfgini2
        set 0,(hl)
        ld hl,-1
        jr nz,cfgini1
        ld hl,(cfgdatwps)
cfgini1 ld (txtmulobj+texdatxmx),hl
cfgini2 ld a,(cfgfntnum)
        inc a
        ld (fntselobj),a
        dec a
        jr z,cfgfnt
        db #fd:ld l,a
        add a
        ld l,a
        ld h,0
        ld de,cfgfntdat
        add hl,de
        ld ix,fntsellst+4
        xor a
cfgini3 ld (ix+2),l
        ld (ix+3),h
        ld de,4
        add ix,de
        ld bc,-1
        cpir
        db #fd:dec l
        jr nz,cfgini3
        call cfgwrp0
        jr cfgfnt

;### CFGFNT -> Loads font
cfgfntl db -1   ;last loaded font
cfgfnt  ld hl,txtmulobj+texdatflg
        res 3,(hl)
        ld a,(cfgdatfnt)
        or a
        ret z
        ld hl,cfgfntl
        cp (hl)
        jr z,cfgfnt1
        push af
        ld hl,(cfgpth)
        ld a,(prgbnknum)
        db #dd:ld h,a
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILOPN           ;open file
        pop bc
        ret c
        push af
        ld c,a
        ld a,b
        add a
        ld l,a
        ld h,0
        ld de,cfgfntdat-2
        add hl,de
        ld a,(hl):db #dd:ld l,a
        inc hl
        ld a,(hl):db #dd:ld h,a
        ld a,c
        ld iy,0
        ld c,0
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILPOI           ;move to font data
        pop bc
        jr c,cfgfnt0
        ld a,b
        ld hl,txtbufmem
        ld bc,txtbufmax+1
        add hl,bc
        ld (txtmulobj+texdatfnt),hl
        ld bc,96*16+2
        ld de,(prgbnknum)
        push af
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILINP           ;load font
        pop bc
        jr c,cfgfnt0
        call cfgfnt1
        ld a,(cfgdatfnt)
        ld (cfgfntl),a
cfgfnt0 ld a,b
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILCLO           ;close file
        ret
cfgfnt1 ld hl,txtmulobj+texdatflg
        set 3,(hl)
        ret

;### CFGSAV -> Save config
cfgsav  ld hl,(cfgpth)      ;open config file
        ld a,(prgbnknum)
        db #dd:ld h,a
        xor a
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILOPN
        ret c
        ld de,(prgbnknum)   ;save config
        ld hl,cfgdat
        ld bc,16
        push af
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILOUT
        pop af              ;close config file
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILCLO
        ret

;### CFGOPN -> Open config-dialogue
cfgopn  ld a,(cfgdatwrp)
        ld (cfgwinwrp),a
        ld ix,(cfgdatwps)
        ld iy,cfgwinbuf1
        ld e,4
        call cfgopn1
        ld ix,(cfgdattab)
        db #dd:ld h,0
        ld iy,cfgwinbuf2
        ld e,2
        call cfgopn1
        ld bc,(fntselobj-1)
        ld hl,fntsellst+1
        ld de,4
cfgopn2 res 7,(hl)
        add hl,de
        djnz cfgopn2
        ld a,(cfgdatfnt)
        ld (fntselobj+12),a
        add a:add a
        ld l,a
        ld h,0
        ld de,fntsellst+1
        add hl,de
        set 7,(hl)
        ld a,(cfgdatpap)
        ld (papselobj+12),a
        ld c,a
        ld a,(cfgdatpen)
        ld (penselobj+12),a
        call cfgcol0
        ld de,cfgwindat
cfgopn0 ld a,(prgbnknum)
        call SyDesktop_WINOPN
        jp c,prgprz0            ;memory full -> ignore
        ld (diawin),a           ;window has been opened -> store ID
        inc a
        ld (prgwindat+windatsup),a
        jp prgprz0
cfgopn1 push iy
        call clcnum
        ex (sp),iy
        pop hl
        db #fd:ld e,l
        db #fd:ld d,h
        or a
        sbc hl,de
        inc l
        ld (iy-6),l
        ld (iy-10),l
        ret

;### CFGCOL -> Updates colour preview
cfgcol  call cfgcol0
        ld a,(diawin)
        ld e,8
        call SyDesktop_WINDIN
        jp prgprz0
cfgcol0 ld a,(penselobj+12)
        add a:add a:add a:add a
        ld hl,papselobj+12
        add (hl)
        ld (cfgwindsc8+2),a
        ret

;### CFGOKY -> Close config-dialogue and save config
cfgoky  ld a,(cfgwinwrp)
        ld (cfgdatwrp),a
        ld ix,cfgwinbuf1
        xor a
        ld bc,50
        ld de,9999
        call clcr16
        jr c,cfgoky1
        ld (cfgdatwps),hl
cfgoky1 ld ix,cfgwinbuf2
        xor a
        ld bc,1
        ld de,99
        call clcr16
        jr c,cfgoky1
        ld a,l
        ld (cfgdattab),a
cfgoky2 ld a,(fntselobj+12)
        ld (cfgdatfnt),a
        ld a,(papselobj+12)
        ld (cfgdatpap),a
        ld a,(penselobj+12)
        ld (cfgdatpen),a
        call cfgsav
        call cfgini
        call docrfs
        jp diacnc

;### CFGWRP -> Switch between "wrap at window border" and "no wrap"
cfgwrp  ld a,(cfgdatwrp)
        or a
        ld a,2
        jr z,cfgwrp2
        xor a
cfgwrp2 ld (cfgdatwrp),a
        call cfgwrp0
        call cfgini
        call docrfs
        jp prgprz0
cfgwrp0 ld a,(cfgdatwrp)
        or a
        ld a,3
        jr z,cfgwrp1
        ld a,1
cfgwrp1 ld (prgwinmen3+2),a
        ret

;### CFGBAR -> Switches the status bar on/off
cfgbar  ld hl,prgwinmen4+2
        ld de,cfgdatsta
        ld a,(hl)               ;modify menu
        xor 2
        ld (hl),a
        and 2
        rra
        ld (de),a
        call cfgbar1
        ld de,10
        jr z,cfgbar2
        call edtchg5
        ld de,-10
cfgbar2 ld hl,(prgwindat+10)
        add hl,de
        ld (prgwindat+10),hl
        ld a,(prgwindat)
        cp 2
        ld a,(prgwin)
        push af
        call z,SyDesktop_WINMAX
        pop af
        call nz,SyDesktop_WINMID
        jp prgprz0
cfgbar1 ld hl,prgwindat+1
        res 6,(hl)
        ret z
        set 6,(hl)
        ret


;==============================================================================
;### FILE-ROUTINES ############################################################
;==============================================================================

;### FILMOD -> Ask for file-saving, if text has been modified
;### Output     CF=0 ok, CF=1 cancel
filmod  ld a,(txtmulobj+texdatflg)
        rla
        ret nc
        ld hl,prgtxtsav
        ld b,8*4+3+64
        call prginf0
        cp 1
        ret c
        sub 4
        ret z
        ccf
        ret c
        jp filsav0

;### FILNEW -> New file
filnew  call filmod
        jp c,prgprz0
        call docnew
        call docrfs
        jp prgprz0

;### FILOPN -> Open file
filopn  call filmod
        jp c,prgprz0
        xor a
        call filopn0
        or a
        call z,fillod
        jp prgprz0
filopn0 ld hl,prgbnknum
        add (hl)
        ld hl,docmsk
        ld c,8
        ld ix,100
        ld iy,5000
        ld de,prgwindat
        jp SySystem_SELOPN

;### FILSAS -> Save file as
filsas  call filsav1
        call filtit
        jp prgprz0

;### FILSAV -> Save file
filsav  call filsav0
        jp prgprz0
;-> CF=1 cancel
filsav0 ld a,(docpth)
        or a
        jr nz,filsav2
filsav1 ld a,64
        call filopn0
        or a
        scf
        ret nz
filsav2 call filsto
        or a
        ret

;### FILLOD -> load selected textfile
fillode dw prgtxterr1,prgtxterr2,prgtxterr3,prgtxterr4

fillod  ld hl,docpth
        ld a,(prgbnknum)
        db #dd:ld h,a
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILOPN           ;open file
        ld e,2      ;2=error while loading file
        jr c,fillod5
        push af
        ld hl,txtbufmem
        ld bc,txtbufmax
        add hl,bc
        ld (hl),0
        sbc hl,bc
        ld de,(prgbnknum)
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILINP           ;load textdata
        pop de
        push bc
        push af
        ld a,d
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILCLO           ;close file
        pop af
        pop bc
        ld e,2      ;2=error while loading file
        jr c,fillod3
        ld hl,txtbufmem
        add hl,bc
        ld e,0      ;0=ok
        ld (hl),e
        jr nz,fillod1
        inc e       ;1=memory full (only the first part of the file has been loaded)
fillod1 push de         ;loading ok -> init text
        call docini
        call filtit
        jr fillod4
fillod3 push de         ;error while loading -> clear text
        call docnew
fillod4 call docrfs
        pop de
fillod5 inc e:dec e
        ret z
        ld l,e          ;show error message
        ld h,0
        add hl,hl
        ld bc,fillode-2
        add hl,bc
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld b,1+64
        call prginf0
        jp prgprz0

;### FILSTO -> save actual textfile
filsto  ld hl,txtmulobj+texdatflg   ;reset modified-bit
        res 7,(hl)
        ld hl,docpth
        ld a,(prgbnknum)
        db #dd:ld h,a
        xor a
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILNEW           ;create file
        ld e,3      ;3=error while writing file
        jr c,fillod5
        push af
        ld hl,txtbufmem
        ld bc,(txtmulobj+texdatlen)
        add hl,bc
        ld (hl),26
        push hl
        sbc hl,bc
        inc bc
        ld de,(prgbnknum)
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILOUT           ;save textdata
        pop hl
        ld (hl),0
        pop de
        push af
        ld a,d
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILCLO           ;close file
        pop af
        ld e,3      ;3=error while writing file
        jr c,fillod5
        inc e       ;4=device full (only part of the text has been saved)
        or a
        jr nz,fillod5
        ld e,a      ;0=ok
        jr fillod5

;### FILTIT -> Refreshes window title with filename
filtitt db " - Notepad",0

filtit  ld hl,docpth
        ld e,l:ld d,h
filtit1 call cfgget5
        inc hl
        jr nz,filtit2
        ld e,l:ld d,h
filtit2 or a
        jr nz,filtit1
        dec hl
        sbc hl,de
        ld a,l
        or a
        ret z
        cp 13
        jr c,filtit3
        ld a,12
filtit3 ld c,a
        ld b,0
        ex de,hl
        ld de,prgwintit
        ldir
        ld hl,filtitt
        ld bc,11
        ldir
        ld a,(prgwin)
        jp SyDesktop_WINTIT


;==============================================================================
;### EDIT-ROUTINES ############################################################
;==============================================================================

;### EDTCHG -> Editor changed
edtchgm db "Lin Col Siz Mrk "
edtchgf db 0    ;flag, if changed

edtchg  ld a,1                  ;** Set Change-Flag
        ld (edtchgf),a
        jp prgprz0

edtchg0 ld hl,edtchgf           ;** Update only on change
        bit 0,(hl)
        ld (hl),0
        ret z
edtchg1 ld a,(prgwindat+1)      ;** Update only on view
        bit 6,a
        ret z
        call edtchg5
        ld a,(prgwin)
        jp SyDesktop_WINSTA
edtchg5 ld a,29                 ;** Update content
        rst #20:dw jmp_keyput
        rst #30
        ld iy,prgwinsta
        ld hl,edtchgm
        ld ix,(txtmulobj+texdatmsg+2)
        inc ix
        call edtchg4
        ld ix,(txtmulobj+texdatmsg+0)
        inc ix
        call edtchg4
        ld ix,(txtmulobj+texdatlen)
        call edtchg4
        ld de,(txtmulobj+texdatmrk)
        ld a,e:or d
        jr z,edtchg3
        bit 7,d
        jr z,edtchg2
        ld a,e:cpl:ld e,a
        ld a,d:cpl:ld d,a
        inc de
edtchg2 push de:pop ix
        call edtchg4
edtchg3 ld (iy-2),0
        ret
edtchg4 push iy:pop de          ;add value
        ld bc,4
        add iy,bc
        ldir
        ld e,5
        push hl
        call clcnum
        pop hl
        inc iy:inc iy:inc iy
        ld (iy-2),","
        ld (iy-1)," "
        ret

;### EDTCUT -> Edit Cut
edtcut  ld a,"X"-64
edtcut0 rst #20:dw jmp_keyput
        jp prgprz0

;### EDTCOP -> Edit Copy
edtcop  ld a,"C"-64
        jr edtcut0

;### EDTPAS -> Edit Paste
edtpas  ld a,"V"-64
        jr edtcut0

;### EDTSAL -> Edit Select All
edtsal  ld a,"A"-64
        jr edtcut0

;### EDTDEL -> Edit Delete
edtdel  ld a,8
        jr edtcut0

;### EDTGOT -> Edit Goto
edtgot  ld hl,(gotdatoln+texdatlen)
        ld (gotdatoln+texdatmrk),hl
        ld hl,0
        ld (gotdatoln+texdatpos),hl
        ld a,3
        ld (gotwingrp+14),a
        ld de,gotwindat
        jp cfgopn0

;### EDTTIM -> Edit Date/Time
edttims db "00:00:00 00.00.0000",0
edttim  ld hl,(txtmulobj+texdatmrk)
        ld a,l:or h
        jr z,edttim1
        ld a,8
        rst #20:dw jmp_keyput
        rst #30
edttim1 ld hl,(txtmulobj+texdatlen)     ;increase length
        ld de,19
        add hl,de
        ex de,hl
        ld hl,(txtmulobj+texdatmax)
        sbc hl,de
        jp c,fndral3
        ld (txtmulobj+texdatlen),de
        ld hl,txtmulobj+texdatflg
        set 7,(hl)
        ld hl,(txtmulobj+texdatpos)     ;insert data
        push hl
        push de
        ex de,hl
        sbc hl,de
        ld c,l:ld b,h
        inc bc
        pop de
        ld hl,txtbufmem
        add hl,de
        ex de,hl
        ld hl,-19
        add hl,de
        lddr
        inc de
        push de
        rst #20:dw #810c                ;generate time/date string
        push hl
        push de
        push bc
        call clcdez:ld (edttims+6),hl
        pop bc:push bc
        ld a,c
        call clcdez:ld (edttims+0),hl
        pop af
        call clcdez:ld (edttims+3),hl
        pop de:push de
        ld a,e
        call clcdez:ld (edttims+12),hl
        pop af
        call clcdez:ld (edttims+9),hl
        pop ix
        ld iy,edttims+15
        ld e,4
        call clcnum
        pop de
        ld hl,edttims                   ;copy time/date string
        ld bc,19
        push bc
        ldir
        pop bc
        pop hl
        add hl,bc
        ld (txtmulobj+texdatmsg+0),hl   ;update display
        ld hl,0
        ld (txtmulobj+texdatmrk),hl
        ld a,30
        rst #20:dw jmp_keyput
        jp prgprz0


;==============================================================================
;### FIND- AND REPLACE-ROUTINES ###############################################
;==============================================================================

;### FNDFND -> Opens Find-Dialogue
fndfnd  call fndfnd1
        ld de,fndwindat
        jp cfgopn0
fndfnd1 ld bc,(txtmulobj+texdatmrk)
        ld a,c:or b
        jr z,fndfnd5
        ld hl,(txtmulobj+texdatpos)
        bit 7,b
        jr z,fndfnd2
        add hl,bc
        ld a,c:cpl:ld c,a
        ld a,b:cpl:ld b,a
        inc bc
fndfnd2 ld a,b
        or a
        jr nz,fndfnd3
        ld a,c
        cp 32+1
        jr c,fndfnd4
fndfnd3 ld bc,32
fndfnd4 ld (fnddatofn+texdatlen),bc
        ld de,txtbufmem
        add hl,de
        ld de,fnddattfn
        ldir
        xor a
        ld (de),a
fndfnd5 ld hl,(fnddatofn+texdatlen)
        ld (fnddatofn+texdatmrk),hl
        ld hl,0
        ld (fnddatofn+texdatpos),hl
        ld a,3
        ld (fndwingrp+14),a
        ld (repwingrp+14),a
        ld hl,fnddattfn
        jp fndlfp

;### FNDREP -> Opens Replace-Dialogue
fndrep  call fndfnd1
        ld hl,fnddattrp
        call fndlfp
        ld de,repwindat
        jp cfgopn0

;### FNDFOK -> Start Find
fndfok  ld a,(diawin)
        call SyDesktop_WINCLS
        jp fndfnx

;### FNDROK -> Start Replace
fndrok  call fndrok0
        ld hl,(txtmulobj+texdatpos)
        call fndsea
        jp c,fndfnx0
fndrok1 call fndfnx2
        rst #30
        ld de,rplwindat
        jp cfgopn0
fndrok0 ld a,(diawin)
        call SyDesktop_WINCLS
        ld hl,fnddattfn
        call fndplf
        ld hl,fnddattrp
        call fndplf
        rst #30         ;let the desktop-manager close the window first, before the text is modified
        ret

;### FNDRDR -> Replace-Dialogue -> Replace
fndrdr  call fndrok0
        ld hl,(txtmulobj+texdatpos)
        ld de,(txtmulobj+texdatmrk)
        add hl,de
        push hl
        call fndrpl
        pop de
        jr c,fndral3
        ld hl,(fnddatorp+texdatlen)
        add hl,de
        ld (txtmulobj+texdatmsg+0),hl
        push hl
        ld hl,0
        ld (txtmulobj+texdatmrk),hl
        ld a,30
        rst #20:dw jmp_keyput
        rst #30
        pop hl
        call fndsea
        jr nc,fndrok1
        jp prgprz0

;### FNDRDA -> Replace-Dialogue -> Replace All
fndrda  ld hl,(txtmulobj+texdatpos)
        ld de,(txtmulobj+texdatmrk)
        add hl,de
        ld (txtmulobj+texdatpos),hl
        ld hl,0
        ld (txtmulobj+texdatmrk),hl
        jr fndral

;### FNDRAL -> Start Replace all
fndral  call fndrok0
        ld bc,0
        ld a,(fnddatall)
        dec a
        ld l,a:ld h,a
        jr z,fndral1
fndral0 ld hl,(txtmulobj+texdatpos)
fndral1 push bc
        call fndsea
        jr c,fndral2
        push hl
        call fndrpl
        pop hl
        pop bc
        jr c,fndral3
        inc bc
        ld de,(fnddatorp+texdatlen)
        add hl,de
        jr fndral1
fndral2 pop bc
        ld a,c:or b
        jr z,fndfnx0
        push bc:pop ix
        ld e,5
        ld iy,fndmsgtxt2b
        call clcnum
        push iy:pop de
        inc de
        ld hl,fndmsgtxt2c
        ld bc,8
        ldir
        call docrfs
        ld hl,prgtxtrep
        ld b,8*2+1+64+128
        jp prginf1
fndral3 ld hl,prgtxtmem
        ld b,8*3+1+64
        jp prginf1

;### FNDFNX -> Find next
fndfnx  ld hl,fnddattfn
        call fndplf
        ld hl,(txtmulobj+texdatpos)
        call fndsea
        jr nc,fndfnx1
fndfnx0 ld hl,prgtxtfnd
        ld b,8*2+1+64
        jp prginf1
fndfnx1 call fndfnx2
        jp prgprz0
fndfnx2 ld de,(fnddatofn+texdatlen)
        add hl,de
        ld (txtmulobj+texdatmsg+0),hl
        ld a,e:cpl:ld e,a
        ld a,d:cpl:ld d,a
        inc de
        ld (txtmulobj+texdatmsg+2),de
        ld a,31
        rst #20:dw jmp_keyput
        ret

;### FNDRPL -> Replaces text
;### Input      HL=Offset, (fnddatofn+texdatlen)=old length, fnddattrp=new text, (fnddatorp+texdatlen)=new length
;### Output     CF=0 ok, CF=1 memory full
fndrplo dw 0    ;offset
fndrpl  push hl
        ex de,hl
        ld hl,(fnddatofn+texdatlen)
        ld bc,(fnddatorp+texdatlen)
        or a
        sbc hl,bc
        push hl
        ld c,l:ld b,h
        ld hl,(txtmulobj+texdatlen)
        or a
        sbc hl,bc       ;hl=new length
        push hl
        ld bc,txtbufmax
        scf
        sbc hl,bc
        ccf
        pop hl
        pop bc          ;bc=lendif
        ret c           ;new length >= max+1 -> memory full
        ld (txtmulobj+texdatlen),hl
        ld a,c:or b
        jr z,fndrpl2
        push bc
        push hl
        ld a,b
        sbc hl,de
        ld bc,(fnddatorp+texdatlen)
        sbc hl,bc
        ld c,l:ld b,h
        inc bc          ;bc=copylength (newlen-new wordlength-offset+1)
        pop hl          ;hl=newlen
        rla
        jr nc,fndrpl1
        ld de,txtbufmem ;expand text -> copy backwards
        add hl,de       ;hl=last char+1
        pop de          ;de=dif
        push hl
        add hl,de       ;hl=last char+dif = source
        pop de          ;de=last char = destination
        lddr
        jr fndrpl2
fndrpl1 ld hl,(fnddatorp+texdatlen)
        add hl,de
        ld de,txtbufmem
        add hl,de
        ex de,hl        ;de=offset + new wordlength=destination
        pop hl
        add hl,de       ;hl=destination + dif=source
        ldir
fndrpl2 pop de
        ld hl,txtbufmem
        add hl,de
        ex de,hl
        ld hl,fnddattrp
        ld bc,(fnddatorp+texdatlen)
        ldir
        ld hl,txtmulobj+texdatflg
        set 7,(hl)      ;modified
        or a
        ret

;### FNDSEA -> Searches for text
;### Input      HL=Startoffset, fnddattfn=Text, (fnddatofn+texdatlen)=length, (fnddatcas)=Flag, if case sensitive
;### Output     CF=0 ok (HL=offset), CF=1 nothing found
fndsea  ld de,(fnddatofn+texdatlen)
        ld a,e:or d
        scf
        ret z
        push hl
        add hl,de
        ex de,hl
        ld hl,(txtmulobj+texdatlen)
        scf
        sbc hl,de
        ld c,l:ld b,h
        pop hl
        ret c
        inc bc              ;bc=len
        ld de,txtbufmem
        add hl,de           ;hl=adr
        ld a,(fnddattfn)
        call fndcas
        ld e,a
fndsea1 ld a,(hl)       ;search for 1st char
        call fndcas
        cp e
        jr z,fndsea3
fndsea2 inc hl          ;next char
        dec bc
        ld a,c:or b
        jr nz,fndsea1
        scf
        ret
fndsea3 dec hl          ;1st char found
        ld a,(hl)
        inc hl
        call fndaln
        jr c,fndsea2
        push bc
        push de
        push hl
        ld bc,(fnddatofn+texdatlen)
        ld de,fnddattfn
fndsea4 inc hl          ;check remaining chars
        dec c
        jr z,fndsea6
        inc de
        ld a,(de)
        call fndcas
        ld b,a
        ld a,(hl)
        call fndcas
        cp b
        jr z,fndsea4
fndsea5 pop hl          ;not found, next char
        pop de
        pop bc
        jr fndsea2
fndsea6 ld a,(hl)       ;complete string found
        call fndaln
        jr c,fndsea5
        pop hl
        pop de
        pop bc
        ld de,txtbufmem
        or a
        sbc hl,de
        ret

;### FNDCAS -> Converts char into lcase, if case-flag is not set
;### Input      A=Char
;### Output     A=Char
;### Destroyed  F
fndcas  push hl
        ld hl,fnddatcas
        bit 0,(hl)
        pop hl
        ret nz
        cp "A"
        ret c
        cp "Z"+1
        ret nc
        add "a"-"A"
        ret

;### FNDALN -> Checks, if word only + char is alphanumeric
;### Input      A=Char
;### Output     CF=1 word only + char is alphanumeric
;### Destroyed  F
fndaln  or a
        push hl
        ld hl,fnddatwrd
        bit 0,(hl)
        pop hl
        ret z
        cp "_"
        scf
        ret z
        cp "0"
        ccf
        ret nc
        cp "9"+1
        ret c
        cp "A"
        ccf
        ret nc
        cp "Z"+1
        ret c
        cp "a"
        ccf
        ret nc
        cp "z"+1
        ret

;### FNDPLF -> Converts ^P into 13+10
;### Input      HL=String
;### Destroyed  AF,BC,DE,HL
fndplf  ld bc,13*256+10
        ld de,"^"*256+"P"
        jr fndlfp0

;### FNDLFP -> Converts 13+10 into ^P
;### Input      HL=String
;### Destroyed  AF,BC,DE,HL
fndlfp  ld de,13*256+10
        ld bc,"^"*256+"P"
fndlfp0 ld a,(hl)
fndlfp1 or a
        ret z
        inc hl
        cp d
        jr nz,fndlfp0
        ld a,(hl)
        cp e
        jr nz,fndlfp1
        dec hl
        ld (hl),b
        inc hl
        ld (hl),c
        inc hl
        jr fndlfp0

;### FNDGOT -> Goto
fndgot  ld a,(diawin)           ;close dialogue
        call SyDesktop_WINCLS
        ld ix,gotdattln         ;convert line
        xor a
        ld bc,1
        ld de,9999
        call clcr16
        jr nc,fndgot2
fndgot1 ld hl,prgtxtnum
        ld b,8*3+1+64
        jp prginf1
fndgot2 push hl
        ld ix,gotdattcl         ;convert column
        xor a
        ld bc,1
        ld de,16383
        call clcr16
        pop bc
        jr c,fndgot1
        push hl                 ;limit max-line
        ld hl,(txtmulobj+texdatlnt)
        sbc hl,bc
        jr nc,fndgot3
        add hl,bc
        ld c,l:ld b,h
fndgot3 ld ix,txtmulobj+texdatlln
        ld hl,0                 ;goto line
fndgot4 dec bc
        ld a,c:or b
        jr z,fndgot5
        ld e,(ix+0)
        ld d,(ix+1)
        res 7,d
        add hl,de
        inc ix
        inc ix
        jr fndgot4
fndgot5 ex de,hl
        pop hl                  ;limit max-column
        ld c,(ix+0)
        ld b,(ix+1)
        inc bc
        bit 7,b
        res 7,b
        jr z,fndgot6
        dec bc:dec bc
fndgot6 sbc hl,bc
        jr nc,fndgot7
        add hl,bc
        ld c,l:ld b,h
fndgot7 dec bc
        ex de,hl
        add hl,bc
        ld (txtmulobj+texdatmsg+0),hl
        ld hl,0
        ld (txtmulobj+texdatmsg+2),hl
        ld a,31
        rst #20:dw jmp_keyput   ;set cursor
        jp prgprz0


;==============================================================================
;### DOCUMENT-ROUTINES ########################################################
;==============================================================================

texdatadr       equ 0           ;Zeiger auf Text
texdatbeg       equ 2           ;erstes angezeigtes Zeichen (nur singleline)
texdatpos       equ 4           ;Cursorposition im Gesamttext
texdatmrk       equ 6           ;0/Anzahl markierter Zeichen [neg->Cursor=Ende Markierung]
texdatlen       equ 8           ;Textlänge
texdatmax       equ 10          ;maximal zulässige Textlänge (1-16383; exklusive 0-Terminator)
texdatflg       equ 12          ;Flags (Bit0=Paßwort [nur singleline], Bit1=ReadOnly, Bit2=AltColor, Bit3=AltFont [nur multiline])
;** extended 16c/altfont
texdatcol       equ 13          ;4bit txtpap, 4bit txtpen
texdatrhm       equ 14          ;4bit rahmen1, 4bit rahmen2
texdatfnt       equ 15          ;Adresse des alternativen Fonts
texdatrs1       equ 17          ;*reserved 1byte*
;** ab hier nur Multiline
texdatlnt       equ 18          ;aktuelle Anzahl Zeilen
texdatxmx       equ 20          ;maximale Zeilenbreite in Pixeln bei Wordwrap-Pos-Vorgabe (-1=unbegrenzt)
texdatymx       equ 22          ;maximale Anzahl Zeilen (*2 bytes ab texdatlln!)
texdatxwn       equ 24          ;win x len ohne slider für bisherige formatierung (winx<>aktx -> Neuformatierung notwendig, durch -8 erzwingen)
texdatywn       equ 26          ;win y len ohne slider

texdatzgr       equ 28          ;pointer auf diesen datensatz (ab texdatadr)
texdatxfl       equ 30          ;full x len (=Länge der längsten Textzeile in Pixel)
texdatyfl       equ 32          ;full y len (=Anzahl aller Textzeilen * 8)
texdatxof       equ 34          ;offset x   (=texdatbeg)
texdatyof       equ 36          ;offset y
texdatfg2       equ 38          ;Flags (Bit0=WordWrap-Position vorgegeben [dann Xslider], Bit1=1)
texdattab       equ 39          ;Tabstop Größe (1-255; 0=kein Tabstop) ##!!##

texdatmsg       equ 40          ;Message-Buffer (in POS, MRK, out CXP, CYP)
texdatrs2       equ 44          ;*reserved 4byte*
texdatlln       equ 48          ;Zeilen-Längentabelle (bit15=cr+lf am ende vorhanden)

;### DOCINI -> initialise loaded document
docini  ld hl,txtmulobj+texdatflg   ;reset modified-bit
        res 7,(hl)
        ld hl,txtbufmem             ;search for EOF (0 or 26 [CPC])
        ld bc,txtbufmax
        push hl
        xor a                       ;search for 0
        cpir
        ex (sp),hl
        ld bc,txtbufmax
        ld a,26                     ;search for 26 (EOF)
        cpir
        pop de
        or a
        sbc hl,de
        jr nc,docini1
        add hl,de
        ex de,hl
docini1 ex de,hl
        dec hl
        xor a
        ld (hl),a
        ld bc,txtbufmem
        sbc hl,bc                   ;hl=textlength (=min(found(0),found(26))
        ld (txtmulobj+texdatlen),hl
docini2 ld a,l
        or h
        jr z,docnew1
        ld a,(bc)
        cp 10
        jr z,docini4
        cp 13
        jr z,docini4
        cp 32
        jr c,docini3
        cp 128
        jr c,docini4
docini3 ld a,"?"
        ld (bc),a
docini4 inc bc
        dec hl
        jr docini2

;### DOCNEW -> clears and initialise document
docnew  ld hl,txtmulobj+texdatflg   ;reset modified-bit
        res 7,(hl)
        xor a
        ld (txtbufmem),a
        ld l,a:ld h,a
        ld (txtmulobj+texdatlen),hl
docnew1 ld (txtmulobj+texdatpos),hl
        ld (txtmulobj+texdatmrk),hl
        ld (txtmulobj+texdatxof),hl
        ld (txtmulobj+texdatyof),hl
        ret

;### DOCRFS -> refresh document display
docrfs  call edtchg1
        ld hl,-8
        ld (txtmulobj+texdatxwn),hl
        ld a,(prgwin)
        ld e,1
        jp SyDesktop_WINDIN


;==============================================================================
;### DATA AREA ################################################################
;==============================================================================

prgdatbeg

txtbufmem db 0
;!!!last label in data-area!!!

;==============================================================================
;### TRANSFER AREA ############################################################
;==============================================================================

prgtrnbeg
;### PRGPRZS -> Stack for application process
        ds 128
prgstk  ds 6*2
        dw prgprz
AppPrzN db 0
AppMsgB ds 14

prgicn16c db 12,24,24:dw $+7:dw $+4,12*24:db 5
        db #88,#88,#88,#88,#DD,#8D,#D8,#DD,#8D,#D8,#DD,#88,#88,#88,#88,#8D,#8D,#D8,#DD,#8D,#D8,#DD,#8D,#D8,#88,#88,#88,#54,#D4,#4D,#44,#D4,#4D,#44,#D4,#77,#88,#88,#88,#54,#44,#44,#44,#44,#44,#44,#44,#77
        db #88,#88,#85,#44,#44,#44,#44,#44,#44,#44,#45,#17,#88,#88,#85,#44,#44,#44,#44,#44,#44,#44,#45,#17,#88,#88,#54,#44,#FF,#FF,#FF,#FF,#F4,#44,#50,#17,#88,#88,#54,#44,#44,#44,#44,#44,#44,#44,#51,#17
        db #88,#85,#44,#45,#55,#55,#55,#55,#44,#45,#00,#17,#88,#85,#44,#44,#44,#44,#44,#44,#44,#45,#00,#17,#88,#54,#44,#55,#55,#55,#55,#54,#44,#51,#11,#17,#88,#54,#44,#44,#44,#44,#44,#44,#44,#50,#06,#17
        db #85,#44,#44,#44,#44,#44,#44,#44,#45,#00,#06,#17,#85,#44,#44,#44,#44,#44,#44,#44,#45,#11,#11,#17,#54,#44,#44,#44,#44,#44,#44,#44,#50,#00,#66,#17,#54,#44,#44,#44,#44,#44,#44,#44,#50,#00,#66,#17
        db #85,#55,#55,#55,#55,#55,#55,#55,#11,#11,#11,#17,#88,#88,#88,#70,#00,#00,#00,#00,#00,#06,#66,#17,#88,#88,#88,#70,#00,#00,#00,#00,#00,#06,#66,#17,#88,#88,#88,#71,#11,#11,#11,#11,#11,#11,#11,#17
        db #88,#88,#88,#70,#00,#00,#00,#00,#00,#66,#66,#17,#88,#88,#88,#76,#66,#66,#66,#66,#66,#66,#61,#17,#88,#88,#88,#87,#11,#11,#11,#11,#11,#11,#11,#78,#88,#88,#88,#88,#77,#77,#77,#77,#77,#77,#77,#88

docmsk  db "TXT",0
docpth  ds 256

;### STRINGS ##################################################################

prgwintit   db "untitled - Notepad",0:ds 12-8
prgwinsta   ds 4*11

prgtxtinf1  db "Notepad for SymbOS",0
prgtxtinf2  db " Version 1.2 (Build 141019pdt)",0
prgtxtinf3  db " Copyright <c> 2014 SymbiosiS"
prgtxtinf0  db 0

prgtxterra  db "Textbuffer full. Only a part of",0
prgtxterrb  db "the document has been loaded.",0
prgtxterrc  db "Error while loading file!",0
prgtxterrd  db "Error while saving file!",0
prgtxterre  db "Device full. Only a part of",0
prgtxterrf  db "the document has been saved.",0

prgtxtsav1  db "Save changes?",0

prgtxtoky   db "Ok",0
prgtxtcnc   db "Cancel",0
prgtxtfnx   db "Find next",0
prgtxtfrp   db "Replace",0
prgtxtfra   db "Replace all",0

;### FIND AND REPLACE #########################################################

fndwintit   db "Find",0
repwintit   db "Replace",0
gotwintit   db "Go to",0

fndwintxt1  db "Find what",0
fndwintxt2  db "Replace with",0
fndwintxt3  db "Match case",0
fndwintxt4  db "Whole word only",0
fndwintxt5  db "Entire document",0
fndwintxt6  db "Line",0
fndwintxt7  db "Column",0

fnddattfn   ds 33
fnddattrp   ds 33
gotdattln   db "1":ds 4
gotdattcl   db "1":ds 5

fndmsgtxt1  db "Text not found!",0
fndmsgtxt2a db "Replaced "
fndmsgtxt2b ds 8+5
fndmsgtxt2c db " times.",0
fndmsgtxt3a db "Textbuffer full. Couldn't",0
fndmsgtxt3b db "replace one or more entries.",0
fndmsgtxt4  db "Invalid number",0

;### CONFIG ###################################################################

fnttxtdef   db "Default",0

coltxt00    db "00",0
coltxt01    db "01",0
coltxt02    db "02",0
coltxt03    db "03",0
coltxt04    db "04",0
coltxt05    db "05",0
coltxt06    db "06",0
coltxt07    db "07",0
coltxt08    db "08",0
coltxt09    db "09",0
coltxt10    db "10",0
coltxt11    db "11",0
coltxt12    db "12",0
coltxt13    db "13",0
coltxt14    db "14",0
coltxt15    db "15",0

cfgwintit   db "Settings",0
cfgwintxt0  db "Font type",0
cfgwintxt1  db "Font colour",0
cfgwintxt2  db "Options",0
cfgwintxt3  db "Word wrap at window border",0
cfgwintxt4  db "Word wrap at",0
cfgwintxt5  db "px",0
cfgwintxt6  db "No word wrap",0
cfgwintxt7  db "Tabstop width",0
cfgwintxt8  db "chars",0
cfgwintxt9  db "Pen",0
cfgwintxta  db "Paper",0
cfgwintxtb  db "Preview",0

;### MENU #####################################################################

prgwinmentx1 db "File",0
prgwinmen1tx1 db "New",0
prgwinmen1tx2 db "Open...",0
prgwinmen1tx3 db "Save",0
prgwinmen1tx4 db "Save As...",0
prgwinmen1tx5 db "Exit",0

prgwinmentx2 db "Edit",0
prgwinmen2tx1 db "Cut",0
prgwinmen2tx2 db "Copy",0
prgwinmen2tx3 db "Paste",0
prgwinmen2tx4 db "Delete",0
prgwinmen2tx5 db "Find...",0
prgwinmen2tx6 db "Find Again",0
prgwinmen2tx7 db "Replace...",0
prgwinmen2tx8 db "Go To...",0
prgwinmen2tx9 db "Select All",0
prgwinmen2txa db "Time/Date",0

prgwinmentx3 db "Format",0
prgwinmen3tx1 db "Auto word wrap",0
prgwinmen3tx2 db "Settings...",0

prgwinmentx4 db "View",0
prgwinmen4tx1 db "Status bar",0

prgwinmentx5 db "?",0
prgwinmen5tx1 db "Index",0
prgwinmen5tx2 db "About Notepad...",0

;### ALERT BOXES ##############################################################

prgtxtinf  dw prgtxtinf1,4*1+2,prgtxtinf2,4*1+2,prgtxtinf3,4*1+2,prgicnbig

prgtxterr1  dw prgtxterra,4*1+2,prgtxterrb,4*1+2,prgtxtinf0,4*1+2
prgtxterr2  dw prgtxterrc,4*1+2,prgtxtinf0,4*1+2,prgtxtinf0,4*1+2
prgtxterr3  dw prgtxterrd,4*1+2,prgtxtinf0,4*1+2,prgtxtinf0,4*1+2
prgtxterr4  dw prgtxterre,4*1+2,prgtxterrf,4*1+2,prgtxtinf0,4*1+2

prgtxtsav   dw prgtxtsav1,4*1+2,prgtxtinf0,4*1+2,prgtxtinf0,4*1+2

prgtxtfnd   dw fndmsgtxt1,4*1+2,prgtxtinf0,4*1+2,prgtxtinf0,4*1+2
prgtxtrep   dw fndmsgtxt2a,4*1+2,prgtxtinf0,4*1+2,prgtxtinf0,4*1+2,prgicnbig
prgtxtmem   dw fndmsgtxt3a,4*1+2,fndmsgtxt3b,4*1+2,prgtxtinf0,4*1+2
prgtxtnum   dw fndmsgtxt4,4*1+2,prgtxtinf0,4*1+2,prgtxtinf0,4*1+2

;### CONFIG WINDOW ############################################################

cfgwindat   dw #1401,4+16,079,024,160,138,0,0,160,138,160,138,160,138,0,cfgwintit,0,0,cfgwingrp,0,0:ds 136+14
cfgwingrp   db 20,0:dw cfgwinobj,0,0,256*20+19,0,0,0
cfgwinobj
            dw     00,         0,2,          0,0,1000,1000,0        ;00=Hintergrund
            dw     00,255*256+ 3,cfgwindsc0, 00, 01, 80,59,0        ;01=Frame       "Font type"
            dw     00,255*256+41,fntselobj,  08, 10, 64,42,0        ;02=Font-List
            dw     00,255*256+ 3,cfgwindsc1, 80, 01, 80,59,0        ;03=Frame       "Font colour"
            dw     00,255*256+ 1,cfgwindsc6, 88, 12, 32, 8,0        ;04=Description "Pen"
            dw cfgcol,255*256+42,penselobj, 120, 11, 32,10,0        ;05=Pen-List
            dw     00,255*256+ 1,cfgwindsc7, 88, 24, 32, 8,0        ;06=Description "Paper"
            dw cfgcol,255*256+42,papselobj, 120, 23, 32,10,0        ;07=Paper-List
            dw     00,255*256+ 1,cfgwindsc8, 92, 40, 56, 8,0        ;08=Description "Preview"
            dw     00,255*256+ 3,cfgwindsc2, 00, 60,160,63,0        ;09=Frame       "Options"
            dw     00,255*256+18,cfgwinrad0, 08, 70,120, 8,0        ;10=Radiobox    "Word wrap at window border"
            dw     00,255*256+18,cfgwinrad1, 08, 81, 64, 8,0        ;11=Radiobox    "Word wrap at"
            dw     00,255*256+32,cfgwininp1, 73, 79, 26,12,0        ;12=Input       "Word wrap at"
            dw     00,255*256+ 1,cfgwindsc4,101, 81, 32, 8,0        ;13=Description "px"
            dw     00,255*256+18,cfgwinrad2, 08, 92, 64, 8,0        ;14=Radiobox    "No word wrap"
            dw     00,255*256+ 1,cfgwindsc3, 08,106, 32, 8,0        ;15=Description "Tab stop width"
            dw     00,255*256+32,cfgwininp2, 68,104, 16,12,0        ;16=Input       "Tab stop width"
            dw     00,255*256+ 1,cfgwindsc5, 86,106, 32, 8,0        ;17=Description "chars"
            dw cfgoky,255*256+16,prgtxtoky,  59,123, 48,12,0        ;18="Ok"    -Button
            dw diacnc,255*256+16,prgtxtcnc, 109,123, 48,12,0        ;19="Cancel"-Button


fntselobj   dw 8,0,fntsellst,0,1,fntselrow,0,1
fntselrow   dw 0,56,0,0
fntsellst   dw 00,fnttxtdef
            dw 01,fnttxtdef, 02,fnttxtdef, 03,fnttxtdef, 04,fnttxtdef, 05,fnttxtdef, 06,fnttxtdef, 07,fnttxtdef, 08,fnttxtdef
            dw 09,fnttxtdef, 10,fnttxtdef, 11,fnttxtdef, 12,fnttxtdef, 13,fnttxtdef, 14,fnttxtdef, 15,fnttxtdef, 16,fnttxtdef

penselobj   dw 16,0,pensellst,0,1,penselrow,0,1
penselrow   dw 0,56,0,0
pensellst   dw 00,coltxt00, 01,coltxt01, 02,coltxt02, 03,coltxt03, 04,coltxt04, 05,coltxt05, 06,coltxt06, 07,coltxt07
            dw 08,coltxt08, 09,coltxt09, 10,coltxt10, 11,coltxt11, 12,coltxt12, 13,coltxt13, 14,coltxt14, 15,coltxt15

papselobj   dw 16,0,papsellst,0,1,papselrow,0,1
papselrow   dw 0,56,0,0
papsellst   dw 00,coltxt00, 01,coltxt01, 02,coltxt02, 03,coltxt03, 04,coltxt04, 05,coltxt05, 06,coltxt06, 07,coltxt07
            dw 08,coltxt08, 09,coltxt09, 10,coltxt10, 11,coltxt11, 12,coltxt12, 13,coltxt13, 14,coltxt14, 15,coltxt15

cfgwindsc0  dw cfgwintxt0,2+4
cfgwindsc1  dw cfgwintxt1,2+4
cfgwindsc2  dw cfgwintxt2,2+4
cfgwindsc3  dw cfgwintxt7,2+4
cfgwindsc4  dw cfgwintxt5,2+4
cfgwindsc5  dw cfgwintxt8,2+4
cfgwindsc6  dw cfgwintxt9,2+4
cfgwindsc7  dw cfgwintxta,2+4
cfgwindsc8  dw cfgwintxtb,256*194+16

cfgwininp1  dw cfgwinbuf1,0,0,0,0,4,0
cfgwinbuf1  ds 5
cfgwininp2  dw cfgwinbuf2,0,0,0,0,2,0
cfgwinbuf2  ds 3

cfgwinwrp   db 0
cfgwinradb  dw -1,-1
cfgwinrad0  dw cfgwinwrp,cfgwintxt3,256*0+2+4,cfgwinradb
cfgwinrad1  dw cfgwinwrp,cfgwintxt4,256*1+2+4,cfgwinradb
cfgwinrad2  dw cfgwinwrp,cfgwintxt6,256*2+2+4,cfgwinradb

cfgdat
cfgdatpap   db 0    ;paper
cfgdatpen   db 1    ;pen
cfgdatfnt   db 0    ;font 
cfgdatwrp   db 0    ;0=autowordwrap, 1=wordwrap at position x, 2=no wordwrap
cfgdatwps   dw 200  ;wordwrap-position (pixels)
cfgdattab   db 8    ;tabstop-position (chars)
cfgdatsta   db 1    ;flag, if statusbar
            ds 16-8

cfgfntnum   db 0    ;number of fonts
cfgfntdat   ds 127  ;font information (offset table, names)

;### GOTO #####################################################################

gotwindat   dw #1401,4+16,090,060,120,34,0,0,120,34,120,34,120,34,0,gotwintit,0,0,gotwingrp,0,0:ds 136+14
gotwingrp   db 07,0:dw gotwinobj,0,0,256*07+06,0,0,3
gotwinobj
            dw     00,         0,2,          0,0,1000,1000,0        ;00=Hintergrund
            dw     00,255*256+ 1,gotwindsc1, 04, 06, 34, 8,0        ;01=Description "Line"
            dw     00,255*256+32,gotdatoln,  38, 04, 32,12,0        ;02=Input       "Line"
            dw     00,255*256+ 1,gotwindsc2, 04, 20, 34, 8,0        ;03=Description "Column"
            dw     00,255*256+32,gotdatocl,  38, 18, 32,12,0        ;04=Input       "Column"
            dw fndgot,255*256+16,prgtxtoky,  76, 04, 40,12,0        ;05="Ok"        -Button
            dw diacnc,255*256+16,prgtxtcnc,  76, 18, 40,12,0        ;06="Cancel"    -Button

gotwindsc1  dw fndwintxt6,2+4
gotwindsc2  dw fndwintxt7,2+4
gotdatoln   dw gotdattln,0,1,0,1,4,0
gotdatocl   dw gotdattcl,0,1,0,1,5,0

;### FIND AND REPLACE #########################################################

fndwindat   dw #1401,4+16,060,060,240,46,0,0,240,46,240,46,240,46,0,fndwintit,0,0,fndwingrp,0,0:ds 136+14
fndwingrp   db 07,0:dw fndwinobj,0,0,256*07+06,0,0,3
fndwinobj
            dw     00,         0,2,          0,0,1000,1000,0        ;00=Hintergrund
            dw     00,255*256+ 1,fndwindsc1, 04, 06, 40, 8,0        ;01=Description "Find what"
            dw     00,255*256+32,fnddatofn,  60, 04,114,12,0        ;02=Input       "Find what"
            dw     00,255*256+17,fndwinchk1, 04, 24, 80, 8,0        ;03=Checkbox    "Match case"
            dw     00,255*256+17,fndwinchk2, 04, 34, 80, 8,0        ;04=Checkbox    "Whole word only"
            dw fndfok,255*256+16,prgtxtfnx, 182, 04, 54,12,0        ;05="Find next" -Button
            dw diacnc,255*256+16,prgtxtcnc, 182, 20, 54,12,0        ;06="Cancel"    -Button

repwindat   dw #1401,4+16,060,060,240,70,0,0,240,70,240,70,240,70,0,repwintit,0,0,repwingrp,0,0:ds 136+14
repwingrp   db 11,0:dw repwinobj,0,0,256*11+09,0,0,3
repwinobj
            dw     00,         0,2,          0,0,1000,1000,0        ;00=Hintergrund
            dw     00,255*256+ 1,fndwindsc1, 04, 06, 40, 8,0        ;01=Description  "Find what"
            dw     00,255*256+32,fnddatofn,  60, 04,114,12,0        ;02=Input        "Find what"
            dw     00,255*256+ 1,fndwindsc2, 04, 20, 40, 8,0        ;03=Description  "Replace with"
            dw     00,255*256+32,fnddatorp,  60, 18,114,12,0        ;04=Input        "Replace with"
            dw     00,255*256+17,fndwinchk1, 04, 38, 80, 8,0        ;05=Checkbox     "Match case"
            dw     00,255*256+17,fndwinchk2, 04, 48, 80, 8,0        ;06=Checkbox     "Whole word only"
            dw     00,255*256+17,fndwinchk3, 04, 58, 80, 8,0        ;07=Checkbox     "Entire document"
            dw fndrok,255*256+16,prgtxtfnx, 182, 04, 54,12,0        ;08="Find next"  -Button
            dw fndral,255*256+16,prgtxtfra, 182, 20, 54,12,0        ;09="Replace all"-Button
            dw diacnc,255*256+16,prgtxtcnc, 182, 36, 54,12,0        ;10="Cancel"     -Button

rplwindat   dw #1401,4+16,060,060,226,24,0,0,226,24,226,24,226,24,0,repwintit,0,0,rplwingrp,0,0:ds 136+14
rplwingrp   db 5,0:dw rplwinobj,0,0,256*5+3,0,0,2
rplwinobj
            dw     00,         0,2,          0,0,1000,1000,0        ;00=Hintergrund
            dw fndrok,255*256+16,prgtxtfnx,   2, 6, 54,12,0         ;01="Find next"  -Button
            dw fndrdr,255*256+16,prgtxtfrp,  58, 6, 54,12,0         ;02="Replace"    -Button
            dw fndrda,255*256+16,prgtxtfra, 114, 6, 54,12,0         ;03="Replace all"-Button
            dw diacnc,255*256+16,prgtxtcnc, 170, 6, 54,12,0         ;04="Cancel"     -Button

fndwindsc1  dw fndwintxt1,2+4
fndwindsc2  dw fndwintxt2,2+4

fndwinchk1  dw fnddatcas,fndwintxt3,2+4
fndwinchk2  dw fnddatwrd,fndwintxt4,2+4
fndwinchk3  dw fnddatall,fndwintxt5,2+4

fnddatofn   dw fnddattfn,0,0,0,0,32,0
fnddatorp   dw fnddattrp,0,0,0,0,32,0
fnddatcas   db 0    ;flag, if case-sensitive
fnddatwrd   db 0    ;flag, if whole word only
fnddatall   db 0    ;flag, if entire document

;### MAIN WINDOW ##############################################################

prgwindat   dw #7701,3,50,20,200,106,0,0,200,106,100,50,1000,1000,prgicnsml,prgwintit
prgwindat0  dw prgwinsta,prgwinmen,prgwingrp,0,0:ds 136+14

prgwinmen  dw  5, 1+4,prgwinmentx1,prgwinmen1,0, 1+4,prgwinmentx2,prgwinmen2,0, 1+4,prgwinmentx3,prgwinmen3,0, 1+4,prgwinmentx4,prgwinmen4,0, 1+4,prgwinmentx5,prgwinmen5,0
prgwinmen1 dw  6, 1,prgwinmen1tx1,filnew,0, 1,prgwinmen1tx2,filopn,0, 1,prgwinmen1tx3,filsav,0, 1,prgwinmen1tx4,filsas,0, 1+8,0,0,0, 1,prgwinmen1tx5,prgend0,0
prgwinmen2 dw 12, 1,prgwinmen2tx1,edtcut,0, 1,prgwinmen2tx2,edtcop,0, 1,prgwinmen2tx3,edtpas,0, 1,prgwinmen2tx4,edtdel,0, 1+8,0,0,0,                1,prgwinmen2tx5,fndfnd,0
           dw     1,prgwinmen2tx6,fndfnx,0, 1,prgwinmen2tx7,fndrep,0, 1,prgwinmen2tx8,edtgot,0, 1+8,0,0,0,                1,prgwinmen2tx9,edtsal,0, 1,prgwinmen2txa,edttim,0
prgwinmen3 dw  2, 1,prgwinmen3tx1,cfgwrp,0, 1,prgwinmen3tx2,cfgopn,0
prgwinmen4 dw  1, 1,prgwinmen4tx1,cfgbar,0
prgwinmen5 dw  3, 1,prgwinmen5tx1,prghlp,0, 1+8,0,0,0, 1,prgwinmen5tx2,prginf,0

prgwingrp   db 2,0:dw prgwinobj,prgwinclc,0,256*0+0,0,0,2
prgwinobj
            dw     00,255*256+00,8         ,0,0,0,0,0   ;00=Background
            dw edtchg,255*256+33,txtmulobj ,0,0,0,0,0   ;01=Editor

prgwinclc
            dw   0,      0,  0,  0,1000,      0,1000,      0    ;Background
            dw   1,      0,  1,  0,  -2,256*1+1, -2,256*1+1     ;Editor

txtmulobj   dw txtbufmem    ;texdatadr       equ 0           ;Zeiger auf Text
            dw 0            ;texdatbeg       equ 2           ;erstes angezeigtes Zeichen (nur singleline)
            dw 0            ;texdatpos       equ 4           ;Cursorposition im Gesamttext
            dw 0            ;texdatmrk       equ 6           ;0/Anzahl markierter Zeichen [neg->Cursor=Ende Markierung]
            dw 0            ;texdatlen       equ 8           ;Textlänge
            dw txtbufmax    ;texdatmax       equ 10          ;maximal zulässige Textlänge (1-16383; exklusive 0-Terminator)
            db 4            ;texdatflg       equ 12          ;Flags (Bit0=Paßwort [nur singleline], Bit1=ReadOnly, Bit2=AltColor, Bit3=AltFont [nur multiline], Bit7=Text has been modified)
                            ;;** extended 16c/altfont
            db 0+16         ;texdatcol       equ 13          ;4bit txtpap, 4bit txtpen
            db 0            ;texdatrhm       equ 14          ;4bit rahmen1, 4bit rahmen2 (nur singleline)
            dw 0            ;texdatfnt       equ 15          ;Adresse des alternativen Fonts
            ds 1            ;texdatrs1       equ 17          ;*reserved 2byte*
                            ;;** ab hier nur Multiline
            dw 0            ;texdatlnt       equ 18          ;aktuelle Anzahl Zeilen
            dw -1           ;texdatxmx       equ 20          ;maximale Zeilenbreite in Pixeln bei Wordwrap-Pos-Vorgabe (-1=unbegrenzt)
            dw txtlinmax    ;texdatymx       equ 22          ;maximale Anzahl Zeilen (*2 bytes ab texdatlln!)
            dw -8           ;texdatxwn       equ 24          ;win y len ohne slider für bisherige formatierung (winx<>aktx -> Neuformatierung notwendig, durch -8 erzwingen)
            dw 0            ;texdatywn       equ 26          ;win y len ohne slider
                            ;
            dw txtmulobj    ;texdatzgr       equ 28          ;pointer auf diesen datensatz
            dw 120          ;texdatxfl       equ 30          ;full x len (=Länge der längsten Textzeile in Pixel)
            dw 80           ;texdatyfl       equ 32          ;full y len (=Anzahl aller Textzeilen * 8)
            dw 0            ;texdatxof       equ 34          ;offset x
            dw 0            ;texdatyof       equ 36          ;offset y
            db 1+2          ;texdatfg2       equ 38          ;Flags (Bit0=kein Auto-WordWrap [dann Xslider], Bit1=1)
            db 0            ;texdattab       equ 39          ;Tabstop Größe (1-255; 0=kein Tabstop)
                            ;
            ds 4            ;texdatmsg       equ 40          ;Message-Buffer (in POS, MRK, out CXP, CYP)
            ds 4            ;texdatrs2       equ 44          ;*reserved 4byte*
            db 0            ;texdatlln       equ 48          ;Zeilen-Längentabelle (bit15=cr+lf am ende vorhanden, wird mitgezählt)
;!!!last line in transfer-area!!!

prgtrnend
