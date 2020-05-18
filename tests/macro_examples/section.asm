    MACRO SECTION sectionName?
        ; init new section to ORG 0
        IFNDEF SECTION_MACRO_KNOWN_SECTION_sectionName?
            DEFINE SECTION_MACRO_KNOWN_SECTION_sectionName?
SECTION_MACRO_LAST_ADR_sectionName? = 0
        ENDIF
        ; if sections are switching, remember position of previous
        IFDEF SECTION_MACRO_PREVIOUS_SECTION
SECTION_MACRO_LAST_ADR_SECTION_MACRO_PREVIOUS_SECTION = $
            UNDEFINE SECTION_MACRO_PREVIOUS_SECTION
        ENDIF
        DEFINE SECTION_MACRO_PREVIOUS_SECTION sectionName?
        ; and set/restore the position of requested section
        ORG SECTION_MACRO_LAST_ADR_sectionName?
    ENDM

    DEVICE ZXSPECTRUM48
; WARNING - the SECTION macro makes sense only with DEVICE virtual memory
; if you do just simple `OUTPUT "section.bin"`, the output will mix all
; sections together.
; To output separate sections without mixing you have to save each section
; separately at the end of assembling from the virtual-device memory.

    SECTION @code       ; use reasonable section names which can form part of label name
        rst     0       ; this will land to address $0000, because no ORG was done
        ORG     $8000   ; at the first usage of SECTION, use ORG to set initial address
@code_start equ   $
        nop             ; `nop` at $8000

    SECTION @data
        ORG     $D000
@data_start equ   $
s1:     DZ      "abc"

    SECTION @code
        ld      hl,s1   ; `ld hl,..` at $8001, s1 = $D000
        ld      bc,s2   ; s2 = $D004

    SECTION @data
s2:     DZ      "efg"
@data_end equ   $

    SECTION @code
        jr      $       ; `jr` at $8007 after `ld bc,..`
@code_end equ   $

    ; save the binary result of sections

    ; saving code (except that `rst 0`)
    SAVEBIN "section.bin", code_start, code_end-code_start
    ; saving strings
    SAVEBIN "section.raw", data_start, data_end-data_start
