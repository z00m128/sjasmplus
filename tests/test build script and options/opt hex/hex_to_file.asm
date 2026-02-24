    ; --hex option test (main focus), creates file: "hex_to_file.raw"
    ORG     $1234
    DB      "HEX only\n"
start:
    DB      "per 16 bytes\n"
    ORG     $3456
    DB      "change adr by ORG\n"
    di                  ; try some instructions
    ld      hl,$ABCD
    jr      $

    END     start       ; set start address also for --hex record
