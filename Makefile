# Makefile for sjasmplus created by Tygrys' hands.
# install/uninstall features added, CFLAGS and LDFLAGS modification by z00m's hands. [05.05.2016]
# overall optimization and beautification by mborik's hands. [05.05.2016]
# overall rewrite by Ped7g [2019-03-21]
# added code coverage targets and variables by Ped7g [2019-07-22]

## Some examples of my usage of this Makefile:
# make tests 					- to run the CI test+example script runner
# make memcheck TEST=misc DEBUG=1		- to use valgrind on assembling sub-directory "misc" in tests
# make PREFIX=~/.local install			- to install release version into ~/.local/bin/
# make clean && make CC=gcc-8 CXX=g++-8		- to compile binary with gcc-8
# make DEBUG=1 LUA_COVERAGE=1 coverage		- to produce build/debug/coverage/* files by running the tests
# make COVERALLS_SERVICE=1 DEBUG=1 coverage	- to produce coverage data and upload them to https://coveralls.io/
# make CFLAGS_EXTRA='-m32' LDFLAGS='-ldl -m32'  - to builds 32b linux executable
# make KEEP_SYMBOLS=1 CC=clang-12 CXX=clang++-12 CFLAGS_EXTRA='-fsanitize=address' LDFLAGS='-ldl -fsanitize=address' - ASAN build
# make KEEP_SYMBOLS=1 CC=clang-12 CXX=clang++-12 CFLAGS_EXTRA='-fsanitize=undefined' LDFLAGS='-ldl -fsanitize=undefined' - UBSAN build
# to cross-compile windows exe try to use Makefile.win instead, this Makefile is now too much linux/posix only

# Use LUA (system-wide or bundled, depending on USE_BUNDLED_LUA)
USE_LUA?=1

# Use bundled LUA
USE_BUNDLED_LUA?=1

# Where to stage files when building a package
STAGEDIR?=

# Where to install resulting files
PREFIX?=/usr/local

# define DEBUG=1 for debug build
DEBUG?=

ifdef DEBUG
KEEP_SYMBOLS?=$(DEBUG)
endif

# set up CC+CXX explicitly, because windows MinGW/MSYS environment don't have it set up
CC?=cc
CXX?=c++
BASH?=/usr/bin/env bash
STRIP?=strip
INSTALL?=install -c
UNINSTALL?=rm -vf
REMOVEDIR?=rm -vdf
DOCBOOKGEN?=xsltproc
MEMCHECK?=valgrind --leak-check=yes
	# --leak-check=full --show-leak-kinds=all

# all internal file names (sources, module subdirs, build dirs, ...) must be WITHOUT space!
# (i.e. every relative path from project-dir must be space-less ...)
# the project-dir itself can contain space, or any path leading up to it

EXE_BASE_NAME=sjasmplus
BUILD_DIR=build

SUBDIR_BASE=sjasm
SUBDIR_LUA=lua5.4
SUBDIR_LUABRIDGE=LuaBridge/Source
SUBDIR_CRC32C=crc32c
SUBDIR_DOCS=docs
SUBDIR_COV=coverage

ifeq ($(USE_BUNDLED_LUA), 1)
_LUA_CPPFLAGS=-I$(SUBDIR_LUA)
endif

# TODO too many lua5.4 warnings: -pedantic removed
CPPFLAGS+=-Wall -DMAX_PATH=PATH_MAX -I$(SUBDIR_CRC32C)
ifeq ($(USE_LUA), 1)
CPPFLAGS+=-DUSE_LUA -DLUA_USE_LINUX $(_LUA_CPPFLAGS) -I$(SUBDIR_LUABRIDGE)
endif

CFLAGS+=$(CFLAGS_EXTRA)

ifeq ($(USE_LUA), 1)
LDFLAGS+=-ldl
endif

ifdef DEBUG
BUILD_DIR:=$(BUILD_DIR)/debug
CFLAGS+=-g -O0
else
BUILD_DIR:=$(BUILD_DIR)/release
CFLAGS+=-DNDEBUG -O2
endif

# C++ flags (the CPPFLAGS are for preprocessor BTW, if you always wonder, like me...)
CXXFLAGS?=-std=gnu++14 $(CFLAGS)

# full path to executable
BUILD_EXE=$(BUILD_DIR)/$(EXE_BASE_NAME)

# UnitTest++ related values (slightly modified defaults)
# Unit Test exe (checks for "--unittest" and runs unit tests then)
EXE_UT_BASE_NAME=sjasm+ut
BUILD_DIR_UT=$(BUILD_DIR)+ut
SUBDIR_UT=unittest-cpp
SUBDIR_TESTS=cpp-src-tests
BUILD_EXE_UT=$(BUILD_DIR_UT)/$(EXE_UT_BASE_NAME)

EXE_FP="$(abspath $(BUILD_EXE))"
EXE_UT_FP="$(abspath $(BUILD_EXE_UT))"

# turns list of %.c/%.cpp files into $BUILD_DIR/%.o list
define object_files
	$(addprefix $(BUILD_DIR)/, $(patsubst %.c,%.o, $(patsubst %.cpp,%.o, $(1))))
endef
define object_files_ut
	$(addprefix $(BUILD_DIR_UT)/, $(patsubst %.c,%.o, $(patsubst %.cpp,%.o, $(1))))
endef

# sjasmplus files
SRCS:=$(wildcard $(SUBDIR_BASE)/*.c) $(wildcard $(SUBDIR_BASE)/*.cpp)
OBJS:=$(call object_files,$(SRCS))
OBJS_UT:=$(call object_files_ut,$(SRCS))

ifeq ($(USE_BUNDLED_LUA), 1)
# liblua files
LUASRCS:=$(wildcard $(SUBDIR_LUA)/*.c)
LUAOBJS:=$(call object_files,$(LUASRCS))
LUAOBJS_UT:=$(call object_files_ut,$(LUASRCS))
endif

# crc32c files
CRC32CSRCS:=$(wildcard $(SUBDIR_CRC32C)/*.cpp)
CRC32COBJS:=$(call object_files,$(CRC32CSRCS))
CRC32COBJS_UT:=$(call object_files_ut,$(CRC32CSRCS))

# UnitTest++ files
UTPPSRCS:=$(wildcard $(SUBDIR_UT)/UnitTest++/*.cpp) $(wildcard $(SUBDIR_UT)/UnitTest++/Posix/*.cpp)
UTPPOBJS:=$(call object_files,$(UTPPSRCS))
TESTSSRCS:=$(wildcard $(SUBDIR_TESTS)/*.cpp)
TESTSOBJS:=$(call object_files_ut,$(TESTSSRCS))

ALL_OBJS:=$(OBJS) $(CRC32COBJS)
ifeq ($(USE_LUA), 1)
ifeq ($(USE_BUNDLED_LUA), 1)
ALL_OBJS+=$(LUAOBJS)
endif
endif
ALL_OBJS_UT=$(OBJS_UT) $(CRC32COBJS_UT) $(UTPPOBJS) $(TESTSOBJS)
ifeq ($(USE_LUA), 1)
ifeq ($(USE_BUNDLED_LUA), 1)
ALL_OBJS_UT+=$(LUAOBJS_UT)
endif
endif
ALL_COVERAGE_RAW:=$(patsubst %.o,%.gcno,$(ALL_OBJS_UT)) $(patsubst %.o,%.gcda,$(ALL_OBJS_UT))

# GCOV options to generate coverage files
ifdef COVERALLS_SERVICE
GCOV_OPT=-rlp
else
GCOV_OPT=-rlpmab
endif

#implicit rules to compile C/CPP files into $(BUILD_DIR)
$(BUILD_DIR)/%.o : %.c
	@mkdir -p $(@D)
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(BUILD_DIR)/%.o : %.cpp
	@mkdir -p $(@D)
	$(COMPILE.cc) $(OUTPUT_OPTION) $<

#implicit rules to compile C/CPP files into $(BUILD_DIR_UT) (with unit tests enabled)
$(BUILD_DIR_UT)/%.o : %.c
	@mkdir -p $(@D)
	$(COMPILE.c) -DADD_UNIT_TESTS -I$(SUBDIR_UT) $(OUTPUT_OPTION) $<

$(BUILD_DIR_UT)/%.o : %.cpp
	@mkdir -p $(@D)
	$(COMPILE.cc) -DADD_UNIT_TESTS -I$(SUBDIR_UT) $(OUTPUT_OPTION) $<

.PHONY: all install uninstall clean docs tests memcheck coverage upx

# "all" will also copy the produced binary into project root directory (to mimick old makefile)
all: $(BUILD_EXE)
	$(INSTALL) $(BUILD_EXE) $(EXE_BASE_NAME)

upx: $(BUILD_EXE)
	cp $(BUILD_EXE) $(EXE_BASE_NAME)
	upx --best $(EXE_BASE_NAME)
	EXE="$(CURDIR)/$(EXE_BASE_NAME)" $(BASH) ContinuousIntegration/test_folder_tests.sh

# make all sjasm/*.o depend on all sjasm/*.h files (no subtle dependencies, all by all affected)
$(OBJS): $(wildcard $(SUBDIR_BASE)/*.h)

$(BUILD_EXE): $(ALL_OBJS)
	$(CXX) -o $(BUILD_EXE) $(CXXFLAGS) $(ALL_OBJS) $(LDFLAGS)
ifndef KEEP_SYMBOLS
	$(STRIP) $(BUILD_EXE)
endif

$(BUILD_EXE_UT): $(ALL_OBJS_UT)
	$(CXX) -o $(BUILD_EXE_UT) $(CXXFLAGS) $(ALL_OBJS_UT) $(LDFLAGS)
ifndef KEEP_SYMBOLS
	$(STRIP) $(BUILD_EXE_UT)
endif

install: $(BUILD_EXE)
	$(INSTALL) -d "$(STAGEDIR)/$(PREFIX)/bin"
	$(INSTALL) $(BUILD_EXE) "$(STAGEDIR)/$(PREFIX)/bin"

uninstall:
	$(UNINSTALL) "$(STAGEDIR)/$(PREFIX)/bin/$(EXE_BASE_NAME)"

tests: $(BUILD_EXE_UT)
ifdef TEST
	EXE=$(EXE_UT_FP) $(BASH) ContinuousIntegration/test_folder_tests.sh "$(TEST)"
else
	$(BUILD_EXE_UT) --unittest
	EXE=$(EXE_UT_FP) $(BASH) ContinuousIntegration/test_folder_tests.sh
	EXE=$(EXE_UT_FP) $(BASH) ContinuousIntegration/test_folder_examples.sh
endif

memcheck: $(BUILD_EXE)
ifdef TEST
	MEMCHECK="$(MEMCHECK)" EXE=$(EXE_FP) $(BASH) ContinuousIntegration/test_folder_tests.sh "$(TEST)"
else
	MEMCHECK="$(MEMCHECK)" EXE=$(EXE_FP) $(BASH) ContinuousIntegration/test_folder_tests.sh
	MEMCHECK="$(MEMCHECK)" EXE=$(EXE_FP) $(BASH) ContinuousIntegration/test_folder_examples.sh
endif

coverage:
	$(MAKE) CFLAGS_EXTRA=--coverage tests
	gcov $(GCOV_OPT) --object-directory $(BUILD_DIR_UT)/$(SUBDIR_BASE) $(SRCS)
	gcov $(GCOV_OPT) --object-directory $(BUILD_DIR_UT)/$(SUBDIR_CRC32C) $(CRC32CSRCS)
ifdef LUA_COVERAGE
# by default the "external" lua sources are excluded from coverage report, sjasmplus is not focusing to cover+fix lua itself
# to get full coverage report, including the lua sources, use `make DEBUG=1 LUA_COVERAGE=1 coverage`
	gcov $(GCOV_OPT) --object-directory $(BUILD_DIR_UT)/$(SUBDIR_LUA) $(LUASRCS)
endif
ifndef COVERALLS_SERVICE
# coversall.io is serviced by 3rd party plugin: https://github.com/eddyxu/cpp-coveralls
# (from *.gcov files stored in project root directory, so not moving them here)
# local coverage is just moved from project_root to build_dir/coverage/
	@mkdir -p $(BUILD_DIR_UT)/$(SUBDIR_COV)
	mv *#*.gcov $(BUILD_DIR_UT)/$(SUBDIR_COV)/
endif

docs: $(SUBDIR_DOCS)/documentation.html ;

$(SUBDIR_DOCS)/documentation.html: Makefile $(wildcard $(SUBDIR_DOCS)/*.xml) $(wildcard $(SUBDIR_DOCS)/*.xsl)
	$(DOCBOOKGEN) \
		--stringparam html.stylesheet docbook.css \
		--stringparam generate.toc "book toc" \
		-o $(SUBDIR_DOCS)/documentation.html \
		$(SUBDIR_DOCS)/docbook-xsl-ns-html-customization-linux.xsl \
		$(SUBDIR_DOCS)/documentation.xml

clean:
	$(UNINSTALL) \
		$(EXE_BASE_NAME) \
		$(BUILD_EXE) \
		$(BUILD_EXE_UT) \
		$(ALL_OBJS) \
		$(ALL_COVERAGE_RAW) \
		$(ALL_OBJS_UT) \
		$(BUILD_DIR_UT)/$(SUBDIR_COV)/*.gcov
	$(REMOVEDIR) \
		$(BUILD_DIR)/$(SUBDIR_BASE) \
		$(BUILD_DIR)/$(SUBDIR_CRC32C) \
		$(BUILD_DIR)/$(SUBDIR_LUA) \
		$(BUILD_DIR)/$(SUBDIR_UT)/UnitTest++/Posix \
		$(BUILD_DIR)/$(SUBDIR_UT)/UnitTest++ \
		$(BUILD_DIR)/$(SUBDIR_UT) \
		$(BUILD_DIR) \
		$(BUILD_DIR_UT)/$(SUBDIR_BASE) \
		$(BUILD_DIR_UT)/$(SUBDIR_CRC32C) \
		$(BUILD_DIR_UT)/$(SUBDIR_LUA) \
		$(BUILD_DIR_UT)/$(SUBDIR_TESTS) \
		$(BUILD_DIR_UT)/$(SUBDIR_COV) \
		$(BUILD_DIR_UT)
