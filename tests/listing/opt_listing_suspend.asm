    scf     ; by default listing is ON
    OPT push listoff    ; remember current state, switch listing off
    DZ  "not listed"
    OPT pop             ; restoring original state
    DZ  "LISTED"
    OPT listoff
    DZ  "not listed 2"
    OPT liston          ; explicit ON
    DZ  "LISTED 2"
    OPT listoff : DZ "not listed 3" : OPT liston : DZ "LISTED 3"    ; single line OFF/ON

    ; nested listing OFF by suggested push+pop technique
    OPT push listoff    ; switch listing off twice
    OPT push listoff
    DZ  "not listed 4"
    OPT pop
    DZ  "not listed 5"
    OPT pop
    DZ  "LISTED 4+5"
