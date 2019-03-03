;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test case for STRUCT with -1 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        OUTPUT  struct_test.bin

        STRUCT  str
member0 db      0
member1 db      1
member2 dw      2
member3 d24     3
member4 dd      4
        ENDS

t01     str     #EE,#DD,#BBCC,#8899AA,#44556677
t02     str     #EE,-1,#BBCC,#8899AA,#44556677
t03     str     #EE,#DD,-1,#8899AA,#44556677
t04     str     #EE,#DD,-256,#8899AA,#44556677
t05     str     #EE,#DD,-257,#8899AA,#44556677
t06     str     #EE,#DD,#BBCC,-1,#44556677
t07     str     #EE,#DD,#BBCC,-256,#44556677
t08     str     #EE,#DD,#BBCC,-65536,#44556677
t09     str     #EE,#DD,#BBCC,#8899AA,-1
t0A     str     #EE,#DD,#BBCC,#8899AA,-#100
t0B     str     #EE,#DD,#BBCC,#8899AA,-#10000
t0C     str     #EE,#DD,#BBCC,#8899AA,-#1000000
