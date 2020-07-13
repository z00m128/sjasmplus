    ORG $1000

    RELOCATE_START

    dw      relocate_count
    dw      relocate_size

; these ahead of RELOCATE_TABLE will refresh the table content to keep it consistent
1:
    jp      1B
    jp      1B
    jp      1F
    jp      1F
1:

; emit intetionally table ahead of labels "3B"/"3F" to break table consistency
    RELOCATE_TABLE

3:                      ; warning about different address (between pass2 and pass3)
    jp      3B          ; warning about inconsistent table (content differs)
    jp      3B          ; second warning is not issued (one only)
    jp      3F          ; forward label test (also two more opportunities to warn if not yet)
    jp      3F
3:                      ; warning about different address (between pass2 and pass3)

; emit final version of the table for comparison
    RELOCATE_TABLE
    RELOCATE_END
