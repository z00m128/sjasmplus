    DEFARRAY    myarray 'A', 'B', 'C'
    DB myarray[#], myarray[0], myarray[myarray[#] - 1]
    DEFARRAY+   myarray 'D', 'E', 'F'
    DB myarray[#], myarray[3], myarray[myarray[#]-1]

iii = 0
    DUP myarray[#]
iii = iii + 1   DB  myarray[iii]    ; substitution happens first (before label++ parsing)
    EDUP
