    DEVICE ZXSPECTRUMNEXT
    ORG $8000
        daa         ; some eol comments with keyword1 included
        nop         ; some eol comment without any keyword
; full line comment with keyword2 included (line without code)
; full line without any keyword, but wrong cased Keyword2 (SLD keywords are case sensitive)
label1: DB  1,"b",3 ; some keyword3 here
label2: DB  4,"e",6 ; keyword none here

    SLDOPT COMMENT keyword1, keyword2   ; SLDOPT is global directive
    SLDOPT COMMENT keyword2, keyword3   ; and keywords could be added over multiple lines

        ret         ; some keyword1 also after SLDOPT specified (should not matter)
        nop         ; some eol comment without any keyword
    MMU 6, 100
    DISP 50000, 100
        cpl         ; keyword2 in displacement block (displaced address reported)
    ENT

    ; syntax error
    SLDOPT INVALID whatever
    SLDOPT COMMENT @@@  ; invalid keyword (must roughly fit rules of valid labels)
    SLDOPT COMMENT
    SLDOPT
