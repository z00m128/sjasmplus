# Makefile for sjasmplus created by Tygrys' hands.
# install/uninstall features added, CFLAGS and LDFLAGS modification by z00m's hands. [05.05.2016]
# overall optimization and beautification by mborik's hands. [05.05.2016]
# simplified for linux only by cizo2000's hands [10.5.2016]
#
# requirements: lua-5.1.5-r3, toluapp-1.0.93

GCC=gcc
CC=$(GCC)
GPP=g++
C++=$(GPP)

PREFIX=/usr/local
INSTALL=install -c
UNINSTALL=rm -vf

EXE=sjasmplus

SUBDIR_BASE=sjasm

CFLAGS=-O2 -Wall -DLUA_USE_LINUX -DMAX_PATH=PATH_MAX
CXXFLAGS=$(CFLAGS)

# for Linux (added strip flag)
LDFLAGS=-ldl -s -llua -ltolua++

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

all: $(OBJS)
	$(GPP) -o $(EXE) $(CXXFLAGS) $(OBJS) $(LDFLAGS)

install:
	$(INSTALL) $(EXE) $(PREFIX)/bin

uninstall:
	$(UNINSTALL) $(PREFIX)/bin/$(EXE)

.c.o:
	$(GCC) $(CFLAGS) -o $@ -c $< 

.cpp.o:
	$(GPP) $(CFLAGS) -o $@ -c $<

clean:
	$(UNINSTALL) \
		$(SUBDIR_BASE)/*.o \
		$(EXE) *~
