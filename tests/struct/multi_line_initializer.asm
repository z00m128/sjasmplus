    STRUCT S_SymbOS_icon_header
type        BYTE    2
sizex       BYTE    8
sizey       BYTE    8
    ENDS

    STRUCT S_SymbOS_exe_header
codelen     WORD                ;Length of the code area (OS will place this area everywhere)
datalen     WORD                ;Length of the data area (screen manager data; OS will place this area inside a 16k block of one 64K bank)
tranlen     WORD                ;Length of the transfer area (stack, message buffer, desktop manager data; placed between #c000 and #ffff of a 64K bank)
datadr:
origin      WORD                ;Original origin of the assembler code      ; POST address data area
trnadr:
relcount    WORD                ;Number of entries in the relocator table   ; POST address transfer area
prztab:
stacksize   WORD                ;Length of the stack in bytes               ; POST table processes or timer IDs (4*1)
            BLOCK   2, 0        ;*reserved* (2 bytes)
bnknum      BLOCK   1, 0        ;*reserved* (1 byte)                        ; POST 64K ram bank (1-8), where the application is located
name        TEXT    25          ;program name (24+1[0] chars)
flags       BYTE                ;flags (+1=16colour icon available)
icon16      WORD                ;file offset of 16colour icon
            BLOCK   5, 0        ;*reserved* (5 bytes)
memtab:                         ;"SymExe10" SymbOS executable file identification ; POST table reserved memory areas
identifier  TEXT    8, { "SymExe10" }
codex       WORD                ;additional memory for code area (will be reserved directly behind the loaded code area)
datex       WORD                ;additional memory for data area (see above)
trnex       WORD                ;additional memory for transfer area (see above)
            BLOCK   26, 0       ;*reserviert* (26 bytes)
appId:
osver       WORD                ;required OS version (1.0)
        ;Application icon (small version), 8x8 pixel, SymbOS graphic format
iconsm      S_SymbOS_icon_header { 2, 8, 8 }
icobsmdat   TEXT    16
        ;Application icon (big version), 24x24 pixel, SymbOS graphic format
iconbg      S_SymbOS_icon_header { 6, 24, 24 }
icobbgdat   TEXT    128         ; should be 144 bytes, but "TEXT" can be 128 bytes long at most
            TEXT    16          ; so this is split into two blocks
    ENDS

    ASSERT 256 == S_SymbOS_exe_header
    ASSERT 6 == S_SymbOS_exe_header.datadr
    ASSERT 8 == S_SymbOS_exe_header.trnadr
    ASSERT 10 == S_SymbOS_exe_header.prztab
    ASSERT 14 == S_SymbOS_exe_header.bnknum

;additional memory areas; 8 memory areas can be registered here, each entry consists of 5 bytes
;00  1B  Ram bank number (1-8; if 0, the entry will be ignored)
;01  1W  Address
;03  1W  Length
    ASSERT 48 == S_SymbOS_exe_header.memtab

;Application ID
    ASSERT 88 == S_SymbOS_exe_header.appId

;Main process ID is at (S_SymbOS_exe_header.appId+1) (offset 89), but it is not easy
;to create such label if "osver" is WORD type, that would need "union"-like feature
;that's unlikely to happen, it's more reasonable to define osver as two bytes then.

    OUTPUT "multi_line_initializer.bin"
    ORG     #1000

exeHeader   S_SymbOS_exe_header {
    #1234                   ; implicit delimiter at end (newline) (new line is next value)
    #2345,                  ; explicit delimiter (comma) is valid only *AFTER* value
    #3456
    #1011
    #0203                   ; relocate_count
    #0405                   ; stack size
    { "MyName" }            ; name
    #AA, #ACAB,             ; flags, 16col icon offset
    ,                       ; keep default identifier
    #0102, #0304, #0506     ; code/data/transfer extra memory
    #0708                   ; OS ver

    ; small icon
    ,                       ; type + size sub-structure (default values)

    {

        #31,#F5,#23,#3F,#56,#6E,#47,#6E,#8F,#EA,#FF,#AE,#74,#E2,#77,#EE

    }

    ; big icon (data are split into two blocks: 128 + 16 bytes
    {}, {
        #00,#00,#D0,#B0,#60,#C0,#00,#10,#60,#D0,#B0,#60,#00,#31,#F6,#FD,
        #FB,#F4,#00,#31,#FF,#FF,#FF,#FC,#00,#73,#FF,#FF,#FF,#FA,#00,#73,
        #FF,#FF,#FF,#FA,#00,#F7,#F0,#F0,#F7,#B6,#00,#F7,#FF,#FF,#FF,#F6,
        #10,#FE,#F0,#F0,#FE,#3E,#10,#FF,#FF,#FF,#FE,#3E,#31,#FF,#FF,#FF,
        #FD,#FE,#31,#FF,#FF,#FF,#ED,#3A,#73,#FF,#FF,#FF,#CB,#3A,#73,#FF,
        #FF,#FF,#FB,#FE,#F7,#FF,#FF,#FF,#87,#32,#F7,#FF,#FF,#FF,#87,#32,
        #70,#F0,#F0,#F0,#FF,#FE,#00,#21,#0F,#0F,#0E,#32,#00,#21,#0F,#0F,
        #0E,#32,#00,#31,#FF,#FF,#FF,#FE,#00,#21,#0F,#0F,#0C,#32,#00,#20
    },
    {
        #00,#00,#00,#76,#00,#10,#FF,#FF,#FF,#EC,#00,#00,#F0,#F0,#F0,#C0
    }
    ; these empty lines before final "}" are intentional

}
        daa     ; first line after multi-line struct init (make sure it gets into listing!)
    OUTEND
