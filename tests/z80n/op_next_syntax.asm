    OPT --zxnext=cspect --syntax=af
    ORG     $0405
label:
    ; test *OTHER* syntax of various instructions
    ; (only variants, multi-arguments and error messages)

    swapnib a                       ; #ED23
    swapnib b : swapnib 5 : swapnib label : swapnib a,,a        ; syntax errors

    mirror a                        ; #ED24
    mirror b : mirror 5 :  mirror label : mirror a,,a           ; syntax errors

    test label                      ; #ED2705
    test : test a : test b : test 5,,5                          ; syntax errors

    mul de : mul                    ; #ED30 (w/o arguments shows "warning: Fake")
    mul h,l : mul hl : mul 5 : mul label : mul d,e,,d,e         ; syntax errors

    add hl,a,,de,a,,bc,a            ; #ED31 ED32 ED33
    add hl,$102,,de,$304,,bc,$506   ; #ED340201 ED350403 ED360605

    push $102,,label                ; #ED8A0102 ED8A0405

    outinb a : outinb 5 : outinb label                          ; syntax errors

    nextreg $04,$05,,$03,a          ; #ED910405 ED9203
    nextreg $0E,b,,a,$0F                                        ; syntax errors

    pixeldn hl                      ; #ED93
    pixeldn de : pixeldn hl,,hl                                 ; syntax errors

    pixelad hl                      ; #ED94
    pixelad de : pixelad hl,,hl                                 ; syntax errors

    setae a : setae 5 : setae label                             ; syntax errors

    jp      [c]                                                 ; syntax errors
