    DEFARRAY    myarray 'A', 'B', 'C'
    DB myarray[#], myarray[0], myarray[myarray[#] - 1]
    DEFARRAY+   myarray 'D', 'E', 'F'
    DB myarray[#], myarray[3], myarray[myarray[#]-1]

iii = -1
    DUP myarray[#]
iii = iii + 1 : DB  myarray[iii]    ; the DEFL symbol will be updated separately because of colon
    EDUP
    ; this used to be without colon, but then colon become mandatory, also "fixing" this test :)
