# Makefile for sjasmplus created by Tygrys' hands.
# install/uninstall features added, CFLAGS and LDFLAGS modification by z00m's hands. [05.05.2016]
# overall optimization and beautification by mborik's hands. [05.05.2016]

GCC=gcc
CC=$(GCC)
GPP=g++
C++=$(GPP)

PREFIX=/usr/local
INSTALL=install -c
UNINSTALL=rm -vf
DOCBOOKGEN=xsltproc

EXE=sjasmplus

SUBDIR_BASE=sjasm
SUBDIR_LUA=lua5.1
SUBDIR_TOLUA=tolua++

CFLAGS=-O2 -Wall -pedantic -DUSE_LUA -DLUA_USE_LINUX -DMAX_PATH=PATH_MAX -I$(SUBDIR_LUA) -I$(SUBDIR_TOLUA)
CXXFLAGS=-std=c++14 $(CFLAGS)

# for Linux (added strip flag)
LDFLAGS=-ldl -s

#sjasmplus object files
OBJS=\
	$(SUBDIR_BASE)/devices.o \
	$(SUBDIR_BASE)/directives.o \
	$(SUBDIR_BASE)/io_snapshots.o \
	$(SUBDIR_BASE)/io_trd.o \
	$(SUBDIR_BASE)/io_tape.o \
	$(SUBDIR_BASE)/lua_lpack.o \
	$(SUBDIR_BASE)/lua_sjasm.o \
	$(SUBDIR_BASE)/parser.o \
	$(SUBDIR_BASE)/reader.o \
	$(SUBDIR_BASE)/sjasm.o \
	$(SUBDIR_BASE)/sjio.o \
	$(SUBDIR_BASE)/support.o \
	$(SUBDIR_BASE)/tables.o \
	$(SUBDIR_BASE)/z80.o

#liblua objects
LUAOBJS= \
	$(SUBDIR_LUA)/lapi.o $(SUBDIR_LUA)/lauxlib.o $(SUBDIR_LUA)/lbaselib.o \
	$(SUBDIR_LUA)/lcode.o $(SUBDIR_LUA)/ldblib.o $(SUBDIR_LUA)/ldebug.o \
	$(SUBDIR_LUA)/ldo.o $(SUBDIR_LUA)/ldump.o $(SUBDIR_LUA)/lfunc.o \
	$(SUBDIR_LUA)/lgc.o $(SUBDIR_LUA)/linit.o $(SUBDIR_LUA)/liolib.o \
	$(SUBDIR_LUA)/llex.o $(SUBDIR_LUA)/lmathlib.o $(SUBDIR_LUA)/lmem.o \
	$(SUBDIR_LUA)/loadlib.o $(SUBDIR_LUA)/lobject.o $(SUBDIR_LUA)/lopcodes.o \
	$(SUBDIR_LUA)/loslib.o $(SUBDIR_LUA)/lparser.o $(SUBDIR_LUA)/lstate.o \
	$(SUBDIR_LUA)/lstring.o $(SUBDIR_LUA)/lstrlib.o $(SUBDIR_LUA)/ltable.o \
	$(SUBDIR_LUA)/ltablib.o $(SUBDIR_LUA)/ltm.o $(SUBDIR_LUA)/lundump.o \
	$(SUBDIR_LUA)/lvm.o $(SUBDIR_LUA)/lzio.o

# tolua objects
TOLUAOBJS=\
	$(SUBDIR_TOLUA)/tolua_event.o \
	$(SUBDIR_TOLUA)/tolua_is.o \
	$(SUBDIR_TOLUA)/tolua_map.o \
	$(SUBDIR_TOLUA)/tolua_push.o \
	$(SUBDIR_TOLUA)/tolua_to.o


.PHONY: all clean docs

all: $(LUAOBJS) $(TOLUAOBJS) $(OBJS)
	$(GPP) -o $(EXE) $(CXXFLAGS) $(OBJS) $(LUAOBJS) $(TOLUAOBJS) $(LDFLAGS)

install:
	$(INSTALL) $(EXE) $(PREFIX)/bin

uninstall:
	$(UNINSTALL) $(PREFIX)/bin/$(EXE)

.c.o:
	$(GCC) $(CFLAGS) -o $@ -c $<

.cpp.o:
	$(GPP) $(CXXFLAGS) -o $@ -c $<

docs:
	$(DOCBOOKGEN) \
		--stringparam generate.toc "book toc" \
		-o docs/documentation.html \
		docs/docbook-xsl-ns-html-customization-linux.xsl \
		docs/documentation.xml

clean:
	$(UNINSTALL) \
		$(SUBDIR_BASE)/*.o \
		$(SUBDIR_LUA)/*.o \
		$(SUBDIR_TOLUA)/*.o \
		$(EXE) *~
