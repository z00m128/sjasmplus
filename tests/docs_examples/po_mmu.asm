    DEVICE ZXSPECTRUM128 : LABELSLIST "po_mmu.lbl"  ; to check label pages
    MMU 1 3, 5      ; maps slots 1, 2, 3 with pages 5, 6, 7
    ORG 0xBFFF
label1_p6: scf      ; last byte of page 6 (in slot 2)
label2_p7: scf      ; first byte of page 7 (in slot 3)

    MMU 3 e, 0      ; page 0 into slot 3, write beyond slot will cause error
    ORG 0xFFFF
    ld  a,1         ; error: Write outside of memory slot: 65536 (65536 = address outside)

    MMU 3 n, 1      ; page 1 into slot 3, make it wrap + map next page automatically
    ORG 0xFFFF      ; ! also the $ address was truncated by MMU from $10001 to $0001 !
label3_p1: scf      ; last byte of page 1, then wrapping back to 0xC000 with page 2
label4_p2: scf      ; first byte of page 2 at 0xC000
