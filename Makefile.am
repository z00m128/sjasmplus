bin_PROGRAMS = sjasmplus 
sjasmplus_SOURCES = sjasm/devices.cpp sjasm/directives.cpp sjasm/io_snapshots.cpp sjasm/io_tape.cpp sjasm/io_trd.cpp sjasm/lua_sjasm.cpp sjasm/parser.cpp sjasm/reader.cpp sjasm/sjasm.cpp sjasm/sjio.cpp sjasm/support.cpp sjasm/tables.cpp sjasm/z80.cpp sjasm/lua_lpack.c
AUTOMAKE_OPTIONS = subdir-objects
nodist_include_HEADERS = config.h
AM_CPPFLAGS = $(liblua_CFLAGS) $(libtoluapp_CFLAGS)
sjasmplus_LDADD = $(libtoluapp_LIBS) $(liblua_LIBS) -ldl
sjasmplus_LDFLAGS = -s 
