; This example shows one of possible ways to use multiple STRUCT definitions
; as some kind of C-language-like "union"
;
; The "receive_buffer" is single block of memory large enough to accomodate
; any of the specific "commands"
;
; RECEIVE_BUFFER_HEADER struct defines the initial header shared across all "commands"
; RECEIVE_BUFFER_CMD_READ_REGS, RECEIVE_BUFFER_CMD_CONTINUE, RECEIVE_BUFFER_CMD_PED_TEST
; then define the specific "commands" with their extended fields
;
; finally there is small fake process-like subroutine to show usage of the defined fields

; define the command structures
    STRUCT RECEIVE_BUFFER_HEADER
length              DWORD   0
seq_no              BYTE    0
command             BYTE    0
    ENDS

    STRUCT RECEIVE_BUFFER_CMD_READ_REGS, RECEIVE_BUFFER_HEADER
register_number     BYTE    0
    ENDS

    STRUCT RECEIVE_BUFFER_CMD_CONTINUE, RECEIVE_BUFFER_HEADER
bp1_enable          BYTE    0
bp1_address         WORD    0
bp2_enable          BYTE    0
bp2_address         WORD    0
    ENDS

    STRUCT RECEIVE_BUFFER_CMD_PED_TEST, RECEIVE_BUFFER_HEADER
pattern             BLOCK   256
    ENDS

; find the structure with maximum size to define how long the receive_buffer should be
RB_MAX_SIZE         = RECEIVE_BUFFER_HEADER
RB_MAX_SIZE         = RB_MAX_SIZE >? RECEIVE_BUFFER_CMD_READ_REGS
RB_MAX_SIZE         = RB_MAX_SIZE >? RECEIVE_BUFFER_CMD_CONTINUE
RB_MAX_SIZE         = RB_MAX_SIZE >? RECEIVE_BUFFER_CMD_PED_TEST

; reserve the memory for the receive_buffer (one buffer for all)
    ORG     $8000
receive_buffer      RECEIVE_BUFFER_HEADER
.data               BLOCK   RB_MAX_SIZE - RECEIVE_BUFFER_HEADER, 0

; definie alias labels for "receive_buffer" to access specific-command fields
rb_read_regs    RECEIVE_BUFFER_CMD_READ_REGS = receive_buffer
rb_continue     RECEIVE_BUFFER_CMD_CONTINUE = receive_buffer
rb_ped_test     RECEIVE_BUFFER_CMD_PED_TEST = receive_buffer

; example of usage in code
    ORG     $C000
process_command:
    ld      a,(receive_buffer.command)
    cp      1
    jr      nz,.not_read_regs
    ; CMD_READ_REGS specific code
    ld      a,(rb_read_regs.register_number)
    rst     0
.not_read_regs:
    cp      2
    jr      nz,.not_continue
    ; CMD_CONTINUE specific code
    ld      hl,(rb_continue.bp1_address)
    ld      de,(rb_continue.bp2_address)
    ld      bc,(rb_continue.bp1_enable) ; C = bp1_enable
    ld      a,(rb_continue.bp2_enable)
    ld      b,a                         ; B = bp2_enable
    rst     0
.not_continue:
    ; must be RECEIVE_BUFFER_CMD_PED_TEST then
    ld      hl,rb_ped_test.pattern
    ld      bc,$5B          ; C = ZX Next sprite pattern upload port, B = 0 (256x)
    otir                    ; upload pattern to active pattern slot
    rst     0
