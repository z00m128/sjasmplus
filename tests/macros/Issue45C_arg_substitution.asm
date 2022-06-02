    ORG 'PS'  :   OUTPUT "Issue45C_arg_substitution.bin"

    DEFARRAY arrayIdx 2,3,4,0,1
    DEFARRAY arrayTxt 't0', 't1', 't2', 't3', 't4'

    ; read array items in macro
    MACRO readArray idx?
.ii=-idx?
        db      arrayTxt[ arrayIdx[ idx? + .ii ] ], " "
        db      arrayTxt[ arrayIdx[ .ii + idx? ] ], " "
        DUP idx?
            DEFINE readArrayM_idx? .ii+idx?
            db      arrayTxt[ arrayIdx[ .ii + idx? ] ], " "
            db      arrayTxt[arrayIdx[readArrayM_idx?]], " "
            IF 0 <= readArrayM_idx?
                db      arrayTxt[arrayIdx[readArrayM_idx?]], " "
            ENDIF
            UNDEFINE readArrayM_idx?
.ii=.ii+1
        EDUP
    ENDM

    readArray 4
    db  arrayTxt[arrayIdx[4]], "\n"
