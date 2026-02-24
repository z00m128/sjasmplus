    HEXOUT "dir_hexout.raw"
    ORG     $1234
    DB      "HEX only\n"
start_1:
    DB      "per 16 bytes\n"
    ORG     $3456
    DB      "change adr by ORG\n"
    di                  ; try some instructions
    ld      hl,$ABCD
    jr      $
    HEXEND  start_1

    HEXOUT "dir_hexout.tap"
    ORG     $ABCD
    DB      "Fake TAP"
    HEXEND  -1          ; test explicit start address OFF

    HEXOUT "dir_hexout.bin"
    ORG     $5678
start_2:
    di
    ld      hl,$2345
    jr      $
    DB      "Second hex file\n"
    ; implicit close of open hex file by END instruction, changing also start address
    END     start_2

== implementation notes:

=== supported record block types:
- block 00 Data
- block 01 End of file
- block 03 start segment address
  - no idea if this is compatible with Z80 machines, but it's provided in *some* way
- everything else seems out of scope, especially as I don't plan banking support initially
- in case of banking I guess block 04 may be of interest

=== directives syntax
; HEXOUT <hex filename>
; HEXEND [<start_address>]  ; default comes from global state StartAddress (`END` directive)
; HEXEND -1                 ; explicit start address OFF

=== implementation specifics/peculiarities
; - only one HEX ouput can be active at time, ie. --hex vs HEXOUT vs SAVEHEX -> all collide together
; - no SIZE support for --hex and HEXOUT (doesn't seem to make sense with HEX containing records with addresses)
; - obviously no FPOS and append/rewind, HEX is not binary file but text file with formatting
; - no support for banks/longptr at this moment, open github issue if you have real use case for that
; `HEXEND` will finish also --hex started output
; `<end of source>` will finish also last HEXOUT started output

=== things to test in directive tests to test this thoroughly:
; - syntax errors of HEXOUT (and all errors added through code)
; - DEVICE + SAVEHEX combination
;   - (maybe not possible together with HEXOUT because of buffer? or collecting buffer vs device mem for lower level fn.)
; - test HEXOUT implicit close by EOF
