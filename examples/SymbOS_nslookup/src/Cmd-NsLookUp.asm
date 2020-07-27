;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                           SymbOS network daemon                            @
;@                              N S L O O K U P                               @
;@                                                                            @
;@               (c) 2015 by Prodatron / SymbiosiS (Jörn Mika)                @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


;### PRGPRZ -> Programm-Prozess
prgprz  call SyShell_PARALL     ;get commandline parameters
        push de
        call SyShell_PARSHL     ;fetch shell-specific parameters
        jp c,prgend
        ld hl,nsltxttit         ;title text
        ld e,0
        call SyShell_STROUT
        jp c,prgend
        pop de
        ld a,d
        cp 1                    ;exactly 1 parameter (domain name) is required
        ld hl,nsltxtpar
        jp nz,prgend0

        call SyNet_NETINI               ;***** INIT NETWORK API (SEARCH FOR THE DAEMON)
        ld hl,nsltxtdmn
        jr c,prgend0            ;no daemon found -> error

        ld hl,nsltxtdns
        ld e,0
        call SyShell_STROUT

        call prgdns
        jr prgend

;### PRGEND -> Programm beenden
prgend0 ld e,0
        call SyShell_STROUT
prgend  ld e,0
        call SyShell_EXIT       ;tell Shell, that process will quit
        ld hl,(App_BegCode+prgpstnum)
        call SySystem_PRGEND
prgend1 rst #30
        jr prgend1

;### PRGERR -> display DNS error message
prgerr  ld hl,nsltxterr
        sub 16
        jr c,prgend0
        cp 4+1
        jr nc,prgend0
        add a
        ld c,a
        ld b,0
        ld hl,nsldnstab
        add hl,bc
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        jr prgend0

;### PRGDNS -> DNS resolve
prgdns  ld hl,(SyShell_CmdParas+0)
        call SyNet_DNSRSV               ;***** DNS RESOLVE
        jr c,prgerr             ;lookup failed -> error
        ld hl,nsltxtipa+12
        ld e,"."
        db #dd:ld a,l:call clcn08:ld (hl),e:inc hl
        db #dd:ld a,h:call clcn08:ld (hl),e:inc hl
        db #fd:ld a,l:call clcn08:ld (hl),e:inc hl
        db #fd:ld a,h:call clcn08:ld (hl),0
        ld hl,nsltxtipa:ld e,0:call SyShell_STROUT
        ld hl,nsltxtlfd:ld e,0:call SyShell_STROUT
        ret


nsltxttit   db 13,10
            db "NSLOOKUP 1.0 (c)oded 2015 by Prodatron",13,10,0
nsltxtdns   db "Send DNS request",13,10,0
nsltxtipt   db "X-type",13,10,0
nsltxtipa   db "IP address: xxx.xxx.xxx.xxx",0

nsltxtpar   db "Wrong or missing parameter",13,10
            db "NSLOOKUP <domainname>",13,10,0
nsltxtdmn   db "Network daemon not running!",13,10,0

nsltxtlfd   db 13,10,13,10,0

nsldnstab   dw nsldnstxt1,nsldnstxt2,nsldnstxt3,nsldnstxt4,nsldnstxt5
nsldnstxt1  db "Invalid domain string",13,10,0
nsldnstxt2  db "Request timeout",13,10,0
nsldnstxt3  db "Recursion currently not supported",13,10,0
nsldnstxt4  db "Truncated answer",13,10,0
nsldnstxt5  db "Package too large",13,10,0

nsltxterr   db "Error",13,10,0

neterrdiv   equ 16  ;dns - invalid domain string
neterrdto   equ 17  ;dns - timeout
neterrdrc   equ 18  ;dns - recursion not supported
neterrdtr   equ 19  ;dns - truncated answer
neterrdln   equ 20  ;dns - package too large


;==============================================================================
;### SUB-ROUTINEN #############################################################
;==============================================================================

;### CLCN08 -> Converst 8bit value into ASCII string (0-terminated)
;### Input      A=Value, HL=Destination
;### Output     HL=points behind last digit
;### Destroyed  AF,BC
clcn08  cp 10
        jr c,clcn082
        cp 100
        jr c,clcn081
        ld c,100
        call clcn083
clcn081 ld c,10
        call clcn083
clcn082 add "0"
        ld (hl),a
        inc hl
        ld (hl),0
        ret
clcn083 ld b,"0"-1
clcn084 sub c
        inc b
        jr nc,clcn084
        add c
        ld (hl),b
        inc hl
        ret


;==============================================================================
;### DATEN-TEIL ###############################################################
;==============================================================================

App_BegData

;### nothing (more) here
db 0

;==============================================================================
;### TRANSFER-TEIL ############################################################
;==============================================================================

App_BegTrns
;### PRGPRZS -> Stack für Programm-Prozess
            ds 64
prgstk      ds 6*2
            dw prgprz
App_PrcID   db 0
App_MsgBuf  ds 14
