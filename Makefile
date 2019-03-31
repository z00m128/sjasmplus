# Makefile for sjasmplus created by Tygrys' hands.
# install/uninstall features added, CFLAGS and LDFLAGS modification by z00m's hands. [05.05.2016]
# overall optimization and beautification by mborik's hands. [05.05.2016]
# overall rewrite by Ped7g [2019-03-21]

## Some examples of my usage of this Makefile:
# make DEBUG=1					- to get DEBUG build
# make tests 					- to run the CI test+example script runner
# make memcheck TEST=misc DEBUG=1		- to use valgrind on assembling sub-directory "misc" in tests
# make PREFIX=~/.local install			- to install release version into ~/.local/bin/
# make clean && make CC=gcc-8 CXX=g++-8		- to compile binary with gcc-8

# set up CC+CXX explicitly, because windows MinGW/MSYS environment don't have it set up
CC=gcc
CXX=g++
BASH=/bin/bash

PREFIX=/usr/local
INSTALL=install -c
UNINSTALL=rm -vf
REMOVEDIR=rm -vdf
DOCBOOKGEN=xsltproc
MEMCHECK=valgrind --leak-check=yes

EXE := sjasmplus
BUILD_DIR := build

SUBDIR_BASE=sjasm
SUBDIR_LUA=lua5.1
SUBDIR_TOLUA=tolua++
SUBDIR_DOCS=docs

CFLAGS := -Wall -pedantic -DUSE_LUA -DLUA_USE_LINUX -DMAX_PATH=PATH_MAX -I$(SUBDIR_LUA) -I$(SUBDIR_TOLUA)
LDFLAGS := -ldl

ifdef DEBUG
BUILD_DIR := $(BUILD_DIR)/debug
CFLAGS += -g -O0
else
BUILD_DIR := $(BUILD_DIR)/release
CFLAGS += -DNDEBUG -O2
# for Linux (added strip flag)
LDFLAGS += -s
endif

# C++ flags (the CPPFLAGS are for preprocessor BTW, if you always wonder, like me...)
CXXFLAGS = -std=gnu++14 $(CFLAGS)
#full path to executable
EXE_FP := "$(CURDIR)/$(BUILD_DIR)/$(EXE)"

# turns list of %.c/%.cpp files into $BUILD_DIR/%.o list
define object_files
	$(addprefix $(BUILD_DIR)/, $(patsubst %.c,%.o, $(patsubst %.cpp,%.o, $(1))))
endef

# sjasmplus files
SRCS := $(wildcard $(SUBDIR_BASE)/*.c) $(wildcard $(SUBDIR_BASE)/*.cpp)
OBJS := $(call object_files,$(SRCS))

# liblua files
LUASRCS := $(wildcard $(SUBDIR_LUA)/*.c)
LUAOBJS := $(call object_files,$(LUASRCS))

# tolua files
TOLUASRCS := $(wildcard $(SUBDIR_TOLUA)/*.c)
TOLUAOBJS := $(call object_files,$(TOLUASRCS))

#implicit rules to compile C/CPP files into $(BUILD_DIR)
$(BUILD_DIR)/%.o : %.c
	@mkdir -p $(@D)
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(BUILD_DIR)/%.o : %.cpp
	@mkdir -p $(@D)
	$(COMPILE.cc) $(OUTPUT_OPTION) $<

.PHONY: all install uninstall clean docs tests memcheck

# "all" will also copy the produced binary into project root directory (to mimick old makefile)
all: $(EXE_FP)
	cp $(EXE_FP) $(EXE)

$(EXE_FP): $(LUAOBJS) $(TOLUAOBJS) $(OBJS)
	$(CXX) -o $(EXE_FP) $(CXXFLAGS) $(OBJS) $(LUAOBJS) $(TOLUAOBJS) $(LDFLAGS)

install: $(EXE_FP)
	$(INSTALL) $(EXE_FP) $(PREFIX)/bin

uninstall:
	$(UNINSTALL) $(PREFIX)/bin/$(EXE)

tests: $(EXE_FP)
ifdef TEST
	EXE=$(EXE_FP) $(BASH) "$(CURDIR)/ContinuousIntegration/test_folder_tests.sh" $(TEST)
else
	EXE=$(EXE_FP) $(BASH) "$(CURDIR)/ContinuousIntegration/test_folder_tests.sh"
	@EXE=$(EXE_FP) $(BASH) "$(CURDIR)/ContinuousIntegration/test_folder_examples.sh"
endif

memcheck: $(EXE_FP)
ifdef TEST
	MEMCHECK="$(MEMCHECK)" EXE=$(EXE_FP) $(BASH) "$(CURDIR)/ContinuousIntegration/test_folder_tests.sh" $(TEST)
else
	MEMCHECK="$(MEMCHECK)" EXE=$(EXE_FP) $(BASH) "$(CURDIR)/ContinuousIntegration/test_folder_tests.sh"
	MEMCHECK="$(MEMCHECK)" EXE=$(EXE_FP) $(BASH) "$(CURDIR)/ContinuousIntegration/test_folder_examples.sh"
endif

docs: $(SUBDIR_DOCS)/documentation.html ;

$(SUBDIR_DOCS)/documentation.html: Makefile $(wildcard $(SUBDIR_DOCS)/*.xml) $(wildcard $(SUBDIR_DOCS)/*.xsl)
	$(DOCBOOKGEN) \
		--stringparam generate.toc "book toc" \
		-o $(SUBDIR_DOCS)/documentation.html \
		$(SUBDIR_DOCS)/docbook-xsl-ns-html-customization-linux.xsl \
		$(SUBDIR_DOCS)/documentation.xml

clean:
	$(UNINSTALL) \
		$(EXE) \
		$(BUILD_DIR)/$(EXE) \
		$(LUAOBJS) \
		$(TOLUAOBJS) \
		$(OBJS)
	$(REMOVEDIR) \
		$(BUILD_DIR)/$(SUBDIR_BASE) \
		$(BUILD_DIR)/$(SUBDIR_LUA) \
		$(BUILD_DIR)/$(SUBDIR_TOLUA) \
		$(BUILD_DIR)
