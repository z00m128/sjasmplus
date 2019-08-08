; various error states, etc... (not a good fit elsewhere)
    ENDLUA

    LUA neverpass
    ENDLUA

    INCLUDELUA neverfile.lua

    LUA pass3
        % $ & ?
    ENDLUA

    LUA pass3
        someErrorInLua(1, 2, 3)
