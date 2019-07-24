    ;mulub   a,a         ; #EDF9    - not guaranteed to work properly, sjasmplus doesn't support it
    mulub   a,b         ; #EDC1
    mulub   a,c         ; #EDC9
    mulub   a,d         ; #EDD1
    mulub   a,e         ; #EDD9
    ;mulub   a,h         ; #EDE1    - not guaranteed
    ;mulub   a,l         ; #EDE9    - not guaranteed
    muluw   hl,bc       ; #EDC3
    ;muluw   hl,de       ; #EDD3    - not guaranteed
    ;muluw   hl,hl       ; #EDE3    - not guaranteed
    muluw   hl,sp       ; #EDF3

    ;; syntax variants
    mulub   b
    muluw   bc

    ;; invalid instr. variants
    mulub   a
    muluw   hl
