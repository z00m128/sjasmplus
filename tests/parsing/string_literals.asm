    ; new string-suffixes to add zero byte or set high bit of last char
    DB ""Z
    DB ''Z
    DB "a"Z
    DB 'a'Z
    DB "abcdef"Z
    DB 'abcdef'Z
    DB ""C          ; error - can't patch empty string
    DB ''C          ; error - can't patch empty string
    DB "a"C
    DB 'a'C
    DB "abcdef"C
    DB 'abcdef'C
    DB "ab"Z,"cd"C,"e"Z

    ; test max-size inputs (128 chars), regular + C will work, Z should fail
    DB "0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE."

    DB "0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE."C

    DB "0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE.0123456789ABCDE."Z ; error

    ; this works in any expression, if you really want to complicate your life
    DZ "A"Z         ; double zero
    DC "ab"C        ; technically patched twice, but to same value
    ld hl,"A"Z      ; ld hl,$4100
    ld a,'A'C       ; ld a,$C1

    ; DC / DZ directives and their pecularities
    DC  'A'         ; not patched, special case of sjasmplus treating this as *character*, not *string*
    DC  "A"
    DC  'AB'
    DC  "AB"

    DZ 1,2,3        ; will add only single zero at end
    DC "01","23"    ; will patch both strings with |$80
