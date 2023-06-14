; VTech Laser 200 (VZ200, Laser 210) example to build binary file header with helper STRUCT
    STRUCT VZ200FILEHEADER
magic   TEXT 4, { "VZF1" }
fname   TEXT 17
ftype   BYTE $F1
start   WORD $8000
    ENDS

    ORG $7B00 - VZ200FILEHEADER
    OUTPUT "vz200_file_header.bin"
    VZ200FILEHEADER { , { "VZFILE" }, , start } // default magic and ftype, custom fname and start
start:
    jp $
    OUTEND
