	OUTPUT "Issue138_if_vs_label.bin"

	IFDEF BORDER

; ELSE - extra test to check the comment starting at beginning of line is safe

	; v1.18.2 didn't find nested IFNDEF inside false-block, because of label in front of it
	; causing the ELSE to be processed for IFDEF BORDER, making the blocks incorrect:

	; the fix works only for user not using --dirbol, and still fails for temporary labels (the number-ones)
	; (just split it into two lines then, temporary/normal label on one line, IF/IFDEF/ELSE/... on next line)

@Border:	IFNDEF RED
			ld a,1 : out (254),a
		ELSE
			ld a,2 : out (254),a
		ENDIF ; RED

	ENDIF

	DB     0       ; only this zero byte should be emitted for first part

	; do the same block, but with BORDER defined, this should produce the label "Border"
	DEFINE BORDER

	IFDEF BORDER

@Border:	IFNDEF RED
			ld a,1 : out (254),a
		ELSE
			ld a,2 : out (254),a
		ENDIF ; RED

	ENDIF

	; do the same block, but with RED defined
	DEFINE RED

	IFDEF BORDER

@Border2:	IFNDEF RED
			ld a,1 : out (254),a
		ELSE
			ld a,2 : out (254),a
		ENDIF ; RED

	ENDIF

	ASSERT 1 == Border
	ASSERT 5 == Border2
