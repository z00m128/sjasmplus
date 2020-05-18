    STRUCT abc
def     BYTE    0
    ENDS

test    abc     1
.local  DB      2       ; expected label is "test.local"

    ld      hl,@test.local

zz:
.ls     abc     3       ; should become "zz.ls.*"
.local2 DB      4       ; should become "zz.local2"
    ld      de,@zz.ls.def
    ld      hl,@zz.local2
