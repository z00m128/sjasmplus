    ; coverage: old V1.2 BMP files (with palOffset defined => warning about V1.3)
    DEVICE ZXSPECTRUMNEXT
    SAVENEX OPEN "savenexBmpL.nex"
    ; two warnings, about using paletteOffset with BMP 256x192 and only 10 colors in pal
    SAVENEX SCREEN BMP "savenexBmpL2/savenexBmpL2.bmp", 1, 10
    SAVENEX CLOSE

    ; coverage: palette bmp valid
    SAVENEX OPEN "savenexBmpL.nex"
    SAVENEX PALETTE BMP "savenexBmpL2/savenexBmpL2_256x8.bmp"
    SAVENEX CLOSE

    ; BMP 320x256 open
    SAVENEX OPEN "savenexBmpL.nex"
    SAVENEX SCREEN BMP "savenexBmpL_x256/bg320x256.bmp"
    SAVENEX CLOSE

    ; BMP 640x256 open
    SAVENEX OPEN "savenexBmpL.nex"
    SAVENEX SCREEN BMP "savenexBmpL_x256/airplane.bmp"
    SAVENEX CLOSE

    ; 320/640 screens from BMP: valid + forced V1.2 error
    SAVENEX OPEN "savenexBmpL.nex", 0, $FE00, 0, 2
    SAVENEX SCREEN BMP "savenexBmpL_x256/bg320x256.bmp"
    SAVENEX CLOSE
    SAVENEX OPEN "savenexBmpL.nex", 0, $FE00, 0, 2
    SAVENEX SCREEN BMP "savenexBmpL_x256/airplane.bmp"
    SAVENEX CLOSE
