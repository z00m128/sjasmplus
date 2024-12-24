  LUA
    --  outside of a module --
    my_var = sj.get_modules()
    -- sj.get_modules() returns "" --
    sj.insert_label(my_var.."label", 0xA0A0)
  ENDLUA

  ASSERT label = 0xA0A0

  MODULE plop

  LUA
    -- entering module plop --
    my_var = sj.get_modules()
    -- sj.get_modules() returns "plop"
    sj.insert_label(my_var..".label", 0xB0B0)
  ENDLUA

  ASSERT plop.label = 0xB0B0

  MODULE plip

  LUA
    -- entering module plip --
    my_var = sj.get_modules()
    -- sj.get_modules() returns "plop.plip" --
    sj.insert_label(my_var..".label", 0xC0C0)
  ENDLUA

  ASSERT plop.plip.label = 0xC0C0

  ENDMODULE

  LUA
    -- returning in module plop --
    my_var = sj.get_modules()
    -- sj.get_modules() returns "plop" --
    sj.insert_label(my_var..".label", 0xD0D0)
  ENDLUA

  ASSERT plip.label = 0xD0D0

  ENDMODULE

  LUA
    -- outside of a module --
    my_var = sj.get_modules()
    sj.insert_label(my_var.."label", 0xE0E0)
    -- sj.get_modules() returns ""
  ENDLUA

  ASSERT label = 0xE0E0
