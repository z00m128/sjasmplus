/*

  SjASMPlus Z80 Cross Compiler

  Copyright (c) 2004-2006 Aprisobal

  This software is provided 'as-is', without any express or implied warranty.
  In no event will the authors be held liable for any damages arising from the
  use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it freely,
  subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not claim
	 that you wrote the original software. If you use this software in a product,
	 an acknowledgment in the product documentation would be appreciated but is
	 not required.

  2. Altered source versions must be plainly marked as such, and must not be
	 misrepresented as being the original software.

  3. This notice may not be removed or altered from any source distribution.

*/

//sjdefs.h

#ifndef __SJDEFS
#define __SJDEFS

// version string
#define VERSION "1.19.0"
#define VERSION_NUM "0x00011300"

#define LASTPASS 3

// output
#define _COUT cout <<
#define _CERR cerr <<
#define _CMDL  <<
#define _ENDL << endl
#define _END ;

#ifdef WIN32
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#endif

#include <memory>
#include <algorithm>
#include <stack>
#include <vector>
#include <iostream>
using std::cout;
using std::cerr;
using std::endl;
using std::flush;
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>
#include <math.h>

//FIXME actually move this only to files which do something with lua and not everywhere?
#ifdef USE_LUA
  #include "lua.hpp"
#endif //USE_LUA

// global defines
#define LINEMAX 2048
#define LINEMAX2 LINEMAX*2
#define LABMAX 64
#define LABTABSIZE 32768
#define FUNTABSIZE 4096
typedef int32_t aint;
typedef uint8_t byte;
typedef uint16_t word;
typedef std::vector<char> stdin_log_t;

#ifdef _MSC_VER
#pragma pack(push, 1)
#endif
template <typename T>
struct SAlignSafeCast {
	T	val;
}
#ifndef _MSC_VER
	__attribute__((packed));
#else
	;
#pragma pack(pop)
#endif

#ifndef PATH_MAX
#define PATH_MAX	4096
#endif

// include all headers

// extern "C" { //FIXME remove or update
// #include "lua_lpack.h"
// }

#include "devices.h"
#include "support.h"
#include "tables.h"
#include "reader.h"
#include "parser.h"
#include "z80.h"
#include "directives.h"
#include "sjio.h"
#include "io_cpc.h"
#include "io_err.h"
#include "io_snapshots.h"
#include "io_tape.h"
#include "io_trd.h"
#include "io_tzx.h"
#include "io_nex.h"
#include "relocate.h"
#include "sjasm.h"

#endif
//eof sjdefs.h
