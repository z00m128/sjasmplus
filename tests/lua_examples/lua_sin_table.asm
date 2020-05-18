
    ; Sinus table generator - using lua script, because sjasmplus itself does not have
    ; floating point arithmetics and sin/cos/... functions.

    org $8000

sin_table:  ; check listing file to see resulting table bytes
    lua
        -- 256 bytes (index 0..255):
        for i = 0, 255, 1 do

            -- index 0..255 will cover angle range < 0, 2Pi )
            -- i.e. going in sinus values 0 -> +1 -> 0 -> -1 -> 0
            -- For different range, the /128.0 must be modified:
            --     /256.0 is 0..Pi, /512.0 is 0..Pi/2, etc

            -- The *15.5 is amplitude of final values
            -- to be -15 .. +15 (+0.5 for "floor" compensation)
            -- in this example values are signed byte (-15 == 241 == 0xF1)

            sj.add_byte(math.floor(math.sin(math.pi * i / 128.0) * 15.5))
        end
    endlua

