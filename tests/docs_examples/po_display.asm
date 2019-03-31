; DISPLAY options
; /D - out only in Decimal
; /H - out only in Hexadecimal
; /A - out both in Hexadecimal and Decimal

;; Example with DISPLAY directive description

    ORG 100h
TESTLABEL:
    ;...some code...
    RET
    DISPLAY "--the some program-- by me"
    DISPLAY "TESTLABEL address is:",/A,TESTLABEL
/*
will output to the console strings:
> --the some program-- by me
> TESTLABEL address is:0x100, 256
*/

;; Part of example in LUA chapter of documentation (modified to pin date to fixed one)
    LUA
        -- Creates define "TIME" with current time
        datetime = os.date("%Y-%m-%d %H:%M:%S")
        datetime = "1982-04-23 03:14:15"    -- set it to fixed string for CI tests to pass
        sj.insert_define("TIME", '"' .. datetime .. '"')
    ENDLUA

    DISPLAY "Build time: ", TIME
/*
will output to the console strings:
Build time: <current date+time>  --> not current, but fixed one, for automated tests to pass
*/

;; Non-documentation manual tests of DISPLAY

    DISPLAY 0x100, " | ", /D, 0x100, " | ", 0x100, " | ", /H, 0x100, " | ", 0x100, " | ", /A, 0x100, " | ", 0x100, " |s: ", "0x100"
    DISPLAY -2, " | ", /D, -2, " | ", -2, " | ", /H, -2, " | ", -2, " | ", /A, -2, " | ", -2, " |s: ", "-2"
    DISPLAY 0xFF0000, " | ", /D, 0xFF0000, " | ", 0xFF0000, " | ", /H, 0xFF0000, " | ", 0xFF0000, " | ", /A, 0xFF0000, " | ", 0xFF0000, " |s: ", "0xFF0000"
    DISPLAY 0xFF<<24, " | ", /D, 0xFF<<24, " | ", 0xFF<<24, " | ", /H, 0xFF<<24, " | ", 0xFF<<24, " | ", /A, 0xFF<<24, " | ", 0xFF<<24, " |s: ", "0xFF<<24"
    DISPLAY 0xFF<<20, " | ", /D, 0xFF<<20, " | ", 0xFF<<20, " | ", /H, 0xFF<<20, " | ", 0xFF<<20, " | ", /A, 0xFF<<20, " | ", 0xFF<<20, " |s: ", "0xFF<<20"
/*
will output to the console strings:
> 0x0100 | 256 | 0x0100 | 0x0100 | 0x0100 | 0x0100, 256 | 0x0100 |s: 0x100
> 0xFFFFFFFE | 4294967294 | 0xFFFFFFFE | 0xFFFFFFFE | 0xFFFFFFFE | 0xFFFFFFFE, 4294967294 | 0xFFFFFFFE |s: -2
> 0xFF0000 | 16711680 | 0xFF0000 | 0xFF0000 | 0xFF0000 | 0xFF0000, 16711680 | 0xFF0000 |s: 0xFF0000
> 0xFF000000 | 4278190080 | 0xFF000000 | 0xFF000000 | 0xFF000000 | 0xFF000000, 4278190080 | 0xFF000000 |s: 0xFF<<24
> 0xFF00000 | 267386880 | 0xFF00000 | 0xFF00000 | 0xFF00000 | 0xFF00000, 267386880 | 0xFF00000 |s: 0xFF<<20
*/

;; testing error reporting
    DISPLAY
    DISPLAY /X, 1
    DISPLAY /H 1
    DISPLAY ))((%*%!@)
