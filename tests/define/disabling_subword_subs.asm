mac1    MACRO x
            ld c,x
label_x:    dec c
            jr nz,label_x
        ENDM

    DEFINE y 34

    ; by default the substitions work also on subwords
    mac1 12         ; expected "ld c,12" and "label_12"
    ld b,y          ; expected "ld b,34" and "label_34"
label_y:
    dec b
    jr nz,label_y

    ; switch sub-word substitions OFF
    OPT --syntax=s
    mac1 23         ; expected "ld c,23" and "label_x"
    ld b,y          ; expected "ld b,34" and "label_y"
label_y:
    dec b
    jr nz,label_y
