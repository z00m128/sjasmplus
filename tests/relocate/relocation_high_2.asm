; test to verify transitions of "relocatable" while using the structs and relocation data generation
    RELOCATE_START HIGH ; definition must be in relocation block too to track default values being rel
        STRUCT RELSTRUCT
ByteRel     BYTE        high rel_label
ByteFix     BYTE        high fix_label
WordRelMsb  WORD        high rel_label
WordFixMsb  WORD        high fix_label
WordRel     WORD        rel_label
WordFix     WORD        fix_label
        ENDS
    RELOCATE_END

        ORG $8800
fix_label:

        ; these are outside of relocation block -> no relocation data in any case
s_1     RELSTRUCT { high fix_label, high rel_label, high fix_label, high rel_label, fix_label, rel_label }
s_2     RELSTRUCT

        DW      relocate_count, relocate_size

        RELOCATE_TABLE      ; provides relocation addresses pointing directly at the high byte

        RELOCATE_TABLE +1   ; provides relocation addresses pointing one byte ahead of the high byte

    RELOCATE_START HIGH
        ORG $1100
rel_label:

        ; check struct defined "at" address
s_at_rel    RELSTRUCT = rel_label + $1000
s_at_fix    RELSTRUCT = fix_label + $1000
            ; these should be relocated
            ld      hl,s_at_rel
            ld      hl,high s_at_rel
            ld      a,high s_at_rel
            ld      hl,s_at_rel.ByteFix
            ld      hl,high s_at_rel.ByteFix
            ld      a,high s_at_rel.ByteFix
            ; these are fixed
            ld      hl,s_at_fix
            ld      hl,high s_at_fix
            ld      a,high s_at_fix
            ld      hl,s_at_fix.ByteFix
            ld      hl,high s_at_fix.ByteFix
            ld      a,high s_at_fix.ByteFix

            ld      hl,RELSTRUCT.ByteFix
            ld      hl,high RELSTRUCT.ByteFix
            ld      a,high RELSTRUCT.ByteFix

        ; check struct with explicit init values (switching relocatable/fixed) - half of them requires relocation
s_init      RELSTRUCT { high fix_label, high rel_label, high fix_label, high rel_label, fix_label, rel_label }

        ; check struct filled with default values (half of them needs relocation)
s_default   RELSTRUCT

        ; this makes no sense? should be treated as norel label
s_at_bogus  RELSTRUCT = high rel_label
            ld      hl,s_at_bogus
            ld      hl,high s_at_bogus
            ld      a,high s_at_bogus
            ld      hl,s_at_bogus.ByteFix
            ld      hl,high s_at_bogus.ByteFix
            ld      a,high s_at_bogus.ByteFix

    RELOCATE_END
