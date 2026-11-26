; test valid limits of source line size vs DB internal limit of values parsed
; at the moment of adding this test the internal source line limits were 2048 letters to read
; expanded to 4096 during substitutions, and DB limit was 256 values.
    DEVICE ZXSPECTRUM48
    ORG 0

    ; 256 numeric values, using seven source characters per value
    DB 100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115,   100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115
    ASSERT $ == 256

    ; the same capacity after DEFINE expansion
    DEFINE _values16 100,   101,   102,   103,   104,   105,   106,   107,   108,   109,   110,   111,   112,   113,   114,   115
    DEFINE _values64 _values16,   _values16,   _values16,   _values16
    DB _values64,   _values64,   _values64,   _values64
    ASSERT $ == 512

    DEFINE _s16 "0123456789ABCDEF"
    DEFINE _s32 _s16 .. _s16
    DEFINE _s64 _s32 .. _s32
    DEFINE _s128 _s64 .. _s64

    ; 255 characters plus the literal's Z suffix fill the parser capacity
    DB _s128 .. _s64 .. _s32 .. _s16 .. "0123456789ABCDE"Z
    ASSERT $ == 768 && {B $-2} == 'E' && {B $-1} == 0

    ; high-bit termination patches the final byte of a full-capacity body
    DC _s128 .. _s128
    ASSERT $ == 1024 && {B $-1} == ('F' | $80)

    ; ABYTEZ adds its own terminator after 256 offset-adjusted payload bytes
    ABYTEZ 1 _s128 .. _s128
    ASSERT $ == 1281 && {B $-257} == '1' && {B $-2} == 'G' && {B $-1} == 0

    ; Pascal length includes numeric operands as well as string bytes
    DP _s128 .. _s64 .. _s32 .. _s16 .. "0123456789ABCD", 0
    ASSERT $ == 1537 && {B $-256} == 255 && {B $-1} == 0

    SAVEBIN "byte_limits.bin", 0, $