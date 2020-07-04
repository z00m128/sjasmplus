    ; lua can emit more than 64ki of bytes in single "step", overruning the internal
    ; byte list (used to render bytes into listing)
    lua allpass
        for i = 0, 66000, 1 do
            sj.add_byte(0)
        end
    endlua

    ; after the buffer is overrun, the "..." is shown in the listing

    ; this is not verified by the automated test, test just checks if the sjasmplus
    ; does not crash, but manually the correct listing output was checked.