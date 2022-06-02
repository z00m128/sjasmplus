--[[
    Lua function providing "inc_text" feature
    for SjASMPlus (https://github.com/z00m128/sjasmplus)
    Author: Reobne (Кузьма Е.) at https://zx-pk.ru forum
    (slightly modified by Ped7g)

    Opens text file, parses it per line, emits text as bytes by default,
    but any line starting with *asm_marker* is assembled (you can define
    label or code with such line, code must be lead with whitespace).

    Call it in every pass of assembling in the ASM file!

    Parameters:
    1 file_name: name of file to open
    2 asm_marker: beginning-of-line marker of ASM line (default ">>")
    3 eol_byte: byte value to emit instead of newline (default 13)
]]
function inc_text(file_name, asm_marker, eol_byte)
    asm_marker = asm_marker or ">>"
    eol_byte = eol_byte or 13
    if not sj.file_exists(file_name) then
        sj.error("[inc_text]: file not found", file_name)
        return
    end
    marker_len = string.len(asm_marker)
    _pl(";; inc_text ;; file \"" .. file_name .. "\", asm_marker \"" .. asm_marker ..
        "\", eol_byte " .. eol_byte)
    for line in io.lines(file_name) do
        if string.sub(line, 1, marker_len) == asm_marker then
            _pl(string.sub(line, marker_len + 1))   -- parse as assembly source line
        else
            for i = 1, string.len(line) do
                sj.add_byte( string.byte(line, i) )
            end
            sj.add_byte(eol_byte)
        end
    end
    _pl(";; inc_text ;; end of file \"" .. file_name .. "\"")
end
