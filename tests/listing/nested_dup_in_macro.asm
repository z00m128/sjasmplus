	MACRO pokus count1,count2,data
        DUP count1
            DUP count2
                db data
            EDUP
        EDUP
	ENDM

	pokus 2,3,#FF
