    SHELLEXEC "kill -TERM $$"
    LUA PASS3
        sj.shellexec("kill -TERM $$")
    ENDLUA