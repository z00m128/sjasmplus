; original test runner script does use `--nologo` always, so it went unnoticed
; the `--msg=lstlab` does actually show the logo ahead of listing.
nn: nop
    ld      a,'warn'
    some_error line
