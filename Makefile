# Makefile for sjasmplus created by Tygrys' hands.
# install/uninstall features added, io_tape.o, CFLAGS and LDFLAGS modification by z00m's hands. [05.05.2016]

GCC=gcc
CC=$(GCC)
GPP=g++
C++=$(GPP)

PREFIX=/usr/local
INSTALL=install -c
UNINSTALL=rm -vf

EXE=sjasmplus

CFLAGS=-O2 -Wall -DLUA_USE_LINUX -DMAX_PATH=PATH_MAX -Ilua5.1 -Itolua++
CXXFLAGS=$(CFLAGS)

#for Linux
LDFLAGS=-ldl

#sjasmplus object files
OBJS=sjasm/devices.o sjasm/directives.o sjasm/io_snapshots.o sjasm/io_trd.o sjasm/io_tape.o \
sjasm/lua_lpack.o sjasm/lua_sjasm.o sjasm/parser.o sjasm/reader.o sjasm/sjasm.o sjasm/sjio.o \
sjasm/support.o sjasm/tables.o sjasm/z80.o

#liblua objects
LUAOBJS= lua5.1/lapi.o lua5.1/lauxlib.o lua5.1/lbaselib.o lua5.1/lcode.o lua5.1/ldblib.o \
lua5.1/ldebug.o lua5.1/ldo.o lua5.1/ldump.o lua5.1/lfunc.o lua5.1/lgc.o lua5.1/linit.o \
lua5.1/liolib.o lua5.1/llex.o lua5.1/lmathlib.o lua5.1/lmem.o lua5.1/loadlib.o \
lua5.1/lobject.o lua5.1/lopcodes.o lua5.1/loslib.o lua5.1/lparser.o lua5.1/lstate.o \
lua5.1/lstring.o lua5.1/lstrlib.o lua5.1/ltable.o lua5.1/ltablib.o lua5.1/ltm.o \
lua5.1/lundump.o lua5.1/lvm.o lua5.1/lzio.o

# tolua objects
TOLUAOBJS=tolua++/tolua_event.o tolua++/tolua_is.o tolua++/tolua_map.o \
tolua++/tolua_push.o tolua++/tolua_to.o

all: $(LUAOBJS) $(TOLUAOBJS) $(OBJS)
	$(GPP) -o $(EXE) $(CXXFLAGS) $(OBJS) $(LUAOBJS) $(TOLUAOBJS) $(LDFLAGS)
	strip $(EXE)

install:
	$(INSTALL) $(EXE) $(PREFIX)/bin

uninstall:
	$(UNINSTALL) $(PREFIX)/bin/$(EXE)

.c.o:
	$(GCC) $(CFLAGS) -o $@ -c $< 

.cpp.o:
	$(GPP) $(CFLAGS) -o $@ -c $<

clean:
	$(UNINSTALL) *.o *.o lua5.1/*.o tolua++/*.o *~ $(EXE)
