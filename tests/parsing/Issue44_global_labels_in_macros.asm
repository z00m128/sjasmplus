    MACRO setlabel1 name, val
@name = val
	ENDM

	MACRO setlabel2 name, val
name = val
@m.mac_lbl3 = 'ee'
	ENDM

	MODULE m

@m.label1 = 'aa'
m.label2 = 'bb'
	setlabel1 m.mac_lbl1, 'cc'
	setlabel2 m.mac_lbl2, 'dd'

	ENDMODULE

	OUTPUT Issue44_global_labels_in_macros.bin
	; verify the label names are as expected
    dw  @m.label1, @m.m.label2, @m.mac_lbl1, @m.m.mac_lbl2, @m.mac_lbl3
