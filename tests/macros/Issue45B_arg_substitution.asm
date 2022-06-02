    ORG 'PS'  :   OUTPUT "Issue45B_arg_substitution.bin"

    ; labels expected to emerge from the macro argument substition
TESTD_mydef_TESTD_12345:
mydef_TESTD_12345:

    MACRO def name?, val?
        ld  sp,name?_mydef_name?_val?
        ld  sp,mydef_name?_val?
    ENDM

    def TESTD, 12345

    DEFINE MY_VERSION "1.2.3.4.5"   ; should not clash with sjasmplus _VERSION define
    db "\nMy version: ", MY_VERSION, ", sjasm: ", '0'+_SJASMPLUS, "\n"
    DISPLAY "Sjasmplus version: ", _VERSION

    ; as result of the refactoring happening due to Issue #45 and #35, now array indexing by array should work

    DEFARRAY arrayIdx 2,3,4,0,1
    DEFARRAY arrayTxt 't0', 't1', 't2', 't3', 't4'

    ; simple hard-wired source to access array elements
    db  "\n", arrayTxt[0], " ", arrayTxt[1], " ", arrayTxt[2], " ", arrayTxt[3], " ", arrayTxt[4], "\n"

    ; dynamic array access in DUP repeater
ii=0
    DUP 4
        db  arrayTxt[ii], " "
ii=ii+1
    EDUP
    db  arrayTxt[4], "\n"

    ; hard-wired source to access array elements with extra indirection
    db  arrayTxt[arrayIdx[0]], " ", arrayTxt[arrayIdx[1]], " ", arrayTxt[arrayIdx[2]], " ", arrayTxt[arrayIdx[3]], " "
    db  arrayTxt[arrayIdx[4]], "\n"

    ; dynamic indirect array access in DUP repeater
ii=0
    DUP 4
        db  arrayTxt[arrayIdx[ii]], " "
ii=ii+1
    EDUP
    db  arrayTxt[arrayIdx[4]], "\n"
