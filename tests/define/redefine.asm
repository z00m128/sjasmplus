    OUTPUT "redefine.bin"
    DEFINE+ do_stuff set 4,e
    do_stuff                       ; set 4,e
    DEFINE+ do_stuff set 2,e
    do_stuff                       ; set 2,e
