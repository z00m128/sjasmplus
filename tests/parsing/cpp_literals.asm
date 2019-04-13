    ; new syntax did break legacy sources in specific case like "0b800h"
    dw      0b100h, 0xb100

    ; new syntax to define: 0b..|0B.. = binary number (C++ rule), 0q..|0Q.. = octal number
    db      %01011101, 01011101b, 01011101B, 0b01011101, 0B01011101
    db      111q, 111Q, 111o, 111O, 0q111, 0Q111
    ; other old syntax, just verifying syntax highlight of editor and functionality
    db      65, 65d, 65D
    db      $42, #42, 0x42, 0X42, 42h, 42H
111:
    jr      111B        ; temporary labels will steal "binary" highlight up to 3 chars
1001:
    jr      1001B       ; four+ chars: the binary value highlight wins even for label

    ; digit-group ticks tests - fully valid ones
    db      %01'01'11'01, 01'01'11'01b, 01'01'11'01B, 0b01'01'11'01, 0B01'01'11'01
    db      1'1'1q, 1'1'1Q, 1'1'1o, 1'1'1O, 0q1'1'1, 0Q1'1'1
    dw      1'6'961, 1'6'961d, 1'6'961D
    dw      $4'4'43, #4'4'43, 0x4'4'43, 0X4'4'43, 4'4'43h, 4'4'43H

    ; digit-group ticks tests - invalid beginning
    db      %'01'01'11'01
    db      '01'01'11'01B,
    db      0B'01'01'11'01
    db      '1'1'1Q
    db      '1'1'1O
    db      0Q'1'1'1
    dw      '1'6'961
    dw      '1'6'961D
    dw      $'4'4'43
    dw      #'4'4'43
    dw      0X'4'4'43
    dw      '4'4'43H

    ; digit-group ticks tests - invalid end
    db      %01'01'11'01'
    db      01'01'11'01'B
    db      0B01'01'11'01'
    db      1'1'1'Q
    db      1'1'1'O
    db      0Q1'1'1'
    dw      1'6'961'
    dw      1'6'961'D
    dw      $4'4'43'
    dw      #4'4'43'
    dw      0X4'4'43'
    dw      4'4'43'H

    ; digit-group ticks tests - two ticks are invalid too
    db      %0101''1101
    db      0101''1101B
    db      0B0101''1101
    db      11''1Q
    db      11''1O
    db      0Q11''1
    dw      16''961
    dw      16''961D
    dw      $44''43
    dw      #44''43
    dw      0X44''43
    dw      44''43H
