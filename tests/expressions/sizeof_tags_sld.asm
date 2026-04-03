; design based on notes in Issue #16: https://github.com/z00m128/sjasmplus/issues/16

;;; more tests for `::` and `:.:` tags, if segments are split correctly and SLD generated well

    DEVICE ZXSPECTRUM48

TagTag:
.l: rrd:rld:.:ldi::ldd:di

    ASSERT 4 == SIZEOF(TagTag.l)
    ASSERT 6 == SIZEOF(TagTag)
