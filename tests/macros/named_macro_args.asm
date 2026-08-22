    OUTPUT "named_macro_args.bin"

    MACRO LOAD_XY x, y
        DB x, y
    ENDM

    ; classic positional call still works
    LOAD_XY 2, 3

    ; named arguments, in declaration order
    LOAD_XY x=4, y=5

    ; named arguments, in any order
    LOAD_XY y=7, x=6

    ; spaces around '=' are allowed
    LOAD_XY  x = 8 ,  y = 9

    ; single argument macro
    MACRO ONE val
        DB val
    ENDM

    ONE val=10

    ; named value may itself contain an '=' inside a delimiter
    MACRO TEXT s
        DB s
    ENDM

    TEXT s=<"a=b">

    ; --- error cases ---

    LOAD_XY x=1, z=2        ; unknown argument name
    LOAD_XY x=1, x=2        ; duplicate argument name
    LOAD_XY x=1             ; missing argument 'y'
    LOAD_XY 1, y=2          ; positional first then named: not allowed
    LOAD_XY x=1, 5          ; named first then positional: not allowed

    ; value re-contains the parameter name -> macro substitution loops -> error
val: ONE <val=$>
    ONE <val=val=$>
    ONE val=<val=$>
    ONE val=val=$

    MACRO NONE_ARG
        ; for sake of completeness to verify arg name parser in "edge case" (empty arg list definition)
    ENDM
    NONE_ARG
    NONE_ARG "unexpected value"
    NONE_ARG unexpected_value = "???"
