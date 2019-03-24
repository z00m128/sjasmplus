    ;; test of default output file name in normal input file mode

    ; enable output into default output file ("dir_output_default_name.out")
    SIZE  8     ; should be preserved across first OUTPUT directive
    OUTPUT  "dir_size.bin"
    DB      'Tbin'

    ; should do 2x error, modifying already set old SIZE
    SIZE 16
    SIZE -1

    OUTEND      ; should PAD the file up to 8B

    SIZE -1     ; shouldn't do anything, as OUTEND was supposed to reset SIZE and -1 == -1

    OUTPUT  "dir_size.tap"
    DB      'Ttap'

    SIZE 16     ; make the TAP file 16B

    ; try to end + close OUTPUT by specifying new one
    OUTPUT  "justToEndTap.bin"
