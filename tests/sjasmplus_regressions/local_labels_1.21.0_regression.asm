; reported by Bukem, v1.21.0 fails, v1.20.3 did work

    ORG $1234
    MODULE Vector3D
        MACRO rotationAngle slutAddress, precision
            ld hl,slutAddress ; <-- Label not found: Vector3D.Vector3D.CreateRotationAngleLUT16Bit.SLUT16B90D
            ld e,precision
        ENDM

        IFUSED CreateRotationAngleLUT16Bit
CreateRotationAngleLUT16Bit:
            ld hl,.SLUT16B90D   ; outside of macro it works, only inside macro fails
            rotationAngle .SLUT16B90D, 2
            ld hl,.SLUT16B90D   ; outside of macro it works, only inside macro fails

.SLUT16B90D:
        dh 012345
            ld hl,outside_module
        ENDIF
    ENDMODULE

    call Vector3D.CreateRotationAngleLUT16Bit

outside_module: ; other case

    ASSERT $1234 == Vector3D.CreateRotationAngleLUT16Bit
    ASSERT $123F == Vector3D.CreateRotationAngleLUT16Bit.SLUT16B90D
    ASSERT $1248 == outside_module

; unreported, but related bug in ENDMODULE main label reset
    MODULE mod1
.loc1:
        MODULE mod2
.loc2:
        ENDMODULE
.loc3:
    ENDMODULE
.loc4:

    ASSERT EXIST mod1._.loc1
    ASSERT EXIST mod1.mod2._.loc2
    ASSERT EXIST mod1._.loc3
    ASSERT EXIST _.loc4
