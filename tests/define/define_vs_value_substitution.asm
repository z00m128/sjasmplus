    ; testing if the two-level deep substitution happens per-line and not at DEFINE itself
    DEFINE xyz 123
    DEFINE abc xyz : ASSERT 123 == abc
    UNDEFINE xyz
    DEFINE xyz 456 : ASSERT 456 == abc

    ; remove the defines
    UNDEFINE abc : UNDEFINE xyz

    ; second variant defining "abc" ahead of "xyz"
    DEFINE abc xyz 
    DEFINE xyz 234 : ASSERT 234 == abc
    UNDEFINE xyz
    DEFINE xyz 567 : ASSERT 567 == abc
