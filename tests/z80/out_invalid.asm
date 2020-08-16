    out (c),1                   ; "illegal" error, only "0" is valid
    out (c),0                   ; "warning" about `out (c),0` being unstable
    out (c),0                   ; ok ; suppressed warning

    ASSERT 0==__ERRORS__        ; this assert should fail
    ASSERT 0==__WARNINGS__      ; this assert should fail

    ; update these asserts when editing the file, to make it pass
    ASSERT 1==__WARNINGS__
    ASSERT 3==__ERRORS__
