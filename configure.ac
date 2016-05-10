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

AC_DEFUN([CHECK_SUBDIR_HEADER], [
    _SAVED_CPPFLAGS="$CPPFLAGS"
    AC_MSG_CHECKING([for $2 include dir])
    _check_subdir_header_dir=""
    for _check_subdir_header_root in "$includedir" "/usr/local/include" "/usr/include" "/usr"
    do
      for _check_subdir_header_sfx in $3; do
		_check_subdir_header_dir="$_check_subdir_header_root/$_check_subdir_header_sfx"
		CPPFLAGS="$_SAVED_CPPFLAGS -I$_check_subdir_header_dir"
		AC_COMPILE_IFELSE([AC_LANG_SOURCE([[#include $2]])], [break 2])
		_check_subdir_header_dir=""
      done
    done
    CPPFLAGS="$_SAVED_CPPFLAGS"
    _check_subdir_header_result=
    if test x"$_check_subdir_header_dir" != x""; then
      _check_subdir_header_result="$_check_subdir_header_dir"
      $1="$_check_subdir_header_dir"
      $4
    else
      _check_subdir_header_result=none
      $1=""
      $5
    fi
    AC_MSG_RESULT([$_check_subdir_header_result])
])

AC_LANG_PUSH(C++)
have_lua_h=no
lua_include_flags=""
AC_CHECK_HEADER([<lua.h>], [have_lua_h=yes],[have_lua_h=no], [$liblua_CFLAGS])
if test $have_lua_h = no; then
	CHECK_SUBDIR_HEADER(
	   [lua_include_dir], [<lua.h>],
	   [lua5.1 lua-5.1 lua51 lua],
	   [have_lua_h=yes; lua_include_flags="-I$lua_include_dir"])
fi
if test $have_lua_h = yes; then
	for lua_lib_name in lua lua5.1 lua-5.1 lua51; do
	  	AC_CHECK_LIB([$lua_lib_name], [lua_close], [have_liblua=yes], [have_liblua=no])
	  	if test $have_liblua = yes; then
			AC_SUBST([liblua_CFLAGS], ["$lua_include_flags"])
			AC_SUBST([liblua_LIBS], ["-l$lua_lib_name"])
			break
		fi
	done
fi

if test "$have_liblua" = no; then
  AC_MSG_ERROR([A Lua library is required, and none was found; aborting...])
fi

have_toluapp_h=no
toluapp_include_flags=""
#AC_CHECK_HEADER(<tolua++.h>, [have_toluapp_h=yes],[have_toluapp_h=no], [$lua_include_flags])
AC_CHECK_HEADER([<tolua++.h>], [have_toluapp_h=yes])
#if test $have_toluapp_h = no; then
#	CHECK_SUBDIR_HEADER(
#	   [toluapp_include_dir], [<tolua++.h>],
#	   [tolua++5.1 tolua++-5.1 tolua++51 tolua++ include],
#	   [have_toluapp_h=yes; toluapp_include_flags="-I$toluapp_include_dir"])
#fi
#if test $have_toluapp_h = yes; then
	for toluapp_lib_name in tolua++ tolua++5.1 tolua++-5.1 tolua++51; do
	AC_CHECK_LIB([$toluapp_lib_name], [tolua_function], [have_libtoluapp=yes], [have_libtoluapp=no], [$liblua_LIBS])
	  	if test $have_libtoluapp = yes; then
			AC_SUBST([libtoluapp_CFLAGS], ["$toluapp_include_flags"])
			AC_SUBST([libtoluapp_LIBS], ["-l$toluapp_lib_name"])
			break
		fi
	done
#fi

AC_LANG_POP(C++)


if test "$have_libtoluapp" = no; then
  AC_MSG_ERROR([A tolua++ library is required, and none was found; aborting...])
fi


AC_DEFINE(MAX_PATH, PATH_MAX, [Defines max path length])
AC_DEFINE(LUA_USE_LINUX, [], [Set LUA to be used])

AC_OUTPUT
