AUTOMAKE_OPTIONS = subdir-objects

bin_PROGRAMS = sjasmplus bin2c

sjasmplus_SOURCES = sjasm/devices.cpp sjasm/directives.cpp sjasm/io_snapshots.cpp sjasm/io_tape.cpp sjasm/io_trd.cpp sjasm/lua_sjasm.cpp sjasm/parser.cpp sjasm/reader.cpp sjasm/sjasm.cpp sjasm/sjio.cpp sjasm/support.cpp sjasm/tables.cpp sjasm/z80.cpp sjasm/lua_lpack.c
nodist_include_HEADERS = config.h

AM_CPPFLAGS = $(LUA_INCLUDE) $(libtoluapp_CFLAGS)
sjasmplus_LDADD = $(libtoluapp_LIBS) $(LUA_LIB)
sjasmplus_LDFLAGS = -s 

bin2c_SOURCES = utils/bin2c/bin2c.cpp
