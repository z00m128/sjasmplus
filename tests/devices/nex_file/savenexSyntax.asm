;;; docs design (missing the changes after V1.3 introduction, added directly in docs.xml)
;     SAVENEX <command> <command arguments>
;  Works only in ZXSPECTRUMNEXT device emulation mode. See DEVICE.
;
;  For file format details, check https://specnext.dev/wiki/NEX_file_format
;
;  As the file is designed for self-contained distribution of whole applications/games,
; its configuration and assembling is a bit too complex for single directive, and the
; configuration is instead divided into multiple commands, and the assembling goes
; through multiple stages, so some commands must be used in correct sequence.
;
; While the format technically allows to include multiple screen types data, they are
; all loaded at the beginning over each other, so it makes sense to provide only single
; loading screen (sjasmplus enforces that).
;
; More detailed description of each command follows:
;
;     SAVENEX OPEN <filename>[,<startAddress>[,<stackAddress>[,<entryBank 0..111>]]]
; Opens a NEX file, defines start address and stack address (if omitted, start address is
; zero = no start, stack address is 0xFFFE, entryBank is zero), and 16k bank to be mapped
; at 0xC000 before code is started.
;
; Only single NEX file can be open at the same time, and to finalize the header content
; the command CLOSE has to be used (does auto-close if source ends).
;
; Entry bank is number of 16k bank (0..111), not native 8k page, default is zero, i.e.
; the default memory map is identical to ZX 128 (ROM, RAM banks 5, 2 and 0).
;
; Make sure your new stack has at least tens of bytes available as those will be used
; already by the NEX loader before executing your entry point (although released back).
;
;     SAVENEX CORE <major 0..15>,<minor 0..15>,<subminor 0..255>
; Set minimum required Next core version, can be set any time before CLOSE.
;
;     SAVENEX CFG <border 0..7>[,<fileHandle 0/1/$4000+>[,<PreserveNextRegs 0/1>[,<2MbRamReq 0/1>]]]
; Set border colour (during loading), whether the machine should be set to default state
; (PreserveNextRegs = 0 = default), if the app requires extended RAM (224 8k pages) and
; how the file handle of the NEX file should be treated: 0 = default = close, 1 = keep
; open and pass in BC, $4000..$FFFE = keep open, and write into memory at provided address
; (after entry bank is paged in). This can be set any time before CLOSE.
;
;     SAVENEX BAR <loadBar 0/1>,<barColour 0..255>[,<startDelay 0..255>[,<bankDelay 0..255>]]
; Loading-bar related setup ("colour" usage depends on screen mode), can be set any time
; before CLOSE.
;
;     SAVENEX SCREEN L2 [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
; Layer 2 loading screen, can be used between OPEN and first AUTO/BANK command.
;
; Palette consists of 512 bytes (256 palette items from index 0), in 9b colour format:
; first byte is %RRRGGGBB, second byte is %P000000B (P is priority flag for Layer 2 colours).
;
; Image data are 48kiB block of memory, the loader will use always banks 9..11 to display
; it (8k pages 18..23), but if you will prepare the data there, it will be also re-saved
; by AUTO command, so either use other banks, and overwrite them with valid data/code
; after using the SCREEN command, or reset pages 18..23 to zero after SCREEN.
;
; If no memory address is specified, the pages 18..23 are stored in file, and if no
; palette address is specified, no-palette flag is set in NEX file.
;
;     SAVENEX SCREEN LR [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
; LoRes (128x96) loading screen, can be used between OPEN and first AUTO/BANK command.
;
; Palette is similar to Layer 2 mode, just LoRes mode doesn't have priority bit.
;
; Image data are 12288 bytes memory block - either consecutive block if specific address
; is provided, or without address the actual bank 5 memory is stored (taking 6144 bytes
; from address 0x4000 and 6144 bytes from address 0x6000).
;
;     SAVENEX SCREEN (SCR|SHC|SHR) [<hiResColour 0..7>]
; ULA/Timex modes loading screen, can be used between OPEN and first AUTO/BANK command.
;
; The actual bank 5 memory (pages 10..11) is stored as if the image is displayed, in
; these modes the palette can't be specified.
;
; SCR is classic ZX 6912 bytes long screen from address 0x4000 (page 10 is used, even
; if the slot 1 is modified to other page, so you must prepare the image "in place").
;
; SHC and SHR are Timex HiColor (8x1 attribute) and HiRes (512x192 bitmap) modes, prepare
; data "in place", i.e. 6144 bytes into page 10 and 6144 bytes into page 11 (0x4000 and
; 0x6000 addresses in default memory setup). For HiRes mode you should specify ink colour
; (the paper is complement of ink).
;
;     SAVENEX BANK <bank 0..111>[,...]
; Can be used after OPEN or SCREEN and before CLOSE, but the 16ki banks must be saved in
; correct order: 5, 2, 0, 1, 3, 4, 6, 7, ..., 111
;
;     SAVENEX AUTO [<fromBank 0..111>[,<toBank 0..111>]]
; Can be used after OPEN or SCREEN and before CLOSE. The sjasmplus will save every
; 16k bank containing at least one non-zero byte; detected in the correct order
; (automatically starting from first possible bank after previous BANK/AUTO commands,
; or from provided "fromBank").
;
; For "fromBank" value use the specified order above in BANK command, i.e. 5, 2, 0, ...
;
;     SAVENEX CLOSE [<fileToAppend>]
; Can be used after OPEN. The currently open NEX file will be finalized (header adjusted),
; and optional extra file just appended to the end of NEX file.

    DEVICE NONE     ; correct commands, but outside of NEXT device
    SAVENEX     OPEN    "savenexSyntax.nex",    $8000,$FFE0,    15  ; not in NEXT mode

    DEVICE ZXSPECTRUMNEXT
    SAVENEX NEPO    ; wrong command

;; OPEN <filename>[,<startAddress>,<stackAddress>[,<entryBank 0..111>]]
    ; errors - [un]expected arguments
    SAVENEX
    SAVENEX                 ; no command, but with comment
    SAVENEX     OPEN
    SAVENEX     OPEN    "savenexSyntax.nex",
    SAVENEX     OPEN    "savenexSyntax.nex",    $8000,
    SAVENEX     OPEN    "savenexSyntax.nex",    $8000,$FFE0,
    SAVENEX     OPEN    "savenexSyntax.nex",    $8000,$FFE0,    15,
    SAVENEX OPEN "savenexSyntax.nex", $7170, $F1F0, 112 ; error entryBank

    ; one correct NEX file to verify simple case (but induce all sorts of warnings)
    SAVENEX     OPEN    "savenexSyntax.nex",    $18180,$1F1F0,  'B'

    ; error = NEX file is already open
    SAVENEX     OPEN    "savenexSyntax.nex", $8180, $F1F0, 'B'

;; CORE <major 0..15>,<minor 0..15>,<subminor 0..255>
    ; errors - [un]expected arguments
    SAVENEX     CORE
    SAVENEX     CORE    0
    SAVENEX     CORE    0,
    SAVENEX     CORE    0,0
    SAVENEX     CORE    0,0,
    SAVENEX     CORE    0,0,0,

    ; one correct + one with warnings
    SAVENEX     CORE    15,15,255
    SAVENEX     CORE    'a','b',$100+'c'    ; warn about values

;; CFG <border 0..7>[,<fileHandle 0/1/$4000+>[,<PreserveNextRegs 0/1>[,<2MbRamReq 0/1>]]]
    ; errors - [un]expected arguments
    SAVENEX     CFG
    SAVENEX     CFG     5,
    SAVENEX     CFG     5,  1,
    SAVENEX     CFG     5,  1,  1,
    SAVENEX     CFG     5,  1,  1,  1,

    ; correct ones with value warnings, and omitting optional arguments
    SAVENEX     CFG     9
    SAVENEX     CFG     5,  -1
    SAVENEX     CFG     5,  1,  2
    SAVENEX     CFG     5,  "hf",  1,  1    ; one completely correct (no warning)
    SAVENEX     CFG     5,  "hf",  1,  'R'

;; BAR <loadBar 0/1>,<barColour 0..255>[,<startDelay 0..255>[,<bankDelay 0..255>]]
    ; errors - [un]expected arguments
    SAVENEX     BAR
    SAVENEX     BAR     1
    SAVENEX     BAR     1,
    SAVENEX     BAR     1,  'L',
    SAVENEX     BAR     1,  'L',    'D',
    SAVENEX     BAR     1,  'L',    'D',    'd',

    ; correct ones with value warnings, and omitting optional arguments
    SAVENEX     BAR     2,  255
    SAVENEX     BAR     1,  256
    SAVENEX     BAR     1,  255, 256
    SAVENEX     BAR     1,  255, 255, 256
    SAVENEX     BAR     1,  'L',    'D',    'd' ; one fully valid (no warning)

;; SCREEN L2 [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
    ; errors - [un]expected arguments
    SAVENEX     SCREEN
    SAVENEX     SCREEN  NEERCS
    SAVENEX     SCREEN  L2  9
    SAVENEX     SCREEN  L2  9 ,
    SAVENEX     SCREEN  L2  9 ,    $1FFF ,
    SAVENEX     SCREEN  L2  9 ,    $1FFF ,  10
    SAVENEX     SCREEN  L2  9 ,    $1FFF ,  10 ,
    SAVENEX     SCREEN  L2  9 ,    $1FFF ,  10 ,    $1800,

    ; errors - wrong values
    SAVENEX     SCREEN  L2 224, 0, 0, 0     ; pagenum outside of range
    SAVENEX     SCREEN  L2 0, 0, 224, 0     ; pagenum outside of range
    SAVENEX     SCREEN  L2 218, 1, 0, 0     ; values in range, but leaks out of memory
    SAVENEX     SCREEN  L2 0, $1B4001, 0, 0 ; values in range, but leaks out of memory
    SAVENEX     SCREEN  L2 0, 0, 223, 7681  ; values in range, but leaks out of memory
    SAVENEX     SCREEN  L2 0, 0, 0, $1BFE01 ; values in range, but leaks out of memory
    SAVENEX     SCREEN  L2 218, 1           ; values in range, but leaks out of memory
    SAVENEX     SCREEN  L2 0, $1B4001       ; values in range, but leaks out of memory
    ; not testing correct variants, because it would make impossible to test other types

;; SCREEN LR [<Page8kNum 0..223>,<offset>[,<palPage8kNum 0..223>,<palOffset>]]
    ; errors - [un]expected arguments
    SAVENEX     SCREEN  LR  5
    SAVENEX     SCREEN  LR  5 ,
    SAVENEX     SCREEN  LR  5 ,    $1FFF ,
    SAVENEX     SCREEN  LR  5 ,    $1FFF ,  10
    SAVENEX     SCREEN  LR  5 ,    $1FFF ,  10 ,
    SAVENEX     SCREEN  LR  5 ,    $1FFF ,  10 ,    $1800,

    ; errors - wrong values
    SAVENEX     SCREEN  LR 224, 0, 0, 0     ; pagenum outside of range
    SAVENEX     SCREEN  LR 0, 0, 224, 0     ; pagenum outside of range
    SAVENEX     SCREEN  LR 222, $1001, 0, 0 ; values in range, but leaks out of memory
    SAVENEX     SCREEN  LR 0, $1BD001, 0, 0 ; values in range, but leaks out of memory
    SAVENEX     SCREEN  LR 0, 0, 223, 7681  ; values in range, but leaks out of memory
    SAVENEX     SCREEN  LR 0, 0, 0, $1BFE01 ; values in range, but leaks out of memory
    SAVENEX     SCREEN  LR 222, $1001       ; values in range, but leaks out of memory
    SAVENEX     SCREEN  LR 0, $1BD001       ; values in range, but leaks out of memory
    ; not testing correct variants, because it would make impossible to test other types

;; SCREEN (SCR|SHC|SHR) [<hiResColour 0..7>]
    ; there's basically no syntax error possible with these

;; BANK <bank 0..111>[,...]
    ; errors - invalid/missing arguments (will eventually also save some banks correctly)
    SAVENEX     BANK    ()
    SAVENEX     BANK    -1
    SAVENEX     BANK    112
    SAVENEX     BANK    5,                  ; bank 5 will be stored
    SAVENEX     BANK    0, 2, 3             ; bank 0 will be stored, 2 = wrong order

    ; revisit screen errors - here no screen should work because bank was written already
    SAVENEX     SCREEN  L2
    SAVENEX     SCREEN  LR
    SAVENEX     SCREEN  SCR
    SAVENEX     SCREEN  SHC
    SAVENEX     SCREEN  SHR 10

;; AUTO [<fromBank 0..111>[,<toBank 0..111>]]
    SAVENEX     AUTO    21,
    SAVENEX     AUTO    21,     25,
    SAVENEX     AUTO    -1, 20
    SAVENEX     AUTO    112, 20
    SAVENEX     AUTO    21, -1
    SAVENEX     AUTO    21, 112
    SAVENEX     AUTO    21, 20
    SAVENEX     AUTO    5, 1                ; already stored by BANK above
    SAVENEX     AUTO    0, 1
    SAVENEX     AUTO    1, 1                ; correct one (but bank is zeroed = no output)
    SAVENEX     AUTO    1, 1                ; but disabled for second try
    SAVENEX     AUTO                        ; correct (but all zeroes = no output)
    SAVENEX     AUTO                        ; but all are disabled now

;; CLOSE [<fileToAppend>]
    SAVENEX     CLOSE   "savenexSyntax.asm" ; correct one (there's not much to do wrong
    SAVENEX     CLOSE                       ; should be error (no NEX is open)

;; create small NEX for BIN comparison, if the thing at least somewhat works
;; also verify it works twice per source (in sequential order)
    SAVENEX OPEN "savenexSyntax.bin", $5000
    SAVENEX CORE 2,0,28 : SAVENEX CFG 4,0,0,1 : SAVENEX BAR 0,0,100,0
    ORG $4800 : DB $45, $5F, $F5, $44
    ORG $5000 : jr $                        ; infinite JR loop
    SAVENEX AUTO 5, 5                       ; should store bank5
    ; let it close automatically by ending source

    END $7170       ; invoke warning about different start address
