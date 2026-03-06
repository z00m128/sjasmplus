; produce various kinds of output files (which are expected to be deleted by --cleanonerror)
; these are considered "primary" targets of assembling and they are tracked for removal

; although if the source is only amending existing file (OUTPUT/SAVETAP/...), it is not removed
; (ie. only freshly created output files are tracked and removed)

        OUTPUT "cleanonerror.out"
        EMPTYTAP "cleanonerror.tap"
        EMPTYTRD "cleanonerror.trd"

        DEVICE AMSTRADCPC464 : ORG $1200 ; fileorg-ok
        di
        halt
        SAVECPCSNA "cleanonerror.cpcsna", $1200
        SAVECDT EMPTY "cleanonerror.cdt"

        DEVICE AMSTRADCPCPLUS
        di
        halt
        SAVECPR "cleanonerror.cpr", 1

        DEVICE ZXSPECTRUMNEXT : ORG $8000 ; fileorg-ok
        di
        halt
        SAVENEX OPEN "cleanonerror.nex", $8000, $9000
        SAVENEX AUTO
        SAVENEX CLOSE

        DEVICE ZXSPECTRUM48, $FEFF : ORG $FF00 ; fileorg-ok
        di
        halt
        SAVESNA "cleanonerror.sna", $FF00
        SAVETAP "cleanonerror.2.tap", $FF00
        SAVEBIN "cleanonerror.bin", $FF00, 2
        SAVE3DOS "cleanonerror.3os", $FF00, 2
        SAVEAMSDOS "cleanonerror.ams", $FF00, 2
        SAVEDEV "cleanonerror.dev", $$, $3F00, 2
        SAVEHOB "cleanonerror.hob", "myfile.C", $FF00, 2

; SLD file, breakpoints, symbols dumps/export and similar files are
; considered "secondary" targets and not tracked + removed

; final syntax error to make the build failure
        ASSERT 0, "binaries should be cleaned"
