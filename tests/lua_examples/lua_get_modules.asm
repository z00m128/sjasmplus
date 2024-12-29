  ; no module, no main label
  LUA ALLPASS
    -- assert() is reported only in LASTPASS in ALLPASS block, so using sj.error instead
    if ("" ~= sj.get_modules()) then sj.error("\"\"", sj.get_modules()) end
  ENDLUA

main_label1:
  ; no module, has main label
  LUA ALLPASS
    if ("" ~= sj.get_modules()) then sj.error("\"\"", sj.get_modules()) end
  ENDLUA

  MODULE plop

    ; plop module, no main label
    LUA ALLPASS
      if ("plop" ~= sj.get_modules()) then sj.error("plop", sj.get_modules()) end
    ENDLUA

main_label2:
    ; plop module, has main label
    LUA ALLPASS
      if ("plop" ~= sj.get_modules()) then sj.error("plop", sj.get_modules()) end
    ENDLUA

    MODULE plip

      ; plop.plip module, no main label
      LUA ALLPASS
        if ("plop.plip" ~= sj.get_modules()) then sj.error("plop.plip", sj.get_modules()) end
      ENDLUA
main_label3:
      ; plop.plip module, has main label
      LUA ALLPASS
        if ("plop.plip" ~= sj.get_modules()) then sj.error("plop.plip", sj.get_modules()) end
      ENDLUA

      ; to verify lua variables from earlier passes keep correct content in Lua context
      LUA PASS1
        lua_pass = 1
        pass1_modules_var = sj.get_modules()
      ENDLUA
      LUA PASS2
        lua_pass = 2
        pass2_modules_var = sj.get_modules()
      ENDLUA
      LUA PASS3
        lua_pass = 3
        pass3_modules_var = sj.get_modules()
      ENDLUA

    ENDMODULE

    ; plip module ended
    LUA ALLPASS
      if ("plop" ~= sj.get_modules()) then sj.error("plop", sj.get_modules()) end
    ENDLUA

  ENDMODULE

  ; plop module ended
  LUA ALLPASS
    if ("" ~= sj.get_modules()) then sj.error("\"\"", sj.get_modules()) end
    -- verify those pass1/2/3 variables
    if (1 <= lua_pass and "plop.plip" ~= pass1_modules_var) then sj.error("plop.plip", pass1_modules_var) end
    if (2 <= lua_pass and "plop.plip" ~= pass2_modules_var) then sj.error("plop.plip", pass2_modules_var) end
    if (3 <= lua_pass and "plop.plip" ~= pass3_modules_var) then sj.error("plop.plip", pass3_modules_var) end
  ENDLUA
