    ; all of these should fail on i8080
    ; (some will emit damaged machine code of legit i8080 instruction, like LD bc,ix)

    ORG 0x8000
    OPT reset --syntax=f   ; fakes warning ON (should not matter, the error is shown any way)

rl_bc               rl bc
rl_de               rl de
rl_hl               rl hl
rr_bc               rr bc
rr_de               rr de
rr_hl               rr hl
sla_bc              sla bc
sla_de              sla de
sla_hl              sla hl
sll_bc              sll bc
sll_de              sll de
sll_hl              sll hl
sli_bc              sli bc
sli_de              sli de
sli_hl              sli hl
sra_bc              sra bc
sra_de              sra de
sra_hl              sra hl
srl_bc              srl bc
srl_de              srl de
srl_hl              srl hl

ld_bc_bc            ld bc,bc
ld_bc_de            ld bc,de
ld_bc_hl            ld bc,hl
ld_bc_ix            ld bc,ix
ld_bc_iy            ld bc,iy
ld_bc_#hl#          ld bc,(hl)
ld_bc_#ix_nn#       ld bc,(ix+$77)
ld_bc_#iy_nn#       ld bc,(iy+$77)

ld_de_bc            ld de,bc
ld_de_de            ld de,de
ld_de_hl            ld de,hl
ld_de_ix            ld de,ix
ld_de_iy            ld de,iy
ld_de_#hl#          ld de,(hl)
ld_de_#ix_nn#       ld de,(ix+$77)
ld_de_#iy_nn#       ld de,(iy+$77)

ld_hl_bc            ld hl,bc
ld_hl_de            ld hl,de
ld_hl_hl            ld hl,hl
ld_hl_ix            ld hl,ix
ld_hl_iy            ld hl,iy
ld_hl_#ix_nn#       ld hl,(ix+$77)
ld_hl_#iy_nn#       ld hl,(iy+$77)

ld_ix_bc            ld ix,bc
ld_ix_de            ld ix,de
ld_ix_hl            ld ix,hl
ld_ix_ix            ld ix,ix
ld_ix_iy            ld ix,iy

ld_iy_bc            ld iy,bc
ld_iy_de            ld iy,de
ld_iy_hl            ld iy,hl
ld_iy_ix            ld iy,ix
ld_iy_iy            ld iy,iy

ld_#hl#_bc          ld (hl),bc
ld_#hl#_de          ld (hl),de

ld_#ix_nn#_bc       ld (ix+$77),bc
ld_#ix_nn#_de       ld (ix+$77),de
ld_#ix_nn#_hl       ld (ix+$77),hl

ld_#iy_nn#_bc       ld (iy+$77),bc
ld_#iy_nn#_de       ld (iy+$77),de
ld_#iy_nn#_hl       ld (iy+$77),hl

ldi_bc_#hl#         ldi bc,(hl)
ldi_bc_#ix_nn#      ldi bc,(ix+$77)
ldi_bc_#iy_nn#      ldi bc,(iy+$77)

ldi_de_#hl#         ldi de,(hl)
ldi_de_#ix_nn#      ldi de,(ix+$77)
ldi_de_#iy_nn#      ldi de,(iy+$77)

ldi_hl_#ix_nn#      ldi hl,(ix+$77)
ldi_hl_#iy_nn#      ldi hl,(iy+$77)

ldi_#hl#_bc         ldi (hl),bc
ldi_#hl#_de         ldi (hl),de

ldi_#ix_nn#_bc      ldi (ix+$77),bc
ldi_#ix_nn#_de      ldi (ix+$77),de
ldi_#ix_nn#_hl      ldi (ix+$77),hl

ldi_#iy_nn#_bc      ldi (iy+$77),bc
ldi_#iy_nn#_de      ldi (iy+$77),de
ldi_#iy_nn#_hl      ldi (iy+$77),hl

ldi_a_#bc#          ldi a,(bc)
ldi_a_#de#          ldi a,(de)
ldi_a_#hl#          ldi a,(hl)
ldi_b_#hl#          ldi b,(hl)
ldi_c_#hl#          ldi c,(hl)
ldi_d_#hl#          ldi d,(hl)
ldi_e_#hl#          ldi e,(hl)
ldi_h_#hl#          ldi h,(hl)
ldi_l_#hl#          ldi l,(hl)
ldi_a_#ix_nn#       ldi a,(ix+$77)
ldi_b_#ix_nn#       ldi b,(ix+$77)
ldi_c_#ix_nn#       ldi c,(ix+$77)
ldi_d_#ix_nn#       ldi d,(ix+$77)
ldi_e_#ix_nn#       ldi e,(ix+$77)
ldi_h_#ix_nn#       ldi h,(ix+$77)
ldi_l_#ix_nn#       ldi l,(ix+$77)
ldi_a_#iy_nn#       ldi a,(iy+$77)
ldi_b_#iy_nn#       ldi b,(iy+$77)
ldi_c_#iy_nn#       ldi c,(iy+$77)
ldi_d_#iy_nn#       ldi d,(iy+$77)
ldi_e_#iy_nn#       ldi e,(iy+$77)
ldi_h_#iy_nn#       ldi h,(iy+$77)
ldi_l_#iy_nn#       ldi l,(iy+$77)

ldd_a_#bc#          ldd a,(bc)
ldd_a_#de#          ldd a,(de)
ldd_a_#hl#          ldd a,(hl)
ldd_b_#hl#          ldd b,(hl)
ldd_c_#hl#          ldd c,(hl)
ldd_d_#hl#          ldd d,(hl)
ldd_e_#hl#          ldd e,(hl)
ldd_h_#hl#          ldd h,(hl)
ldd_l_#hl#          ldd l,(hl)
ldd_a_#ix_nn#       ldd a,(ix+$77)
ldd_b_#ix_nn#       ldd b,(ix+$77)
ldd_c_#ix_nn#       ldd c,(ix+$77)
ldd_d_#ix_nn#       ldd d,(ix+$77)
ldd_e_#ix_nn#       ldd e,(ix+$77)
ldd_h_#ix_nn#       ldd h,(ix+$77)
ldd_l_#ix_nn#       ldd l,(ix+$77)
ldd_a_#iy_nn#       ldd a,(iy+$77)
ldd_b_#iy_nn#       ldd b,(iy+$77)
ldd_c_#iy_nn#       ldd c,(iy+$77)
ldd_d_#iy_nn#       ldd d,(iy+$77)
ldd_e_#iy_nn#       ldd e,(iy+$77)
ldd_h_#iy_nn#       ldd h,(iy+$77)
ldd_l_#iy_nn#       ldd l,(iy+$77)

ldi_#bc#_a          ldi (bc),a
ldi_#de#_a          ldi (de),a
ldi_#hl#_a          ldi (hl),a
ldi_#hl#_b          ldi (hl),b
ldi_#hl#_c          ldi (hl),c
ldi_#hl#_d          ldi (hl),d
ldi_#hl#_e          ldi (hl),e
ldi_#hl#_h          ldi (hl),h
ldi_#hl#_l          ldi (hl),l
ldi_#ix_nn#_a       ldi (ix+$77),a
ldi_#ix_nn#_b       ldi (ix+$77),b
ldi_#ix_nn#_c       ldi (ix+$77),c
ldi_#ix_nn#_d       ldi (ix+$77),d
ldi_#ix_nn#_e       ldi (ix+$77),e
ldi_#ix_nn#_h       ldi (ix+$77),h
ldi_#ix_nn#_l       ldi (ix+$77),l
ldi_#iy_nn#_a       ldi (iy+$77),a
ldi_#iy_nn#_b       ldi (iy+$77),b
ldi_#iy_nn#_c       ldi (iy+$77),c
ldi_#iy_nn#_d       ldi (iy+$77),d
ldi_#iy_nn#_e       ldi (iy+$77),e
ldi_#iy_nn#_h       ldi (iy+$77),h
ldi_#iy_nn#_l       ldi (iy+$77),l

ldd_#bc#_a          ldd (bc),a
ldd_#de#_a          ldd (de),a
ldd_#hl#_a          ldd (hl),a
ldd_#hl#_b          ldd (hl),b
ldd_#hl#_c          ldd (hl),c
ldd_#hl#_d          ldd (hl),d
ldd_#hl#_e          ldd (hl),e
ldd_#hl#_h          ldd (hl),h
ldd_#hl#_l          ldd (hl),l
ldd_#ix_nn#_a       ldd (ix+$77),a
ldd_#ix_nn#_b       ldd (ix+$77),b
ldd_#ix_nn#_c       ldd (ix+$77),c
ldd_#ix_nn#_d       ldd (ix+$77),d
ldd_#ix_nn#_e       ldd (ix+$77),e
ldd_#ix_nn#_h       ldd (ix+$77),h
ldd_#ix_nn#_l       ldd (ix+$77),l
ldd_#iy_nn#_a       ldd (iy+$77),a
ldd_#iy_nn#_b       ldd (iy+$77),b
ldd_#iy_nn#_c       ldd (iy+$77),c
ldd_#iy_nn#_d       ldd (iy+$77),d
ldd_#iy_nn#_e       ldd (iy+$77),e
ldd_#iy_nn#_h       ldd (iy+$77),h
ldd_#iy_nn#_l       ldd (iy+$77),l

ldi_#hl#_nn         ldi (hl),$44
ldi_#ix_nn#_nn      ldi (ix+$77),$44
ldi_#iy_nn#_nn      ldi (iy+$77),$44

ldd_#hl#_nn         ldd (hl),$44
ldd_#ix_nn#_nn      ldd (ix+$77),$44
ldd_#iy_nn#_nn      ldd (iy+$77),$44

sub_hl_bc           sub hl,bc
sub_hl_de           sub hl,de
sub_hl_hl           sub hl,hl
sub_hl_sp           sub hl,sp

    ; ZXNext section - there are no true regular fakes yet, but some specials
zxn_mul             mul         ; no warning "correct" syntax: "mul d,e" and "mul de"
    ; these definitely should not work in i8080 mode (trying to switch --zxnext is fatal error)
zxn_csp_break       break       ; CSpect emulator only: breakpoint instruction
zxn_csp_exit        exit        ; CSpect emulator only: exit instruction
