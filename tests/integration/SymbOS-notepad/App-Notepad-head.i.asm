;### APPLICATION HEADER #######################################################

txtbufmax   equ 16384-1-1536-2
txtlinmax   equ 1000

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
prgdatres       equ 62          ;*reserviert* (26 bytes)
prgdatver       equ 88          ;required OS version (1.0)
prgdatism       equ 90          ;Application icon (small version), 8x8 pixel, SymbOS graphic format
prgdatibg       equ 109         ;Application icon (big version), 24x24 pixel, SymbOS graphic format
prgdatlen       equ 256         ;length of header

prgpstdat       equ 6           ;start address of the data area
prgpsttra       equ 8           ;start address of the transfer area
prgpstspz       equ 10          ;additional sub process or timer IDs (4*1)
prgpstbnk       equ 14          ;64K ram bank (1-8), where the application is located
prgpstmem       equ 48          ;additional memory areas; 8 memory areas can be registered here, each entry consists of 5 bytes
                                ;00  1B  Ram bank number (1-8; if 0, the entry will be ignored)
                                ;01  1W  Address
                                ;03  1W  Length
prgpstnum       equ 88          ;Application ID
prgpstprz       equ 89          ;Main process ID

prgcodbeg   dw prgdatbeg-prgcodbeg  ;length of code area
            dw prgtrnbeg-prgdatbeg  ;length of data area
            dw prgtrnend-prgtrnbeg  ;length of transfer area
prgdatadr   dw #1000                ;original origin                    POST address data area
prgtrnadr   dw relocate_count       ;number of relocator table entries  POST address transfer area
prgprztab   dw prgstk-prgtrnbeg     ;stack length                       POST table processes
            dw 0                    ;*reserved*
prgbnknum   db 0                    ;*reserved*                         POST bank number
            db "Notepad":ds 32-7-8:db 0 ;Name
            db 1                    ;flags (+1=16c icon)
            dw prgicn16c-prgcodbeg  ;16 colour icon offset
            ds 5                    ;*reserved*
prgmemtab   db "SymExe10"           ;SymbOS-EXE-identifier              POST table reserved memory areas
            dw 0                    ;additional code memory
            dw txtbufmax+1536+2     ;additional data memory
            dw txtlinmax*2          ;additional transfer memory
            ds 26                   ;*reserviert*
            db 1,2                  ;required OS version (2.1)

prgicnsml   db 2,8,8,#31,#F5,#23,#3F,#56,#6E,#47,#6E,#8F,#EA,#FF,#AE,#74,#E2,#77,#EE
prgicnbig   db 6,24,24
            db #00,#00,#D0,#B0,#60,#C0,#00,#10,#60,#D0,#B0,#60,#00,#31,#F6,#FD,#FB,#F4,#00,#31,#FF,#FF,#FF,#FC,#00,#73,#FF,#FF,#FF,#FA,#00,#73,#FF,#FF,#FF,#FA,#00,#F7,#F0,#F0,#F7,#B6,#00,#F7,#FF,#FF,#FF,#F6
            db #10,#FE,#F0,#F0,#FE,#3E,#10,#FF,#FF,#FF,#FE,#3E,#31,#FF,#FF,#FF,#FD,#FE,#31,#FF,#FF,#FF,#ED,#3A,#73,#FF,#FF,#FF,#CB,#3A,#73,#FF,#FF,#FF,#FB,#FE,#F7,#FF,#FF,#FF,#87,#32,#F7,#FF,#FF,#FF,#87,#32
            db #70,#F0,#F0,#F0,#FF,#FE,#00,#21,#0F,#0F,#0E,#32,#00,#21,#0F,#0F,#0E,#32,#00,#31,#FF,#FF,#FF,#FE,#00,#21,#0F,#0F,#0C,#32,#00,#20,#00,#00,#00,#76,#00,#10,#FF,#FF,#FF,#EC,#00,#00,#F0,#F0,#F0,#C0
