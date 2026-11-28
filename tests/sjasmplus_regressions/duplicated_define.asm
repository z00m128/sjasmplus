        define label "value1"
        define label "value2"
                db label
                undefine label
                ifdef label
                        assert 0
                endif
