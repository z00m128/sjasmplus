nolist

org #1000

write "nslookup.com"
READ <SymbOS-Constants.asm>

relocate_start

App_BegCode

;### APPLICATION HEADER #######################################################

;header structure
prgdatcod       equ 0           ;Length of the code area (OS will place this area everywhere)
prgdatdat       equ 2           ;Length of the data area (screen manager data; OS will place this area inside a 16k block of one 64K bank)
prgdattra       equ 4           ;Length of the transfer area (stack, message buffer, desktop manager data; placed between #c000 and #ffff of a 64K bank)
prgdatorg       equ 6           ;Original origin of the assembler code
prgdatrel       equ 8           ;Number of entries in the relocator table
prgdatstk       equ 10          ;Length of the stack in bytes
prgdatrs1       equ 12          ;*reserved* (3 bytes)
prgdatnam       equ 15          ;program name (24+1[0] chars)
prgdatflg       equ 40          ;flags (+1=16colour icon available)
prgdat16i       equ 41          ;file offset of 16colour icon
prgdatrs2       equ 43          ;*reserved* (5 bytes)
prgdatidn       equ 48          ;"SymExe10" SymbOS executable file identification
prgdatcex       equ 56          ;additional memory for code area (will be reserved directly behind the loaded code area)
prgdatdex       equ 58          ;additional memory for data area (see above)
prgdattex       equ 60          ;additional memory for transfer area (see above)
prgdatres       equ 62          ;*reserved* (26 bytes)
prgdatver       equ 88          ;required OS version (1.0)
prgdatism       equ 90          ;Application icon (small version), 8x8 pixel, SymbOS graphic format
prgdatibg       equ 109         ;Application icon (big version), 24x24 pixel, SymbOS graphic format
prgdatlen       equ 256         ;length of header

prgpstdat       equ 6           ;start address of the data area
prgpsttra       equ 8           ;start address of the transfer area
prgpstspz       equ 10          ;additional sub process or timer IDs (4*1)
prgpstbnk       equ 14          ;64K ram bank (1-15), where the application is located
prgpstmem       equ 48          ;additional memory areas; 8 memory areas can be registered here, each entry consists of 5 bytes
                                ;00  1B  Ram bank number (1-8; if 0, the entry will be ignored)
                                ;01  1W  Address
                                ;03  1W  Length
prgpstnum       equ 88          ;Application ID
prgpstprz       equ 89          ;Main process ID

            dw App_BegData-App_BegCode  ;length of code area
            dw App_BegTrns-App_BegData  ;length of data area
            dw App_EndTrns-App_BegTrns  ;length of transfer area
prgdatadr   dw #1000                ;original origin                    POST address data area
prgtrnadr   dw relocate_count       ;number of relocator table entries  POST address transfer area
prgprztab   dw prgstk-App_BegTrns   ;stack length                       POST table processes
            dw 0                    ;*reserved*
App_BnkNum  db 0                    ;*reserved*                         POST bank number
            db "NsLookUp":ds 16:db 0 ;name
            db 0                    ;flags (+1=16c icon)
            dw 0                    ;16c icon offset
            ds 5                    ;*reserved*
prgmemtab   db "SymExe10"           ;SymbOS-EXE-identifier              POST table reserved memory areas
            dw 0                    ;additional code memory
            dw 0                    ;additional data memory
            dw 0                    ;additional transfer memory
            ds 26                   ;*reserved*
            db 0,3                  ;required OS version (3.0)
prgicnsml   db 2, 8, 8:ds  16
prgicnbig   db 6,24,24:ds 144


;*** SYMSHELL LIBRARY USAGE
;   SyShell_PARALL              ;Fetches parameters/switches from command line
;   SyShell_PARSHL              ;Parses SymShell info switch
use_SyShell_PARFLG      equ 1   ;Validates present switches
use_SyShell_CHRINP      equ 0   ;Reads a char from the input source
use_SyShell_STRINP      equ 0   ;Reads a string from the input source
use_SyShell_CHROUT      equ 0   ;Sends a char to the output destination
use_SyShell_STROUT      equ 1   ;Sends a string to the output destination
use_SyShell_PTHADD      equ 0   ;...
;   SyShell_EXIT                ;Informs SymShell about an exit event

;*** SYSTEM MANAGER LIBRARY USAGE
use_SySystem_PRGRUN     equ 0   ;Starts an application or opens a document
use_SySystem_PRGEND     equ 1   ;Stops an application and frees its resources
use_SySystem_PRGSRV     equ 1   ;Manages shared services or finds applications
use_SySystem_SYSWRN     equ 0   ;Opens an info, warning or confirm box
use_SySystem_SELOPN     equ 0   ;Opens the file selection dialogue
use_SySystem_HLPOPN	equ 0   ;HLP file handling

;*** NETWORK DAEMON LIBRARY USAGE
;   SyNet_NETINI                ;...
use_SyNet_NETEVT        equ 0   ;Network event check
use_SyNet_CFGGET        equ 0   ;Config get data
use_SyNet_CFGSET        equ 0   ;Config set data
use_SyNet_CFGSCK        equ 0   ;Config socket status
use_SyNet_TCPOPN        equ 0   ;TCP open connection
use_SyNet_TCPCLO        equ 0   ;TCP close connecton
use_SyNet_TCPSTA        equ 0   ;TCP status of connection
use_SyNet_TCPRCV        equ 0   ;TCP receive from connection
use_SyNet_TCPSND        equ 0   ;TCP send to connection
use_SyNet_TCPSKP        equ 0   ;TCP skip received data
use_SyNet_TCPFLS        equ 0   ;TCP flush send buffer
use_SyNet_TCPDIS        equ 0   ;TCP disconnect connection
use_SyNet_TCPRLN        equ 0   ;TCP receive textline from connection
use_SyNet_UDPOPN        equ 0   ;UDP open
use_SyNet_UDPCLO        equ 0   ;UDP close
use_SyNet_UDPSTA        equ 0   ;UDP status
use_SyNet_UDPRCV        equ 0   ;UDP receive
use_SyNet_UDPSND        equ 0   ;UDP send
use_SyNet_UDPSKP        equ 0   ;UDP skip received data
use_SyNet_DNSRSV        equ 1   ;DNS resolve
use_SyNet_DNSVFY        equ 1   ;DNS verify

READ <symbos_lib-SymShell.asm>
READ <symbos_lib-SystemManager.asm>
READ <symbos_lib-NetworkDaemon.asm>
READ "Cmd-NsLookUp.asm"

App_EndTrns

relocate_table
relocate_end
