#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT(sjsamplus, 1.0, cizo2000@gmail.com)
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES(Makefile)

AM_INIT_AUTOMAKE(1.15)

# Checks for programs.
AC_PROG_CXX
AC_PROG_CC

# Checks for libraries.

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.
AC_CHECK_HEADER_STDBOOL

# Checks for library functions.

# Check lua-5.1 path (lib & inc)
AC_ARG_WITH(stuff, [  --with-lua-lib 	  path to the liblua5.1 install root])
if test "$with_lua_lib" != ""
then
	AC_SUBST(LUALIBPATH, $with_lua_lib)
else
	if echo `uname` | grep -q "FreeBSD"
	then
		AC_SUBST(LUALIBPATH, /usr/local/lib)
	fi
	if echo `uname` | grep -q "Linux"
	then
		AC_SUBST(LUALIBPATH, /usr/lib)
	fi
fi

a=1
AC_CHECK_LIB(lua-5.1,lua_close,,[a=0],)
if test $a == 1
then
	AC_SUBST(LIBLUANAME, -llua-5.1)
else
	b=1
	AC_CHECK_LIB(lua5.1,lua_close,,[b=0],)
	if test $b == 1
	then
		AC_SUBST(LIBLUANAME, -llua5.1)
	else
		c=1
		AC_CHECK_LIB(lua,lua_close,,[c=0],)
		if test $c == 1
		then
			AC_SUBST(LIBLUANAME, -llua)
		fi
	fi
fi

a=1
AC_CHECK_LIB(tolua++-5.1,tolua_function,,[a=0],)
if test $a == 1
then
	AC_SUBST(LIBLUANAME, -llua++-5.1)
else
	b=1
	AC_CHECK_LIB(tolua++5.1,tolua_function,,[b=0],)
	if test $b == 1
	then
		AC_SUBST(LIBLUANAME, -ltolua++5.1)
	else
		c=1
		AC_CHECK_LIB(tolua++,tolua_function,,[c=0],)
		if test $c == 1
		then
			AC_SUBST(LIBLUANAME, -ltolua++)
		fi
	fi
fi

AC_ARG_WITH(stuff, [  --with-lua-include	  path to the lua5.1 header install root])
if test "$with_lua_include" != ""
then
	AC_SUBST(LUAINCPATH, $with_lua_include)
else
	if echo `uname` | grep -q "FreeBSD"
	then
		AC_SUBST(LUAINCPATH, /usr/local/include/lua51)
	fi
	if echo `uname` | grep -q "Linux"
	then
		AC_SUBST(LUAINCPATH, /usr/include/lua5.1)
	fi
fi

AC_DEFINE(MAX_PATH, PATH_MAX, [Defines max path length])
AC_DEFINE(LUA_USE_LINUX, [], [Set LUA to be used])

AC_OUTPUT
