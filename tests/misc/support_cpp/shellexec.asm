    SHELLEXEC "exit 0"
    SHELLEXEC "exit", "7"

    LUA PASS3
        os.remove("shellexec.done")
        sj.shellexec("echo done > shellexec.done")
        local marker = assert(io.open("shellexec.done", "rb"))
        assert(marker:read("*a"):find("done", 1, true))
        marker:close()
        sj.shellexec("exit 7")
    ENDLUA