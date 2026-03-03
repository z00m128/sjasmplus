    ORG $4000
    DEFINE FULL part1? _ part2? _ .x    ; glue parts together with .x suffix
    MACRO  ExampleMacro part1?, part2?
        ld hl,FULL
    ENDM
    DEFINE part2? "global def"          ; can be overshadowed by macro argument
    ; can't be done ahead of MACRO definition in this case
    ; it would substitute macro argument name in definition with quoted string

    ExampleMacro forward, Label
    ; emits `ld hl,FULL` which is further processed by substitutions:
    ; -> `ld hl,part1? _ part2? _ .x` define FULL applied
    ; -> `ld hl,forward _ Label _ .x` args applied, `_` becomes glue operators
    ; -> `ld hl,forwardLabel.x` final line to be parsed
    ; In pass 1 this evaluates to `ld hl,0`, forwardLabel.x is not known yet
    ; In pass 2 and 3 the symbol `forwardLabel.x` has value $4003

forwardLabel.x:         ; label to be forward-referenced from within macro
    DB part2?           ; "global def" string emitted here (not `Label`)
