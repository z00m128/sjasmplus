; demonstration of work-around for current v1.18.2

  DEFINE OPT_FIELD3 Field3 DB 0

  STRUCT DATA
Field1  DB 0
Field2  DW 0
OPT_FIELD3
Field4  DB 1
  ENDS
  ASSERT 5 == DATA && 3 == DATA.Field3 && 4 == DATA.Field4

  ; redefine OPT_FIELD3 to empty define
  DEFINE+ OPT_FIELD3

  STRUCT DATA2
Field1  DB 2
Field2  DW 3
OPT_FIELD3
Field4  DB 4
  ENDS
  ASSERT 4 == DATA2 && 3 == DATA2.Field4 && !EXIST(DATA2.Field3)

  DATA  {0,1,2,3}
  DATA2 {4,5,6}
