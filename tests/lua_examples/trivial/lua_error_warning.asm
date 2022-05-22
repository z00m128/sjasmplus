    ; verify documented usage
    lua
        sj.error("message")
        sj.error("message", "bad value")
        sj.warning("message")
        sj.warning("message", "bad value")
    endlua
    ; verify behaviour when mandatory argument is missing (message)
    lua
        sj.error()
    endlua
    lua
        sj.error(nil)
    endlua
    lua
        sj.error(nil,123)
    endlua
    lua
        sj.warning()
    endlua
    lua
        sj.warning(nil)
    endlua
    lua
        sj.warning(nil,124)
    endlua
