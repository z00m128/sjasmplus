m1      MACRO   arg1?
            DEFINE __check__ arg1?
            LUA
                x = sj.get_define("__check__")
                if x ~= "1,2" then
                    sj.error("["..x.."] differs from expected [1,2]")
                end
            ENDLUA
            UNDEFINE __check__
        ENDM

m2      MACRO   arg1?
            DEFINE __check__ arg1?
            LUA
                x = sj.get_define("__check__")
                if x ~= " 3,4 " then
                    sj.error("["..x.."] differs from expected [ 3,4 ]")
                end
            ENDLUA
            UNDEFINE __check__
        ENDM

/* ok */    m1  <1,2>
/* ok */    m1  <1,2> ; comment
/* err */   m1  < 1,2 >
/* err */   m1  < 1,2 > ; comment

/* err */   m2  <3,4>
/* err */   m2  <3,4> ; comment
/* ok */    m2  < 3,4 >
/* ok */    m2  < 3,4 > ; comment

        ASSERT 4 == __ERRORS__
