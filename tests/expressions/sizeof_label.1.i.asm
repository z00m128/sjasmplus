; design based on notes in Issue #16: https://github.com/z00m128/sjasmplus/issues/16
; expected size of machine code: 9

;;; nested include - SIZEOF "friendly" one, should NOT cause boundary for parent file

    MACRO IncMacro1     ; total size: 2
!Inc1Label3:db  "1"
.MyIncL1:   db  "2"

        ASSERT 1 == SIZEOF(.MyIncL1)

    ENDM                ; boundary for macro labels!

Inc1Label1: db  "<"
.locL1:     db  "A"
            IncMacro1   ; +2
.locL2:     db  "BC"
Inc1Label2:
.locL1:     ds  1, "D"  :.:
            db  0       ::
            db  '>'

    ASSERT 1 + 1 + 2 + 2        == SIZEOF(Inc1Label1)
    ASSERT 1 + 2                == SIZEOF(Inc1Label1.locL1)
    ASSERT 2                    == SIZEOF(Inc1Label1.locL2)
    ASSERT 1 + 1                == SIZEOF(Inc1Label3)
    ASSERT 1 + 1                == SIZEOF(Inc1Label2)
    ASSERT 1                    == SIZEOF(Inc1Label2.locL1)
    ASSERT 9                    == $ - Inc1Label1
