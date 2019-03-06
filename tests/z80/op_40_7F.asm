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
;;; does not work due to this fix: https://github.com/z00m128/sjasmplus/commit/1fea88f3775ec243a55fcc198c57e07f543a9253
;;; the "ld  registers[R1],0" is then expanded to "ld b,0" even when R1 is changing
;;; reverting that commit will break the DUP in DUP assembly files, so at this moment I will rather use LUA to generate this code

;     DEFARRAY registers b, c, d, e, h, l, (hl), a
;
; R1 DEFL 0
;     DUP 8
;         ld  registers[R1],0
; R1 DEFL R1+1
;     EDUP
