#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT([sjsamplus], [1.0], [cizo2000@gmail.com])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([Makefile])

AM_INIT_AUTOMAKE([1.15])

# Checks for programs.
AC_PROG_CXX
AC_PROG_CC

# Checks for libraries.

# Checks for header files.
AC_CHECK_HEADERS([fcntl.h stdlib.h string.h sys/time.h unistd.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_CHECK_HEADER_STDBOOL
AC_TYPE_SIZE_T

# Checks for library functions.
AC_FUNC_MALLOC
AC_FUNC_REALLOC
AC_CHECK_FUNCS([floor gettimeofday memset strchr strdup strstr])

have_lua=no

AX_PROG_LUA([5.1],[], [have_lua=yes], [have_lua=no])

if test $have_lua = no; then
	AC_MSG_ERROR([A Lua library is required, and none was found; aborting...])
else
	AX_LUA_HEADERS()
	AX_LUA_LIBS()
fi

have_toluapp=no
have_toluapp_h=no

AC_CHECK_HEADER([tolua++.h], [have_toluapp_h=yes], [have_toluapp_h=no])

for toluapp_lib_name in tolua++ tolua++5.1 tolua++-5.1 tolua++51; do
	AC_CHECK_LIB([$toluapp_lib_name], [tolua_function], [have_toluapp=yes], [have_toluapp=no], [$LUA_LIB])
    if test $have_toluapp = yes; then
        AC_SUBST([libtoluapp_CFLAGS], ["$toluapp_include_flags"])
        AC_SUBST([libtoluapp_LIBS], ["-l$toluapp_lib_name"])
        break
    fi
done

if test $have_toluapp = no; then
	AC_MSG_ERROR([A tolua++ library is required, and none was found; aborting...])
fi

AC_DEFINE(MAX_PATH, PATH_MAX, [Defines max path length])
AC_DEFINE(LUA_USE_LINUX, [], [Set LUA to be used])

AC_OUTPUT
