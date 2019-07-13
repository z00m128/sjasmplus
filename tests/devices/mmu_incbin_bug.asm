    DEVICE ZXSPECTRUMNEXT
    MMU 0 n, 0
    ORG 0x1F00
    ; include 0x2200 bytes
    ; => should include up 0x100 bytes into page 0
    ; => then 0x2000 bytes into page 1
    ; => and final 0x100 bytes into page 2
    INCBIN "mmu_incbin_bug_data.i.asm"
    ASSERT 0x100 == $ && 2 == $$

    ; include another 0x2200 bytes, starting from 0x100 in page 2
    ; => should include up 0x1F00 bytes into page 2
    ; => then 0x300 bytes into page 3 (failed in v1.13.2)
    INCBIN "mmu_incbin_bug_data.i.asm"
    ASSERT 0x300 == $ && 3 == $$
