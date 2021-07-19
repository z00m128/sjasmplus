  macro test
@.kip3      ; prevent macro-local label and create regular local label instead
kip0
.kip1
@.kip2
  endm

  module main
    ; should produce labels: main.hoi, main.kip0, 0>kip1, main.kip0.kip2, main.hoi.kip3
hoi test
  endmodule
