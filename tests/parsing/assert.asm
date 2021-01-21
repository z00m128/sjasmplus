    ASSERT 1    ; no error
    ASSERT 0    ; regular classic assert-triggered error
    ASSERT @    ; syntax error

    ; v1.18.1 extended assert with second argument
    ASSERT 1, should pass without error
    ASSERT 0, should fail and make this second text visible in error line
    ASSERT @, should still fail on syntax
    ASSERT , another syntax fail (workaround for non-existing "ERROR something" directive)
