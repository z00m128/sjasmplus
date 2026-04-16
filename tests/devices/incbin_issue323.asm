  DEVICE ZXSPECTRUM48

  ORG 65524
LOCAL:
  ld b, 1
  ret

  block 65526 -$, 255

  INCBIN "incbin_issue323.asm", 0, 10   ; assembling gets stuck when file exactly fits or overruns device memory
;   block 10, 255                       ; same length block has no issue to assemble

t_end
  SAVEBIN "incbin_issue323.bin", LOCAL, t_end - LOCAL
