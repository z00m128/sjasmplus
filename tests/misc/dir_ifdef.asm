;; use options from dir_ifdef.options: "-DextDef1 -DextDef2=X" to assemble this

;; This must generate syntax errors
    IFDEF
    IFNDEF

;; Rest of code must compile without errors

    DEFINE defined

    IFDEF undefined
    skip
    ELSE
    halt
    ENDIF

    IFNDEF undefined
    halt
    ELSE
    skip
    ENDIF

    IFDEF defined
    halt
    ELSE
    skip
    ENDIF

    IFNDEF defined
    skip
    ELSE
    halt
    ENDIF

;; check the externally defined ones from command line: -DextDef1 -DextDef2=X

    IFDEF extDef1
    halt
    ELSE
    skip
    ENDIF

    IFNDEF extDef1
    skip
    ELSE
    halt
    ENDIF

    IFDEF extDef2
    halt
    ELSE
    skip
    ENDIF

    IFNDEF extDef2
    skip
    ELSE
    halt
    ENDIF

;; check nesting

    IFDEF defined   ; true on top level

        IFDEF extDef1
        halt
        ELSE
        skip
        ENDIF

        IFNDEF extDef1
        skip
        ELSE
        halt
        ENDIF

    ELSE    ; false on top level

        IFDEF extDef1
        almost halt
        ELSE
        skip
        ENDIF

        IFNDEF extDef1
        skip
        ELSE
        almost halt
        ENDIF

    ENDIF

    IFNDEF defined  ; false on top level

        IFDEF extDef1
        almost halt
        ELSE
        skip
        ENDIF

        IFNDEF extDef1
        skip
        ELSE
        almost halt
        ENDIF

    ELSE    ; true on top level

        IFDEF extDef1
        halt
        ELSE
        skip
        ENDIF

        IFNDEF extDef1
        skip
        ELSE
        halt
        ENDIF

    ENDIF
