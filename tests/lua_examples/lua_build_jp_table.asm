        ;-----------------------------------------------------------------
        ; idea is from NEO SPECTRUMAN, who was trying to speed up "opcode" jumptable.
        ; implementation of Lua scripts and macros for sjasmplus is from Ped7g
            device zxspectrum48

        ;-----------------------------------------------------------------
        ; example of usage of the produced table (code provided by NEO SPECTRUMAN)
            org     $C000
        ; A = operation (alias "opcode") number 0..255
            ld      l,a                 ;4
            ld      h,high opJpTab      ;7
            ld      h,(hl)              ;7
            jp      (hl)                ;4
                                        ;=22t

        ;-----------------------------------------------------------------
        ; define LUA functions for memory allocations for opcodes functions
        ;
        ; (the ";" ahead of "end" and some "--" is not needed for Lua, but for my text
        ; editor sjasmplus syntax highlight, as it gets confused by lua source)
        ;
        ; Opcodes *must* be allocated in sequence (0,1,2 ...) to avoid large empty
        ; areas in memory, or even running out of memory completely. Also opcode
        ; implementation subroutines must be reasonably short (few bytes, not hundreds)

        lua pass1
            function allocateOpMemory(opcode)
                -- search for free "page" (512B pages starting at opRoutines address)
                freePage = _c("high opRoutines")
                while allocatedPages[freePage] and opcode < allocatedPages[freePage] do
                    freePage = freePage + 2
                    -- +2 to operate over 512 bytes, with 256B pages high opcodes like FE
                    -- may overwrite following page where early opcodes like 01 resides
                ;end
                ; -- remember it for "finishOpAllocate" function
                _G.lastFreePage = freePage
                ; -- free page found, emit it into jump table
                _pc(string.format("org $%04x", _c("opJpTab") + opcode))
                _pc(string.format("db $%02x", freePage))
                ; -- and reset ORG to target memory for opcode function body
                _pc(string.format("org $%04x", freePage*256 + opcode))
                _pl(string.format("opcode_%02x_impl:", opcode))
            ;end    -- ";" to make my Kate editor syntax highlight survive "end" in lua

            function finishOpAllocate()
                assert(_G.lastFreePage, "allocateOpMemory not called yet")
                allocatedPages[_G.lastFreePage] = _c("$ & $1FF")
            ;end

            function setOrgAfterLastAllocated()
                checkPage = _c("high opRoutines")
                while allocatedPages[checkPage] do
                    lastAdr = checkPage*256 + allocatedPages[checkPage]
                    checkPage = checkPage + 2
                ;end
                assert(lastAdr, "no memory was allocated yet")
                _pc(string.format("org $%04x", lastAdr))
            ;end
        endlua

        ;-----------------------------------------------------------------
        ; helper macros to make the lua calls one-liners in asm
        macro allocateOpMemory _opcode?
@__allocateOpMemory_opcode = _opcode?
            lua allpass
                allocateOpMemory(_c("__allocateOpMemory_opcode"))
            endlua
        endm
        macro finishOpAllocate
            lua allpass
                finishOpAllocate()
            endlua
        endm

        ;-----------------------------------------------------------------
        ; global definitions and variables used to generate jump table
        
        ; jump table with "high" bytes of opcode function addresses
opJpTab     equ     $7F00               ; must be 256B aligned, size 256B
        ; opcode functions will go into memory starting from $8000
opRoutines  equ     $8000               ; must be 256B aligned, size dynamic (N * 512)
        ; reset all Lua global variables ahead of each assembling pass
        lua allpass
            allocatedPages = {}     -- reset allocated pages for every pass
            lastFreePage = nil
        endlua

        ;-----------------------------------------------------------------
        ; define opcode functions (builds also jump table and labels like "opcode_a1_impl")

            allocateOpMemory 0
            db      1, 2            ; fake "implementation" (just 1,2,3,4,... byte values)
            finishOpAllocate

            allocateOpMemory 1
            db      3, 4, 5
            finishOpAllocate

            allocateOpMemory 2
            db      6, 7, 8
            finishOpAllocate

            allocateOpMemory 3
            db      9, 10
            finishOpAllocate

            allocateOpMemory 4
            db      11
            finishOpAllocate

            allocateOpMemory 253
            db      12, 13, 14, 15, "this goes over into page $8100..81FF"
            finishOpAllocate

            allocateOpMemory 255
            db      255, 255, 255, 255, 255     ; another going into second half
            finishOpAllocate

            lua allpass
                setOrgAfterLastAllocated()
            endlua

        ;-----------------------------------------------------------------
        ; store result as binary blob for simple verification in hexa editor
            align   512, 0              ; fill also last page to full 512B first
            savebin "lua_build_jp_table.bin", opJpTab, $ - opJpTab
