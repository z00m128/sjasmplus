    LUA PASS1
        asmpass = 0 + sj.get_define("__PASS__")
        if (1 ~= asmpass) then sj.error("unexpected __PASS__ value", asmpass) end
    ENDLUA
    LUA PASS2
        asmpass = 0 + sj.get_define("__PASS__")
        if (2 ~= asmpass) then sj.error("unexpected __PASS__ value", asmpass) end
    ENDLUA
    LUA PASS3
        asmpass = 0 + sj.get_define("__PASS__")
        if (3 ~= asmpass) then sj.error("unexpected __PASS__ value", asmpass) end
    ENDLUA

    ASSERT $120 == myLab    ; assert is PASS3

    IF 3 == __PASS__
myLab = myLab + $003
        DW  myLab
    ENDIF
    IF 2 == __PASS__
myLab = myLab + $020
    ENDIF
    IF 1 == __PASS__
myLab = $100
    ENDIF

    ASSERT $123 == myLab    ; assert is PASS3
; emitting machine code only in pass3 breaks the coherence of label system
WarningOnLabelBecauseOfBreakingPassCoherence:
