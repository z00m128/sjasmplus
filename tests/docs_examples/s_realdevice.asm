    DEVICE ZXSPECTRUM128
    ; in this device the default slot is SLOT 3 with PAGE 0 paged in.

    ORG 32768
StartProg:
    JP $

    DEVICE NONE
    ;do something, if you don't want to corrupt virtual
    ;memory with other code, for example, loader of code.
    ;...code...

    ;return to our virtual device:
    DEVICE ZXSPECTRUM128

    SAVESNA "snapshotname.sna", StartProg
