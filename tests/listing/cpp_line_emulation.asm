; Issue #361 - adding `#line` keyword to inject custom file/line position for following source code
; this will also affect listing files and SLD files, although maybe not thoroughly enough
; I consider this a feature at this moment, if you want to use `#line`, you should already
; have pretty good idea what you are doing and why (probably generating .asm files by compiler)
; and either deal with consequences, or open github issue describing the use case and details of issue.

    DEVICE ZXSPECTRUM48, -1 ; DEVICE to make SLD file meaningful
    ORG $C000
    sla d                   ; SLD - regular instruction and everything

    #line 123               ; error, in sjasmplus the hash must be at beginning of line
  >#line 234                ; except label identation, then the beginning of line is shifted after the '>'
    invalid_instruction     ; error should be reported at line 234
    sla d                   ; SLD

#line 9997
    invalid_instruction     ; error should be reported at line 9997
    invalid_instruction     ; error should be reported at line 9998
    ; and this should bump listing line numbering space for line 10000 as well (next line is 10000)
#   line   3456             // survive also C/C++ comments and allow whitespace after hash
    invalid_instruction     ; error should be reported at line 3456
    invalid_instruction     ; error should be reported at line 3457
    ASSERT 3458 == __LINE__ ; verify the __LINE__ predefined is updated with fake line number too
    sla d                   ; SLD
#line 13 "C:/file.pas"      // filenames with colon must be in quotes/apostrophes
    invalid_instruction     ; error should be reported at C:/file.pas(13)
    invalid_instruction     ; error should be reported at C:/file.pas(14)
    sla d                   ; SLD

#line 57 /unix/path/file    // nix-like paths can be used without quotes, until you hit "//" in non-canonical path
                            // so recommended way is to quote filenames even in nix-like situations
    invalid_instruction     ; error should be reported at /unix/path/file(58)
    invalid_instruction     ; error should be reported at /unix/path/file(59)
    sla d                   ; SLD

#line 345                   // keeps fake filename, just changes line number
    invalid_instruction     ; error should be reported at /unix/path/file(345)
    sla d                   ; SLD

    ; syntax errors of #line itself
#line weirdnum
#line 9876 "open_quotes
    invalid_instruction     ; error should be reported at /unix/path/file(351)
    sla d                   ; SLD

    DEFINE QUOTE "
    DB QUOTE _ __FILE__ _ QUOTE     ; expected result: DB "/unix/path/file"

    ; including 1 byte from myself should work "of course" (even when __FILE__ and source position points to other root dir)
    INCBIN "./cpp_line_emulation.asm", 0, 1

    MACRO lineinside linenum?, fname?
#line linenum? fname?       ; errors out, #line inside MACRO is NOT supported
        invalid_instruction
        sla d               ; SLD
    ENDM

    lineinside 5101, "/other/file.pas"
    invalid_instruction     ; macro can't affect source pos reported here
    sla d                   ; SLD

    DUP 2
#line 5201, "/other/file.pas"   ; does NOT work inside DUP block (it's macro body)
        invalid_instruction
        sla d                   ; SLD
    EDUP

    LUA ALLPASS
        _pl("#line 5301 /some/lua.script")
        _pc("invalid_instruction")
        _pc("sla d")
    ENDLUA

#line -1                    // negative values are not valid
#line 0                     // 0 will also not work, 1 is minimum (difference from GNU cpp)
    invalid_instruction     ; error should be reported at /unix/path/file(378)
    sla d                   ; SLD
#line 1 '/another/fake.file'// this is the minimum, test apostrophes and EOL comment connected
    invalid_instruction     ; error should be reported at /another/fake.file(1)
    sla d                   ; SLD

    ; verify INCLUDE does search actual real directories of original file, not depending on __FILE__ content
    INCLUDE "cpp_line_emulation/cpp_line_emulation.i.asm"
    INCLUDE "cpp_line_emulation.i.asm"          ; search also CLI include path option

    invalid_instruction     ; error should be reported at /another/fake.file(8)
    sla d                   ; SLD

    mac_from_include        ; defined in include
