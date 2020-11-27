    ORG $100            ; by default listing is ON (full listing)
    DZ  "^ ORG"
    scf
    OPT push listmc     ; remember current state, switch listing to machine-code-only
    ORG $200            ; this should be omitted from listing
    DZ  "NO ORG1"
    ccf
    OPT pop             ; restoring original state
    ORG $300
    DZ  "^ ORG"
    daa
    OPT listmc          ; (there is no explicit way to turn "mc" mode off, only pop/reset!)
    ORG $400            ; this should be omitted from listing
    DZ  "NO ORG2"
    cpl
    OPT reset           ; reset to default state
    ORG $500            ; by default listing is ON (full listing)
    DZ  "^ ORG"
    rra

    ; nested listing adjusting by suggested push+pop technique
    OPT push listmc     ; switch MC listing twice
    OPT push listmc
    ORG $600            ; this should be omitted from listing
    DZ  "NO ORG3"
    rla
    OPT push listoff    ; switch listing completely off temporarily
    ORG $700
    DZ "completely unlisted"
    nop
    OPT pop
    ORG $800            ; this should be omitted from listing
    DZ  "NO ORG4"
    rrca
    OPT pop
    ORG $900            ; this should be omitted from listing
    DZ  "NO ORG5"
    rrca
    OPT pop
    ORG $A00            ; restored to full listing
    DZ  "^ ORG"
    rlca
