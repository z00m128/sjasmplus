k       = 1
kk      = 2
kiki    = 3
n       = 4
nn      = 5
nini    = 6
        ld      de,k
        ld      de,kk
        ld      de,kiki
        ld      bc,g        ; should be "error label not found"
        ld      bc,m        ; should be "error label not found"
        ld      bc,n
        ld      sp,nn
        ld      hl,nini
