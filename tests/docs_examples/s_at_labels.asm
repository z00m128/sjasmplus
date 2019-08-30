    MODULE xxx
Label      ; xxx.Label
.Local     ; xxx.Label.Local
@Label     ; Label
.Local     ; xxx.Label.Local => duplicate label error
@Label2    ; Label2
.Local     ; xxx.Label2.Local
@yyy.Local ; yyy.Local
yyy.Local  ; xxx.yyy.Local
    ENDMODULE
