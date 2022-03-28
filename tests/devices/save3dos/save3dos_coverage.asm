    DEFINE FNAME "save3dos_coverage.bin"

        DEVICE NONE

        ; correct syntax, but outside of DEVICE
        SAVE3DOS FNAME, $8765, $4321

        DEVICE ZXSPECTRUM48

        ; invalid syntax of arguments (missing or invalid)
        SAVE3DOS
        SAVE3DOS FNAME
        SAVE3DOS FNAME,
        SAVE3DOS FNAME,1
        SAVE3DOS FNAME,1,
        SAVE3DOS FNAME,1,2,
        SAVE3DOS FNAME,1,2,0,
        SAVE3DOS FNAME,1,2,0,22,
        SAVE3DOS FNAME,1,2,0,22,33,

        ; address/size out of range
        SAVE3DOS FNAME,-1,1
        SAVE3DOS FNAME,0,0
        SAVE3DOS FNAME,$FFFF,2

        ; other invalid values
        SAVE3DOS FNAME,1,2,-1
        SAVE3DOS FNAME,1,2,4
