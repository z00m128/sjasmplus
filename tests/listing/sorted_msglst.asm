; verify the symbol table appended by --msg=lstlab is sorted (same as --lstlab=sort)
    ORG $8000
FirstLabel:
SecondLabel:
LastLabel:      ; should be in the middle of the table after being sorted
