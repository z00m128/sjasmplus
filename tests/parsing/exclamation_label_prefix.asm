LoudMainLabel1:
!SilentMainLabel1:
.loop:
!.noEffectOnLocals:
    jr  LoudMainLabel1.loop
    jr  SilentMainLabel1
    jr  LoudMainLabel1.noEffectOnLocals

@LoudMainLabel2:
!@SilentMainLabel2:
.loop:
!.noEffectOnLocals:
    jr  LoudMainLabel2.loop
    jr  SilentMainLabel2
    jr  LoudMainLabel2.noEffectOnLocals

    jr  @LoudMainLabel1.loop
    jr  @LoudMainLabel2.loop
    jr  @LoudMainLabel1.noEffectOnLocals
    jr  @LoudMainLabel2.noEffectOnLocals

    STRUCT S_TEST
bb      BYTE    $12
    ENDS

StructLoud      S_TEST
!StructSilent   S_TEST
.check:
    ld  hl,StructLoud.check
    ld  hl,@StructLoud.check
