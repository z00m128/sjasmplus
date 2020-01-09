; only changes with V1.3 are tested here, the basic test is savenexSyntax.asm

    DEVICE ZXSPECTRUMNEXT

;; OPEN <filename>[,<startAddress>[,<stackAddress>[,<entryBank 0..111>[,<fileVersion 2..3>]]]]
    ; errors - [un]expected arguments
    SAVENEX OPEN "savenexSyntaxV_1_3.nex", $8000, $FFE0,15,  2,
    SAVENEX OPEN "savenexSyntaxV_1_3.nex", $8000, $FFE0,15,  2, 2
    SAVENEX OPEN "savenexSyntaxV_1_3.nex", $7170, $F1F0, 0,  1 ; error fileVersion
    SAVENEX OPEN "savenexSyntaxV_1_3.nex", $7170, $F1F0, 0,  4 ; error fileVersion

    ; one correct NEX file to verify simple case (but induce all sorts of warnings)
    SAVENEX OPEN "savenexSyntaxV_1_3.nex", $18180, $1F1F0, 'B', 2   ; force V1.2 version

    ; error = NEX file is already open
    SAVENEX     OPEN    "savenexSyntaxV_1_3.nex", $8180, $F1F0, 'B', 3

    ; few correct commands which didn't change with V1.3 support
    SAVENEX     CORE    3,0,6
    SAVENEX     CFG     5,  0,  1,  1

;; CFG3 <DoCRC 0/1>[,<PreserveExpansionBus 0/1>[,<CLIbufferAdr>,<CLIbufferSize>]]
    ; error because V1.2 file is enforced
    SAVENEX     CFG3    0,  1,  $DF00, 2048

;; BAR <loadBar 0/1>,<barColour 0..255>[,<startDelay 0..255>[,<bankDelay 0..255>[,<posY 0..255>]]]
    ; errors - [un]expected arguments
    SAVENEX     BAR     1,  'L',    'D',    'd', 0,
    SAVENEX     BAR     1,  'L',    'D',    'd', 0, 0

    ; correct ones with value warnings, and omitting optional arguments
    SAVENEX     BAR     1,  255, 255, 255, 256
    SAVENEX     BAR     1,  'L',    'D',    'd', 123 ; one fully valid (no warning)

;; PALETTE NONE
;; PALETTE DEFAULT
;; PALETTE MEM <palPage8kNum 0..223>,<palOffset>
;; PALETTE BMP <filename>
    ; errors - [un]expected arguments
    SAVENEX     PALETTE ETTELAP
    SAVENEX     PALETTE MEM
    SAVENEX     PALETTE MEM 100
    SAVENEX     PALETTE MEM 100,
    SAVENEX     PALETTE MEM 100, 0,
    SAVENEX     PALETTE MEM 100, 0, 0
    SAVENEX     PALETTE BMP
    SAVENEX     PALETTE BMP "pal.bmp",

    ; errors - wrong values
    SAVENEX     PALETTE MEM -1, 0
    SAVENEX     PALETTE MEM 224, 0
    SAVENEX     PALETTE MEM 10, -1
    SAVENEX     PALETTE MEM 0, 1792*1024-511
    SAVENEX     PALETTE BMP ""
    SAVENEX     PALETTE BMP "pal.bmp"
    SAVENEX     PALETTE BMP "savenexSyntaxV_1_3.asm"

    ; one correct (setting up DEFAULT palette type)
    SAVENEX     PALETTE DEFAULT

    ; verify that any one-more reports error
    SAVENEX     PALETTE NONE
    SAVENEX     PALETTE DEFAULT
    SAVENEX     PALETTE MEM 10, 0
    SAVENEX     PALETTE BMP "pal.bmp"

;; SCREEN L2_320 [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
;; SCREEN L2_640 [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
;; SCREEN TILE <NextReg $6B>,<NextReg $6C>,<NextReg $6E>,<NextReg $6F>[,<AlsoStoreBank5 0/1 = 1>]
    ; errors - because V1.2 is enforced
    SAVENEX     SCREEN  L2_320
    SAVENEX     SCREEN  L2_640
    SAVENEX     SCREEN  TILE 0, 1, 2, 3, 0

    ; errors - [un]expected arguments - possible to test for TILE screen (ahead V1.2 check)
    SAVENEX     SCREEN  TILE
    SAVENEX     SCREEN  TILE    0
    SAVENEX     SCREEN  TILE    0,
    SAVENEX     SCREEN  TILE    0,  1
    SAVENEX     SCREEN  TILE    0,  1,
    SAVENEX     SCREEN  TILE    0,  1,  2 
    SAVENEX     SCREEN  TILE    0,  1,  2,
    SAVENEX     SCREEN  TILE    0,  1,  2,  3,
    SAVENEX     SCREEN  TILE    0,  1,  2,  3, 0,

    ; errors - wrong values
    SAVENEX     SCREEN  TILE    0,  1,  2,  3, -1
    SAVENEX     SCREEN  TILE    0,  1,  2,  3, 2
    SAVENEX     SCREEN  TILE    256,  1,  2,  3, 0
    SAVENEX     SCREEN  TILE    0,  256,  2,  3, 0
    SAVENEX     SCREEN  TILE    0,  1,  256,  3, 0
    SAVENEX     SCREEN  TILE    0,  1,  2,  256, 0
    SAVENEX     SCREEN  TILE    -1,  1,  2,  3, 0
    SAVENEX     SCREEN  TILE    0,  -1,  2,  3, 0
    SAVENEX     SCREEN  TILE    0,  1,  -1,  3, 0
    SAVENEX     SCREEN  TILE    0,  1,  2,  -1, 0

;; SCREEN BMP <filename>[,<savePalette 0/1>[,<paletteOffset 0..15>]]
    ; errors - [un]expected arguments
    SAVENEX     SCREEN  BMP
    SAVENEX     SCREEN  BMP     ""
    SAVENEX     SCREEN  BMP     "",
    SAVENEX     SCREEN  BMP     "",     1,
    SAVENEX     SCREEN  BMP     "",     1,  0,

    ; errors - wrong values
    SAVENEX     SCREEN  BMP     "",     2
    SAVENEX     SCREEN  BMP     "",     0,  -2  ; -1 is internal value for "missing" palOfs => legal
    SAVENEX     SCREEN  BMP     "",     0,  16

    ; not testing correct variants, because it would make impossible to test other types

;; COPPER <Page8kNum 0..223>,<offset>
    ; errors - because V1.2 is enforced
    SAVENEX     COPPER 0, 0

    SAVENEX     CLOSE       ; warning about palette defined, but no screen

;; further syntax tests, this time with V1.3 enabled in OPEN

;; OPEN <filename>[,<startAddress>[,<stackAddress>[,<entryBank 0..111>[,<fileVersion 2..3>]]]]
    ; one correct NEX file to verify simple case
    SAVENEX OPEN "savenexSyntaxV_1_3.nex"   ; start with V1.2, enable V1.3

;; CFG3 <DoCRC 0/1>[,<PreserveExpansionBus 0/1>[,<CLIbufferAdr>,<CLIbufferSize>]]
    ; errors - [un]expected arguments
    SAVENEX     CFG3
    SAVENEX     CFG3    0,
    SAVENEX     CFG3    0,  1,
    SAVENEX     CFG3    0,  1,  $DF00
    SAVENEX     CFG3    0,  1,  $DF00,
    SAVENEX     CFG3    0,  1,  $DF00, 2048,

    ; correct ones with value warnings, and omitting optional arguments
    SAVENEX     CFG3    2
    SAVENEX     CFG3    1,  2
    SAVENEX     CFG3    1,  0,  $3FFF, 1
    SAVENEX     CFG3    1,  0,  $FFFF, 2
    SAVENEX     CFG3    1,  0,  $FF00, 0
    SAVENEX     CFG3    1,  0,  $E000, 2049
    SAVENEX     CFG3    1,  1,  0,  0    ; one completely correct (no warning) (+CRC)

;; SCREEN L2_320 [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
;; SCREEN L2_640 [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
    ; errors - [un]expected arguments - possible to test for TILE screen (ahead V1.2 check)
    SAVENEX     SCREEN  L2_320  0
    SAVENEX     SCREEN  L2_320  0,
    SAVENEX     SCREEN  L2_320  0,  0,
    SAVENEX     SCREEN  L2_320  0,  0,  0
    SAVENEX     SCREEN  L2_320  0,  0,  0,
    SAVENEX     SCREEN  L2_320  0,  0,  0,  0,

    SAVENEX     SCREEN  L2_640  0
    SAVENEX     SCREEN  L2_640  0,
    SAVENEX     SCREEN  L2_640  0,  0,
    SAVENEX     SCREEN  L2_640  0,  0,  0
    SAVENEX     SCREEN  L2_640  0,  0,  0,
    SAVENEX     SCREEN  L2_640  0,  0,  0,  0,

    ; errors - wrong values
    SAVENEX     SCREEN  L2_320  224,    0,      0,      0
    SAVENEX     SCREEN  L2_320    0,    0,    224,      0
    SAVENEX     SCREEN  L2_320    0, 1792*1024 - 80*1024 + 1,  0,  0
    SAVENEX     SCREEN  L2_320    0,    0,  0,  1792*1024 - 512 + 1
    SAVENEX     SCREEN  L2_320  223,    0
    SAVENEX     SCREEN  L2_320    0, 1792*1024 - 80*1024 + 1

    SAVENEX     SCREEN  L2_640  224,    0,      0,      0
    SAVENEX     SCREEN  L2_640    0,    0,    224,      0
    SAVENEX     SCREEN  L2_640    0, 1792*1024 - 80*1024 + 1,  0,  0
    SAVENEX     SCREEN  L2_640    0,    0,  0,  1792*1024 - 512 + 1
    SAVENEX     SCREEN  L2_640  223,    0
    SAVENEX     SCREEN  L2_640    0, 1792*1024 - 80*1024 + 1

;; COPPER <Page8kNum 0..223>,<offset>
    ; errors - [un]expected arguments
    SAVENEX     COPPER
    SAVENEX     COPPER 0
    SAVENEX     COPPER 0,
    SAVENEX     COPPER 0, 0,

    ; errors - wrong values
    SAVENEX     COPPER 224, 0
    SAVENEX     COPPER 0, 1792*1024 - 2048 + 1

    ; valid copper commands
    SAVENEX     COPPER 0, 0
    SAVENEX     COPPER 0, 0     ; can be used multiple times, it will simple overwrite old code (silently)

;; SCREEN TILE <NextReg $6B>,<NextReg $6C>,<NextReg $6E>,<NextReg $6F>[,<AlsoStoreBank5 0/1 = 1>]
    ; testing single correct variant (will block all other screens and palette)
    SAVENEX     SCREEN  TILE    0, 1, 2, 3, 1      ; will also store Bank 5

    SAVENEX     PALETTE DEFAULT     ; fails because after screen

    SAVENEX     COPPER 0, 0         ; fails because bank is already saved

    ;; sjasmplus should calculate also CRC-32C value here
    SAVENEX     CLOSE


;; create small NEX for BIN comparison, if the thing at least somewhat works
;; also verify it works twice per source (in sequential order)
    SAVENEX OPEN "savenexSyntaxV_1_3.bin", $5000, $FE00, 0, 3
    SAVENEX CORE 3,0,6 : SAVENEX CFG 4,0,0,0
    SAVENEX CFG3 1,0,$E000,1234 : SAVENEX BAR 1,100,99,13,222
    ORG $4800 : DB $45, $5F, $F5, $44
    ORG $5000
    nextreg $69,0               ; hide Layer 2, ULA screen
    jr $                        ; infinite JR loop
    MMU 7, 18
    org $E000 : DS $2000, %000'111'00   ; green top 32px strip
    SAVENEX PALETTE DEFAULT
    SAVENEX SCREEN L2_320
    SAVENEX AUTO 5, 5                       ; should store bank5
    ; let it close automatically by ending source

    END $7170       ; invoke warning about different start address
