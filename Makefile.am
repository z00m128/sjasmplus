AUTOMAKE_OPTIONS = subdir-objects

nodist_include_HEADERS = config.h
bin_PROGRAMS = sjasmplus bin2c
bin2c_SOURCES = utils/bin2c/bin2c.cpp

if LUA
sjasmplus_SOURCES = sjasm/devices.cpp sjasm/directives.cpp sjasm/io_snapshots.cpp sjasm/io_tape.cpp sjasm/io_trd.cpp sjasm/lua_sjasm.cpp sjasm/parser.cpp sjasm/reader.cpp sjasm/sjasm.cpp sjasm/sjio.cpp sjasm/support.cpp sjasm/tables.cpp sjasm/z80.cpp sjasm/lua_lpack.c

AM_CPPFLAGS = $(LUA_INCLUDE) $(libtoluapp_CFLAGS)
sjasmplus_LDADD = $(libtoluapp_LIBS) $(LUA_LIB)
else
sjasmplus_SOURCES = sjasm/devices.cpp sjasm/directives.cpp sjasm/io_snapshots.cpp sjasm/io_tape.cpp sjasm/io_trd.cpp sjasm/parser.cpp sjasm/reader.cpp sjasm/sjasm.cpp sjasm/sjio.cpp sjasm/support.cpp sjasm/tables.cpp sjasm/z80.cpp
endif

sjasmplus_LDFLAGS = -s 

