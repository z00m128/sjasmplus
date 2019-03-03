; This is trivial ZX Spectrum Next example (turning ULA-white into transparent cyan).
; Added to test the CI build script "test_folder_examples.sh" :
; # filenames containing spaces
; # .options file provided

DEVICE zxspectrum48

    org     $8000
Start:
    ; set global transparency to ULA-white && set transparency fallback to light cyan
    nextreg $14, %10110110, $4A, $1F
.loopyLoop:
    jr      .loopyLoop

SAVESNA "E_Next.sna", Start