// include file for dir_end3.a80
        ld      bc,verifyLabel      ; label from first file
        ld      de,verifyLabelFrom_dir_end3.a80

        ; do not END here : END : not here */ : END
        /* END : END : not even in // : END : block comment */ nop ; this one is LIVE
    // : /* END : END : */ : END // END : END
        xxx     ; MACRO from dir_end1.a80
