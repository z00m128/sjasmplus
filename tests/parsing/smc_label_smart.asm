;  The syntax `<label>+*[:]` is meant to be used as self-modify-code marker only,
; with the assembler automatically suggesting most meaningful offset.

    OPT --zxnext    ; enable also extra instructions of ZX Next
    org $8000
    ; valid extra syntax (colon is optional)
lA+*    and 1
lB+*:   and 2
lC+*:   and 3 : nop

    ; test all valid instructions of Z80 and Z80N
    ; (and I don't care about testing invalid ones, they *should* fail, but it's not tested)
; $0x opcodes
    ASSERT $8007+1 == _ld_bc_i
_ld_bc_i+*:     ld      bc,$1234
    ASSERT $800A+1 == _ld_b_i
_ld_b_i+*:      ld      b,$56
    ASSERT $800C+1 == _ld_c_i
_ld_c_i+*:      ld      c,$56
; $1x opcodes
_djnz+*:        djnz    $           : ASSERT $800E+1 == _djnz
    ASSERT $8010+1 == _ld_de_i
_ld_de_i+*:     ld      de,$1234
    ASSERT $8013+1 == _ld_d_i
_ld_d_i+*:      ld      d,$56
_jr+*:          jr      $           : ASSERT $8015+1 == _jr
    ASSERT $8017+1 == _ld_e_i
_ld_e_i+*:      ld      e,$56
; $2x opcodes
_jr_nz+*:       jr      nz,$        : ASSERT $8019+1 == _jr_nz
    ASSERT $801B+1 == _ld_hl_i
_ld_hl_i+*:     ld      hl,$1234
    ASSERT $801E+1 == _ld_m_hl
_ld_m_hl+*:     ld      ($1234),hl
    ASSERT $8021+1 == _ld_h_i
_ld_h_i+*:      ld      h,$56
_jr_z+*:        jr      z,$         : ASSERT $8023+1 == _jr_z
    ASSERT $8025+1 == _ld_hl_m
_ld_hl_m+*:     ld      hl,($1234)
    ASSERT $8028+1 == _ld_l_i
_ld_l_i+*:      ld      l,$56
; $3x opcodes
_jr_nc+*:       jr      nc,$        : ASSERT $802A+1 == _jr_nc
    ASSERT $802C+1 == _ld_sp_i
_ld_sp_i+*:     ld      sp,$1234
    ASSERT $802F+1 == _ld_m_a
_ld_m_a+*:      ld      ($1234),a
    ASSERT $8032+1 == _ld_memhl_i
_ld_memhl_i+*:  ld      (hl),$56
_jr_c+*:        jr      c,$         : ASSERT $8034+1 == _jr_c
    ASSERT $8036+1 == _ld_a_m
_ld_a_m+*:      ld      a,($1234)
    ASSERT $8039+1 == _ld_a_i
_ld_a_i+*:      ld      a,$56
; $Cx opcodes
    ASSERT $803B+1 == _jp_nz
_jp_nz+*:       jp      nz,$
    ASSERT $803E+1 == _jp
_jp+*:          jp      $
    ASSERT $8041+1 == _call_nz
_call_nz+*:     call    nz,$
    ASSERT $8044+1 == _add_i
_add_i+*:       add     a,$56
    ASSERT $8046+1 == _jp_z
_jp_z+*:        jp      z,$
    ASSERT $8049+1 == _call_z
_call_z+*:      call    z,$
    ASSERT $804C+1 == _call
_call+*:        call    $
    ASSERT $804F+1 == _adc_i
_adc_i+*:       adc     a,$56
; $Dx opcodes
    ASSERT $8051+1 == _jp_nc
_jp_nc+*:       jp      nc,$
Xout_n+*:       out     ($56),a     ; not supported
    ASSERT $8056+1 == _call_nc
_call_nc+*:     call    nc,$
    ASSERT $8059+1 == _sub_i
_sub_i+*:       sub     $56
    ASSERT $805B+1 == _jp_c
_jp_c+*:        jp      c,$
Xin_n+*:        in      a,($56)     ; not supported
    ASSERT $8060+1 == _call_c
_call_c+*:      call    c,$
    ASSERT $8063+1 == _sbc_i
_sbc_i+*:       sbc     a,$56
; $Ex opcodes
    ASSERT $8065+1 == _jp_po
_jp_po+*:       jp      po,$
    ASSERT $8068+1 == _call_po
_call_po+*:     call    po,$
    ASSERT $806B+1 == _and_i
_and_i+*:       and     $56
    ASSERT $806D+1 == _jp_pe
_jp_pe+*:       jp      pe,$
    ASSERT $8070+1 == _call_pe
_call_pe+*:     call    pe,$
    ASSERT $8073+1 == _xor_i
_xor_i+*:       xor     $56
; $Fx opcodes
    ASSERT $8075+1 == _jp_p
_jp_p+*:        jp      p,$
    ASSERT $8078+1 == _call_p
_call_p+*:      call    p,$
    ASSERT $807B+1 == _or_i
_or_i+*:        or      $56
    ASSERT $807D+1 == _jp_m
_jp_m+*:        jp      m,$
    ASSERT $8080+1 == _call_m
_call_m+*:      call    m,$
    ASSERT $8083+1 == _cp_i
_cp_i+*:        cp      $56

; $ED regular Z80
    ASSERT $8085+2 == _ld_m_bc
_ld_m_bc+*:     ld      ($1234),bc
    ASSERT $8089+2 == _ld_bc_m
_ld_bc_m+*:     ld      bc,($1234)
    ASSERT $808D+2 == _ld_m_de
_ld_m_de+*:     ld      ($1234),de
    ASSERT $8091+2 == _ld_de_m
_ld_de_m+*:     ld      de,($1234)
    ASSERT $8095+2 == _ld_m_sp
_ld_m_sp+*:     ld      ($1234),sp
    ASSERT $8099+2 == _ld_sp_m
_ld_sp_m+*:     ld      sp,($1234)

; IX prefix $DD 2x opcodes
    ASSERT $809D+2 == _ld_ix_i
_ld_ix_i+*:     ld      ix,$1234
    ASSERT $80A1+2 == _ld_m_ix
_ld_m_ix+*:     ld      ($1234),ix
    ASSERT $80A5+2 == _ld_ixh_i
_ld_ixh_i+*:    ld      ixh,$56
    ASSERT $80A8+2 == _ld_ix_m
_ld_ix_m+*:     ld      ix,($1234)
    ASSERT $80AC+2 == _ld_ixl_i
_ld_ixl_i+*:    ld      ixl,$56
; IX prefix $DD 3x opcodes
Xinc_memix+*:   inc     (ix+$78)    ; not supported
Xdec_memix+*:   dec     (ix+$78)    ; not supported
    ASSERT $80B5+3 == _ld_memix_i
_ld_memix_i+*:  ld      (ix+$78),$56
; IX prefix other only having displacement => not supported (not testing ALL of them, just few)
Xld_b_memix+*:  ld      b,(ix+$78)  ; not supported
Xld_memix_b+*:  ld      (ix+$78),b  ; not supported
Xld_h_memix+*:  ld      h,(ix+$78)  ; not supported
Xld_memix_h+*:  ld      (ix+$78),h  ; not supported
Xld_a_memix+*:  ld      a,(ix+$78)  ; not supported
Xld_memix_a+*:  ld      (ix+$78),a  ; not supported
Xadd_memix+*:   add     a,(ix+$78)  ; not supported
Xadc_memix+*:   adc     a,(ix+$78)  ; not supported
Xxor_memix+*:   xor     (ix+$78)    ; not supported
; IX bit instructions $DD CB ...
Xrlc_memix+*:   rlc     (ix+$78)    ; not supported
Xrrc_memix+*:   rrc     (ix+$78)    ; not supported
Xrl_memix+*:    rl      (ix+$78)    ; not supported
Xrr_memix+*:    rr      (ix+$78)    ; not supported
Xsla_memix+*:   sla     (ix+$78)    ; not supported
Xsra_memix+*:   sra     (ix+$78)    ; not supported
Xbit0_memix+*:  bit     0,(ix+$78)  ; not supported
Xres1_memix+*:  res     1,(ix+$78)  ; not supported
Xset2_memix+*:  set     2,(ix+$78)  ; not supported

; IY prefix $DD 2x opcodes
    ASSERT $80F8+2 == _ld_iy_i
_ld_iy_i+*:     ld      iy,$1234
    ASSERT $80FC+2 == _ld_m_iy
_ld_m_iy+*:     ld      ($1234),iy
    ASSERT $8100+2 == _ld_iyh_i
_ld_iyh_i+*:    ld      iyh,$56
    ASSERT $8103+2 == _ld_iy_m
_ld_iy_m+*:     ld      iy,($1234)
    ASSERT $8107+2 == _ld_iyl_i
_ld_iyl_i+*:    ld      iyl,$56
; IY prefix $DD 3x opcodes
Xinc_memiy+*:   inc     (iy+$78)    ; not supported
Xdec_memiy+*:   dec     (iy+$78)    ; not supported
    ASSERT $8110+3 == _ld_memiy_i
_ld_memiy_i+*:  ld      (iy+$78),$56
; IY prefix other only having displacement => not supported (not testing ALL of them, just few)
Xld_b_memiy+*:  ld      b,(iy+$78)  ; not supported
Xld_memiy_b+*:  ld      (iy+$78),b  ; not supported
Xld_h_memiy+*:  ld      h,(iy+$78)  ; not supported
Xld_memiy_h+*:  ld      (iy+$78),h  ; not supported
Xld_a_memiy+*:  ld      a,(iy+$78)  ; not supported
Xld_memiy_a+*:  ld      (iy+$78),a  ; not supported
Xadd_memiy+*:   add     a,(iy+$78)  ; not supported
Xadc_memiy+*:   adc     a,(iy+$78)  ; not supported
Xxor_memiy+*:   xor     (iy+$78)    ; not supported
; IY bit instructions $DD CB ...
Xrlc_memiy+*:   rlc     (iy+$78)    ; not supported
Xrrc_memiy+*:   rrc     (iy+$78)    ; not supported
Xrl_memiy+*:    rl      (iy+$78)    ; not supported
Xrr_memiy+*:    rr      (iy+$78)    ; not supported
Xsla_memiy+*:   sla     (iy+$78)    ; not supported
Xsra_memiy+*:   sra     (iy+$78)    ; not supported
Xbit0_memiy+*:  bit     0,(iy+$78)  ; not supported
Xres1_memiy+*:  res     1,(iy+$78)  ; not supported
Xset2_memiy+*:  set     2,(iy+$78)  ; not supported

; $ED extended Z80N
    ASSERT $8153+2 == _test_i
_test_i+*:      test    $56
    ASSERT $8156+2 == _add_hl_i
_add_hl_i+*:    add     hl,$1234
    ASSERT $815A+2 == _add_de_i
_add_de_i+*:    add     de,$1234
    ASSERT $815E+2 == _add_bc_i
_add_bc_i+*:    add     bc,$1234
Xpush_i+*:      push    $1234       ; not supported
    ASSERT $8166+3 == _nextreg_i
_nextreg_i+*:   nextreg $AA,$56
Xnextreg_a+*:   nextreg $AA,a       ; not supported

;---------------------------------------------------------------------------------------------------------
    ; syntax errors ('*' only)
lD+*0   and 4
lE+*a   and 5
lDb+*0: and 42
lEb+*a: and 52
    ; syntax errors (no minus either)
lF-*    and 6
lG-*:   and 7
    ; error unresolved (no suitable instruction is on the line)
lH+*
lI+*:
lJ+*:   nop
lK+*:   nop : and 8         ; must be first instruction after smc label, not second+

    ; syntax errors, using SMC label in unsupported context
123+*   jr  123B
124+*:  jr  124B

lL+*    MACRO
            nop
        ENDM
        lL

        STRUCT S_TEST
Byte        BYTE    0x12
Smc+*       BYTE    0x34    ; error, can't have SMC
        ENDS

NormalStruct    S_TEST
SmcStruct+*     S_TEST      ; error, can't have SMC

    ; mismatch errors

    ; different position of line while same amount of SMC labels (mismatch in pass 3)
    IF 1 == __PASS__
lM+*:   and 9
    ELSE
lM+*:   and 9               ; mismatch reported here (in pass 3)
    ENDIF

    ; mismatch by swapping order between passes
    IF 1 == __PASS__
lN+*:   and 10
    ENDIF
lO+*    and 11              ; mismatch
    IF 1 < __PASS__
lN+*:   and 10              ; mismatch
    ENDIF
lP+*    and 12              ; precise swap will not damage following label, this may still work (not guaranteed in future versions)

    IF 1 < __PASS__
lQ+*:   and 13              ; mismatch
    ENDIF
lR+*:   and 14              ; but all following correct ones are also mismatched

    ASSERT $8000+1 == lA
    ASSERT $8002+1 == lB
    ASSERT $8004+1 == lC
