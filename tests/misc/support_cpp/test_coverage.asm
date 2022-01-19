    ; check warning about relative path starting with windows drive letter

    ; relative path should display warning (difficult to append/change path by prefixing the user string)
    INCLUDELUA "c:relative_win_drive_path.some.nonexisting.file"

    ; absolute path is ok-ish (still pain if you cooperate with several developers on same project, but your choice)
    INCLUDELUA "c:/absolute_win_drive_path.some.nonexisting.file"

    ; check LuaShellExec routine - can't capture output (echo is stdout and redirect to stderr differs per OS)
    LUA PASS3
        sj.shellexec("echo hello")
    ENDLUA
