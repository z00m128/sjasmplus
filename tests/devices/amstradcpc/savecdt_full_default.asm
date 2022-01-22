    DEVICE AMSTRADCPC6128
    ORG $8000 : jr $

    ; snapshot almost empty 6128 with all default values
    SAVECDT FULL "savecdt_full_default.cdt"

    DEVICE AMSTRADCPC464
    ORG $8000 : jr $

    ; snapshot almost empty 464 with all default values (.BIN to not overwrite previous CDT)
    SAVECDT FULL "savecdt_full_default.bin"
