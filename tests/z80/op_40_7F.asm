    OUTPUT "op_40_7F.bin"

    ;;; generate all 40..7F instructions (all common `ld xx,yy` variants + halt)
    LUA ALLPASS
        registers = { 'b', 'c', 'd', 'e', 'h', 'l', '(hl)', 'a' }
        for r1 = 1, #registers do
            for r2 = 1, #registers do
                instruction = 'ld '..registers[r1]..','..registers[r2]
                if (r1 == r2 and registers[r1] == '(hl)') then
                    instruction = 'halt'    -- `ld (hl),(hl)` is `halt`
                end
                _pc(instruction)
            end
        end
    ENDLUA

;;; abandoned work in progress
; while the issue with DEFARRAY was resolved, the next blocker is IF inside DUP...

;     DEFARRAY registers b, c, d, e, h, l, (hl), a
;
; R1 DEFL 0
;     DUP 8
;         IF R1==6
;             halt
;         ELSE
;             ld  registers[R1],registers[R1]
;         ENDIF
; R1 DEFL R1+1
;     EDUP