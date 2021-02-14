    DEFINE define1 12           ; trailing comments were producing many spaces trailing in the value
    DB define1; so here was extra whitespace in listing after substituted "12"
    ; since v1.18.2 these are trimmed, but only when there's eol-comment trailing

    ; without trailing comment, they are part of the value!
    DEFINE define2 34  
    DB define2; here should be two spaces after "34" comming from the DEFINE line
