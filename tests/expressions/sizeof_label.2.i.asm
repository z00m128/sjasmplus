; design based on notes in Issue #16: https://github.com/z00m128/sjasmplus/issues/16
; expected size of machine code: 4 ahead of ORG, 2 after

;;; nested include - SIZEOF "unfriendly" one, should cause boundary for parent file

Inc2Label1:     db      "<In2"

;;; hard boundary also for parent files (reports any open parent ones as errors)
            ORG     $2345

.loc1:          db      "!>"

            ASSERT 4 == SIZEOF(Inc2Label1)
            ASSERT 2 == SIZEOF(.loc1)       ; EOF boundary (== end of include)
