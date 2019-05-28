    ;; classic syntax (name is after MACRO directive)
    MACRO   classicNameNoArg
        dz  "classic-no-arg\n"
    ENDM
    MACRO   classicNameOneArg arg1?
        db  "classic-1-arg: ", arg1?, "\n", 0
    ENDM
    MACRO   classicNameTwoArg arg1?, arg2?
        db  "classic-2-arg: ", arg1?, arg2?, "\n", 0
    ENDM

    ;; new optional syntax (label on MACRO line is used as macro name)
newNameNoArg    MACRO
                    dz  "new-no-arg\n"
                ENDM
newNameOneArg   MACRO  arg1?
                    db  "new-1-arg: ", arg1?, "\n", 0
                ENDM
newNameTwoArg   MACRO  arg1?, arg2?
                    db  "new-1-arg: ", arg1?, arg2?, "\n", 0
                ENDM

    ;; but label doesn't work over colon separator
Label       :   MACRO nameOrArg?
                    dz  "name-or-arg as name\n"
                ENDM

    ;; DEFL labels also don't work, even without colon
Babel = 2       MACRO nameOrArg2?
                    dz  "name-or-arg2 as name\n"
                ENDM

    OUTPUT "label_as_name.bin"      ; verify defined macros (by checking bin output)
    classicNameNoArg : classicNameOneArg 'a' : classicNameTwoArg 'b', 'c'
    newNameNoArg : newNameOneArg 'a' : newNameTwoArg 'b', 'c'
    nameOrArg? : nameOrArg2?
