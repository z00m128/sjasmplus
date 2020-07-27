; this is stub to build SymbOS-notepad sources
; the real source files are in the SymbOS-notepad folder

; the original source files were not just adjusted to conform
; sjasmplus syntax, but also renamed to work around
; the test-runner limitations, adding ".i.asm" extension to
; them to avoid assembling of individual files
;
; see also SymbOS-notepad/#readme.txt for links to original
; project and other info

;;;; test DAT file build (renamed to RAW in this test) ;;;;
    MODULE dat_file
        INCLUDE "SymbOS-notepad/App-Notepad2.i.asm"
    ENDMODULE

;;;; test EXE file build (renamed to BIN in this test) ;;;;
    INCLUDE "SymbOS-notepad/App-Notepad1.i.asm"
