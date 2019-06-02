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
