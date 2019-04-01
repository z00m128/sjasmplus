        OUTPUT      "string_expressions_db.bin"
        DB          'A','A'+1,2|'A',3+'A'               ; ABCD (41 42 43 44)
        DB          'A'|4,'F'&$46, $47&'G', 9^'A'       ; EFGH (45 46 47 48)
        DB          'A'^8, low 'AJ', high 'KA', 'M'-1   ; IJKL (49 4A 4B 4C)
        DB          'M'*1, 'N'/1, 'O'%128, '('<<1       ; MNOP (4D 4E 4F 50)
        DB          'Q'<?'Z', 'R'>?'A', 'S'%'T',~~'T'   ; QRST (51 52 53 54)
