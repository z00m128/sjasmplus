    ORG     0
    RELOCATE_START
    ; this would trigger warning in regular mode
    ; but low-mem access warning is suppressed in relocation mode
label1:     ld  a,(label1)
    RELOCATE_END
    RELOCATE_TABLE

    ASSERT 0 == __WARNINGS__
