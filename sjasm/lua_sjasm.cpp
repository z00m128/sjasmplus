/*
** Lua binding: sjasm
** Generated automatically by tolua++-1.0.92 on 05/13/07 22:42:31.
*/

#ifndef __cplusplus
#include "stdlib.h"
#endif
#include "string.h"

#include "tolua++.h"

/* Exported function */
TOLUA_API int  tolua_sjasm_open (lua_State* tolua_S);

#include "sjdefs.h"
using namespace Options;

/* function to register type */
static void tolua_reg_types (lua_State* tolua_S)
{
 tolua_usertype(tolua_S,"TCHAR");
}

/* function: DefineTable.Get */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_get_define00
static int tolua_sjasm_sj_get_define00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* tolua_var_1 = ((char*)  tolua_tostring(tolua_S,1,0));
  {
   char* tolua_ret = (char*)  DefineTable.Get(tolua_var_1);
   tolua_pushstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'get_define'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: DefineTable.Replace */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_insert_define00
static int tolua_sjasm_sj_insert_define00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* tolua_var_2 = ((char*)  tolua_tostring(tolua_S,1,0));
  char* tolua_var_3 = ((char*)  tolua_tostring(tolua_S,2,0));
  {
   bool tolua_ret = (bool)  DefineTable.Replace(tolua_var_2,tolua_var_3);
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'insert_define'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: LuaGetLabel */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_get_label00
static int tolua_sjasm_sj_get_label00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* tolua_var_4 = ((char*)  tolua_tostring(tolua_S,1,0));
  {
   int tolua_ret = (int)  LuaGetLabel(tolua_var_4);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'get_label'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: LabelTable.Insert */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_insert_label00
static int tolua_sjasm_sj_insert_label00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_isboolean(tolua_S,3,1,&tolua_err) ||
     !tolua_isboolean(tolua_S,4,1,&tolua_err) ||
     !tolua_isnoobj(tolua_S,5,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* tolua_var_5 = ((char*)  tolua_tostring(tolua_S,1,0));
  unsigned int tolua_var_6 = ((unsigned int)  tolua_tonumber(tolua_S,2,0));
  bool tolua_var_7 = ((bool)  tolua_toboolean(tolua_S,3,false));
  bool tolua_var_8 = ((bool)  tolua_toboolean(tolua_S,4,false));
  {
   bool tolua_ret = (bool)  LabelTable.Insert(tolua_var_5,tolua_var_6,tolua_var_7,tolua_var_8);
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'insert_label'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* get function: CurAddress */
#ifndef TOLUA_DISABLE_tolua_get_sj_unsigned_current_address
static int tolua_get_sj_unsigned_current_address(lua_State* tolua_S)
{
  tolua_pushnumber(tolua_S,(lua_Number)CurAddress);
  CheckPage();
 return 1;
}
#endif //#ifndef TOLUA_DISABLE

/* get function: WarningCount */
#ifndef TOLUA_DISABLE_tolua_get_sj_warning_count
static int tolua_get_sj_warning_count(lua_State* tolua_S)
{
  tolua_pushnumber(tolua_S,(lua_Number)WarningCount);
 return 1;
}
#endif //#ifndef TOLUA_DISABLE

/* get function: ErrorCount */
#ifndef TOLUA_DISABLE_tolua_get_sj_error_count
static int tolua_get_sj_error_count(lua_State* tolua_S)
{
  tolua_pushnumber(tolua_S,(lua_Number)ErrorCount);
 return 1;
}
#endif //#ifndef TOLUA_DISABLE

/* function: LuaShellExec */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_shellexec00
static int tolua_sjasm_sj_shellexec00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* command = ((char*)  tolua_tostring(tolua_S,1,0));
  {
   LuaShellExec(command);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'shellexec'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: TRD_SaveEmpty */
#ifndef TOLUA_DISABLE_tolua_sjasm_zx_trdimage_create00
static int tolua_sjasm_zx_trdimage_create00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* fname = ((char*)  tolua_tostring(tolua_S,1,0));
  {
   int tolua_ret = (int)  TRD_SaveEmpty(fname);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'trdimage_create'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: TRD_AddFile */
#ifndef TOLUA_DISABLE_tolua_sjasm_zx_trdimage_add_file00
static int tolua_sjasm_zx_trdimage_add_file00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,4,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,5,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* fname = ((char*)  tolua_tostring(tolua_S,1,0));
  char* fhobname = ((char*)  tolua_tostring(tolua_S,2,0));
  int start = ((int)  tolua_tonumber(tolua_S,3,0));
  int length = ((int)  tolua_tonumber(tolua_S,4,0));
  {
   int tolua_ret = (int)  TRD_AddFile(fname,fhobname,start,length);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'trdimage_add_file'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: SaveSNA_ZX */
#ifndef TOLUA_DISABLE_tolua_sjasm_zx_save_snapshot_sna12800
static int tolua_sjasm_zx_save_snapshot_sna12800(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* fname = ((char*)  tolua_tostring(tolua_S,1,0));
  unsigned short start = ((unsigned short)  tolua_tonumber(tolua_S,2,0));
  {
   int tolua_ret = (int)  SaveSNA_ZX(fname,start);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'save_snapshot_sna128'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* get function: CurrentDirectory */
#ifndef TOLUA_DISABLE_tolua_get_sj_current_path
static int tolua_get_sj_current_path(lua_State* tolua_S)
{
  tolua_pushstring(tolua_S,(const char*)CurrentDirectory);
 return 1;
}
#endif //#ifndef TOLUA_DISABLE

/* function: ExitASM */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_exit00
static int tolua_sjasm_sj_exit00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isnumber(tolua_S,1,1,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  int p = ((int)  tolua_tonumber(tolua_S,1,1));
  {
   ExitASM(p);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'exit'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: Error */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_error00
static int tolua_sjasm_sj_error00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,1,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,1,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* tolua_var_9 = ((char*)  tolua_tostring(tolua_S,1,0));
  char* tolua_var_10 = ((char*)  tolua_tostring(tolua_S,2,0));
  int tolua_var_11 = ((int)  tolua_tonumber(tolua_S,3,0));
  {
   Error(tolua_var_9,tolua_var_10,tolua_var_11);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'error'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: Warning */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_warning00
static int tolua_sjasm_sj_warning00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isstring(tolua_S,2,1,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,1,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* tolua_var_12 = ((char*)  tolua_tostring(tolua_S,1,0));
  char* tolua_var_13 = ((char*)  tolua_tostring(tolua_S,2,0));
  int tolua_var_14 = ((int)  tolua_tonumber(tolua_S,3,0));
  {
   Warning(tolua_var_12,tolua_var_13,tolua_var_14);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'warning'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: FileExists */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_file_exists00
static int tolua_sjasm_sj_file_exists00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* filename = ((char*)  tolua_tostring(tolua_S,1,0));
  {
   bool tolua_ret = (bool)  FileExists(filename);
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'file_exists'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: GetPath */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_get_path00
static int tolua_sjasm_sj_get_path00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isusertype(tolua_S,2,"TCHAR",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* fname = ((char*)  tolua_tostring(tolua_S,1,0));
  TCHAR* filenamebegin = ((TCHAR*)  tolua_tousertype(tolua_S,2,0));
  {
   char* tolua_ret = (char*)  GetPath(fname,&filenamebegin);
   tolua_pushstring(tolua_S,(const char*)tolua_ret);
   tolua_pushusertype(tolua_S,(void*)filenamebegin,"TCHAR");
  }
 }
 return 2;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'get_path'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: SetDevice */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_set_device00
static int tolua_sjasm_sj_set_device00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* id = ((char*)  tolua_tostring(tolua_S,1,0));
  {
   bool tolua_ret = (bool)  SetDevice(id);
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'set_device'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: GetDeviceName */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_get_device00
static int tolua_sjasm_sj_get_device00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isnoobj(tolua_S,1,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  {
   char* tolua_ret = (char*)  GetDeviceName();
   tolua_pushstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'get_device'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: LuaSetPage */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_set_page00
static int tolua_sjasm_sj_set_page00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isnumber(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  unsigned int n = ((unsigned int)  tolua_tonumber(tolua_S,1,0));
  {
   bool tolua_ret = (bool)  LuaSetPage(n);
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'set_page'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: LuaSetSlot */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_set_slot00
static int tolua_sjasm_sj_set_slot00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isnumber(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  unsigned int n = ((unsigned int)  tolua_tonumber(tolua_S,1,0));
  {
   bool tolua_ret = (bool)  LuaSetSlot(n);
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'set_slot'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: MemGetByte */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_get_byte00
static int tolua_sjasm_sj_get_byte00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isnumber(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  unsigned int address = ((unsigned int)  tolua_tonumber(tolua_S,1,0));
  {
   unsigned char tolua_ret = (unsigned char)  MemGetByte(address);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'get_byte'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: MemGetWord */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_get_word00
static int tolua_sjasm_sj_get_word00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isnumber(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  unsigned int address = ((unsigned int)  tolua_tonumber(tolua_S,1,0));
  {
   unsigned char tolua_ret = (unsigned char)  MemGetWord(address);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'get_word'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: EmitByte */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_add_byte00
static int tolua_sjasm_sj_add_byte00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isnumber(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  unsigned char byte = ((unsigned char)  tolua_tonumber(tolua_S,1,0));
  {
   EmitByte(byte);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'add_byte'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: EmitWord */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_add_word00
static int tolua_sjasm_sj_add_word00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isnumber(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  unsigned int word = ((unsigned int)  tolua_tonumber(tolua_S,1,0));
  {
   EmitWord(word);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'add_word'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: LuaCalculate */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_calc00
static int tolua_sjasm_sj_calc00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* str = ((char*)  tolua_tostring(tolua_S,1,0));
  {
   unsigned long tolua_ret = (unsigned long)  LuaCalculate(str);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'calc'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: LuaParseLine */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_parse_line00
static int tolua_sjasm_sj_parse_line00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* str = ((char*)  tolua_tostring(tolua_S,1,0));
  {
   LuaParseLine(str);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'parse_line'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: LuaParseCode */
#ifndef TOLUA_DISABLE_tolua_sjasm_sj_parse_code00
static int tolua_sjasm_sj_parse_code00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* str = ((char*)  tolua_tostring(tolua_S,1,0));
  {
   LuaParseCode(str);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'parse_code'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: LuaCalculate */
#ifndef TOLUA_DISABLE_tolua_sjasm__c00
static int tolua_sjasm__c00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* str = ((char*)  tolua_tostring(tolua_S,1,0));
  {
   unsigned long tolua_ret = (unsigned long)  LuaCalculate(str);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function '_c'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: LuaParseLine */
#ifndef TOLUA_DISABLE_tolua_sjasm__pl00
static int tolua_sjasm__pl00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* str = ((char*)  tolua_tostring(tolua_S,1,0));
  {
   LuaParseLine(str);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function '_pl'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* function: LuaParseCode */
#ifndef TOLUA_DISABLE_tolua_sjasm__pc00
static int tolua_sjasm__pc00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isstring(tolua_S,1,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  char* str = ((char*)  tolua_tostring(tolua_S,1,0));
  {
   LuaParseCode(str);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function '_pc'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* Open function */
TOLUA_API int tolua_sjasm_open (lua_State* tolua_S)
{
 tolua_open(tolua_S);
 tolua_reg_types(tolua_S);
 tolua_module(tolua_S,NULL,0);
 tolua_beginmodule(tolua_S,NULL);
  tolua_module(tolua_S,"sj",0);
  tolua_beginmodule(tolua_S,"sj");
   tolua_function(tolua_S,"get_define",tolua_sjasm_sj_get_define00);
   tolua_function(tolua_S,"insert_define",tolua_sjasm_sj_insert_define00);
   tolua_function(tolua_S,"get_label",tolua_sjasm_sj_get_label00);
   tolua_function(tolua_S,"insert_label",tolua_sjasm_sj_insert_label00);
  tolua_endmodule(tolua_S);
  tolua_module(tolua_S,"sj",1);
  tolua_beginmodule(tolua_S,"sj");
   tolua_variable(tolua_S,"current_address",tolua_get_sj_unsigned_current_address,NULL);
   tolua_variable(tolua_S,"warning_count",tolua_get_sj_warning_count,NULL);
   tolua_variable(tolua_S,"error_count",tolua_get_sj_error_count,NULL);
   tolua_function(tolua_S,"shellexec",tolua_sjasm_sj_shellexec00);
  tolua_endmodule(tolua_S);
  tolua_module(tolua_S,"zx",0);
  tolua_beginmodule(tolua_S,"zx");
   tolua_function(tolua_S,"trdimage_create",tolua_sjasm_zx_trdimage_create00);
   tolua_function(tolua_S,"trdimage_add_file",tolua_sjasm_zx_trdimage_add_file00);
   tolua_function(tolua_S,"save_snapshot_sna",tolua_sjasm_zx_save_snapshot_sna12800);
  tolua_endmodule(tolua_S);
  tolua_module(tolua_S,"sj",1);
  tolua_beginmodule(tolua_S,"sj");
   tolua_variable(tolua_S,"current_path",tolua_get_sj_current_path,NULL);
   tolua_function(tolua_S,"exit",tolua_sjasm_sj_exit00);
  tolua_endmodule(tolua_S);
  tolua_module(tolua_S,"sj",0);
  tolua_beginmodule(tolua_S,"sj");
   tolua_function(tolua_S,"error",tolua_sjasm_sj_error00);
   tolua_function(tolua_S,"warning",tolua_sjasm_sj_warning00);
   tolua_function(tolua_S,"file_exists",tolua_sjasm_sj_file_exists00);
   tolua_function(tolua_S,"get_path",tolua_sjasm_sj_get_path00);
   tolua_function(tolua_S,"set_device",tolua_sjasm_sj_set_device00);
   tolua_function(tolua_S,"get_device",tolua_sjasm_sj_get_device00);
   tolua_function(tolua_S,"set_page",tolua_sjasm_sj_set_page00);
   tolua_function(tolua_S,"set_slot",tolua_sjasm_sj_set_slot00);
   tolua_function(tolua_S,"get_byte",tolua_sjasm_sj_get_byte00);
   tolua_function(tolua_S,"get_word",tolua_sjasm_sj_get_word00);
   tolua_function(tolua_S,"add_byte",tolua_sjasm_sj_add_byte00);
   tolua_function(tolua_S,"add_word",tolua_sjasm_sj_add_word00);
   tolua_function(tolua_S,"calc",tolua_sjasm_sj_calc00);
   tolua_function(tolua_S,"parse_line",tolua_sjasm_sj_parse_line00);
   tolua_function(tolua_S,"parse_code",tolua_sjasm_sj_parse_code00);
  tolua_endmodule(tolua_S);
  tolua_function(tolua_S,"_c",tolua_sjasm__c00);
  tolua_function(tolua_S,"_pl",tolua_sjasm__pl00);
  tolua_function(tolua_S,"_pc",tolua_sjasm__pc00);

  { /* begin embedded lua code */
   int top = lua_gettop(tolua_S);
   static unsigned char B[] = {
    10, 76,117, 97, 66,105,116, 32,118, 48, 46, 51, 10, 97, 32,
     98,105,116,119,105,115,101, 32,111,112,101,114, 97,116,105,
    111,110, 32,108,105, 98, 32,102,111,114, 32,108,117, 97, 46,
     10,104,116,116,112, 58, 47, 47,108,117, 97,102,111,114,103,
    101, 46,110,101,116, 47,112,114,111,106,101, 99,116,115, 47,
     98,105,116, 47, 10, 85,110,100,101,114, 32,116,104,101, 32,
     77, 73, 84, 32,108,105, 99,101,110,115,101, 46, 10, 99,111,
    112,121,114,105,103,104,116, 40, 99, 41, 32, 50, 48, 48, 54,
     32,104, 97,110,122,104, 97,111, 32, 40, 97, 98,114, 97,115,
    104, 95,104, 97,110, 64,104,111,116,109, 97,105,108, 46, 99,
    111,109, 41, 10,100,111, 10,108,111, 99, 97,108, 32,102,117,
    110, 99,116,105,111,110, 32, 99,104,101, 99,107, 95,105,110,
    116, 40,110, 41, 10,105,102, 40,110, 32, 45, 32,109, 97,116,
    104, 46,102,108,111,111,114, 40,110, 41, 32, 62, 32, 48, 41,
     32,116,104,101,110, 10,101,114,114,111,114, 40, 34,116,114,
    121,105,110,103, 32,116,111, 32,117,115,101, 32, 98,105,116,
    119,105,115,101, 32,111,112,101,114, 97,116,105,111,110, 32,
    111,110, 32,110,111,110, 45,105,110,116,101,103,101,114, 33,
     34, 41, 10,101,110,100, 10,101,110,100, 10,108,111, 99, 97,
    108, 32,102,117,110, 99,116,105,111,110, 32,116,111, 95, 98,
    105,116,115, 40,110, 41, 10, 99,104,101, 99,107, 95,105,110,
    116, 40,110, 41, 10,105,102, 40,110, 32, 60, 32, 48, 41, 32,
    116,104,101,110, 10,114,101,116,117,114,110, 32,116,111, 95,
     98,105,116,115, 40, 98,105,116, 46, 98,110,111,116, 40,109,
     97,116,104, 46, 97, 98,115, 40,110, 41, 41, 32, 43, 32, 49,
     41, 10,101,110,100, 10,108,111, 99, 97,108, 32,116, 98,108,
     32, 61, 32,123,125, 10,108,111, 99, 97,108, 32, 99,110,116,
     32, 61, 32, 49, 10,119,104,105,108,101, 32, 40,110, 32, 62,
     32, 48, 41, 32,100,111, 10,108,111, 99, 97,108, 32,108, 97,
    115,116, 32, 61, 32,109, 97,116,104, 46,109,111,100, 40,110,
     44, 50, 41, 10,105,102, 40,108, 97,115,116, 32, 61, 61, 32,
     49, 41, 32,116,104,101,110, 10,116, 98,108, 91, 99,110,116,
     93, 32, 61, 32, 49, 10,101,108,115,101, 10,116, 98,108, 91,
     99,110,116, 93, 32, 61, 32, 48, 10,101,110,100, 10,110, 32,
     61, 32, 40,110, 45,108, 97,115,116, 41, 47, 50, 10, 99,110,
    116, 32, 61, 32, 99,110,116, 32, 43, 32, 49, 10,101,110,100,
     10,114,101,116,117,114,110, 32,116, 98,108, 10,101,110,100,
     10,108,111, 99, 97,108, 32,102,117,110, 99,116,105,111,110,
     32,116, 98,108, 95,116,111, 95,110,117,109, 98,101,114, 40,
    116, 98,108, 41, 10,108,111, 99, 97,108, 32,110, 32, 61, 32,
    116, 97, 98,108,101, 46,103,101,116,110, 40,116, 98,108, 41,
     10,108,111, 99, 97,108, 32,114,115,108,116, 32, 61, 32, 48,
     10,108,111, 99, 97,108, 32,112,111,119,101,114, 32, 61, 32,
     49, 10,102,111,114, 32,105, 32, 61, 32, 49, 44, 32,110, 32,
    100,111, 10,114,115,108,116, 32, 61, 32,114,115,108,116, 32,
     43, 32,116, 98,108, 91,105, 93, 42,112,111,119,101,114, 10,
    112,111,119,101,114, 32, 61, 32,112,111,119,101,114, 42, 50,
     10,101,110,100, 10,114,101,116,117,114,110, 32,114,115,108,
    116, 10,101,110,100, 10,108,111, 99, 97,108, 32,102,117,110,
     99,116,105,111,110, 32,101,120,112, 97,110,100, 40,116, 98,
    108, 95,109, 44, 32,116, 98,108, 95,110, 41, 10,108,111, 99,
     97,108, 32, 98,105,103, 32, 61, 32,123,125, 10,108,111, 99,
     97,108, 32,115,109, 97,108,108, 32, 61, 32,123,125, 10,105,
    102, 40,116, 97, 98,108,101, 46,103,101,116,110, 40,116, 98,
    108, 95,109, 41, 32, 62, 32,116, 97, 98,108,101, 46,103,101,
    116,110, 40,116, 98,108, 95,110, 41, 41, 32,116,104,101,110,
     10, 98,105,103, 32, 61, 32,116, 98,108, 95,109, 10,115,109,
     97,108,108, 32, 61, 32,116, 98,108, 95,110, 10,101,108,115,
    101, 10, 98,105,103, 32, 61, 32,116, 98,108, 95,110, 10,115,
    109, 97,108,108, 32, 61, 32,116, 98,108, 95,109, 10,101,110,
    100, 10,102,111,114, 32,105, 32, 61, 32,116, 97, 98,108,101,
     46,103,101,116,110, 40,115,109, 97,108,108, 41, 32, 43, 32,
     49, 44, 32,116, 97, 98,108,101, 46,103,101,116,110, 40, 98,
    105,103, 41, 32,100,111, 10,115,109, 97,108,108, 91,105, 93,
     32, 61, 32, 48, 10,101,110,100, 10,101,110,100, 10,108,111,
     99, 97,108, 32,102,117,110, 99,116,105,111,110, 32, 98,105,
    116, 95,111,114, 40,109, 44, 32,110, 41, 10,108,111, 99, 97,
    108, 32,116, 98,108, 95,109, 32, 61, 32,116,111, 95, 98,105,
    116,115, 40,109, 41, 10,108,111, 99, 97,108, 32,116, 98,108,
     95,110, 32, 61, 32,116,111, 95, 98,105,116,115, 40,110, 41,
     10,101,120,112, 97,110,100, 40,116, 98,108, 95,109, 44, 32,
    116, 98,108, 95,110, 41, 10,108,111, 99, 97,108, 32,116, 98,
    108, 32, 61, 32,123,125, 10,108,111, 99, 97,108, 32,114,115,
    108,116, 32, 61, 32,109, 97,116,104, 46,109, 97,120, 40,116,
     97, 98,108,101, 46,103,101,116,110, 40,116, 98,108, 95,109,
     41, 44, 32,116, 97, 98,108,101, 46,103,101,116,110, 40,116,
     98,108, 95,110, 41, 41, 10,102,111,114, 32,105, 32, 61, 32,
     49, 44, 32,114,115,108,116, 32,100,111, 10,105,102, 40,116,
     98,108, 95,109, 91,105, 93, 61, 61, 32, 48, 32, 97,110,100,
     32,116, 98,108, 95,110, 91,105, 93, 32, 61, 61, 32, 48, 41,
     32,116,104,101,110, 10,116, 98,108, 91,105, 93, 32, 61, 32,
     48, 10,101,108,115,101, 10,116, 98,108, 91,105, 93, 32, 61,
     32, 49, 10,101,110,100, 10,101,110,100, 10,114,101,116,117,
    114,110, 32,116, 98,108, 95,116,111, 95,110,117,109, 98,101,
    114, 40,116, 98,108, 41, 10,101,110,100, 10,108,111, 99, 97,
    108, 32,102,117,110, 99,116,105,111,110, 32, 98,105,116, 95,
     97,110,100, 40,109, 44, 32,110, 41, 10,108,111, 99, 97,108,
     32,116, 98,108, 95,109, 32, 61, 32,116,111, 95, 98,105,116,
    115, 40,109, 41, 10,108,111, 99, 97,108, 32,116, 98,108, 95,
    110, 32, 61, 32,116,111, 95, 98,105,116,115, 40,110, 41, 10,
    101,120,112, 97,110,100, 40,116, 98,108, 95,109, 44, 32,116,
     98,108, 95,110, 41, 10,108,111, 99, 97,108, 32,116, 98,108,
     32, 61, 32,123,125, 10,108,111, 99, 97,108, 32,114,115,108,
    116, 32, 61, 32,109, 97,116,104, 46,109, 97,120, 40,116, 97,
     98,108,101, 46,103,101,116,110, 40,116, 98,108, 95,109, 41,
     44, 32,116, 97, 98,108,101, 46,103,101,116,110, 40,116, 98,
    108, 95,110, 41, 41, 10,102,111,114, 32,105, 32, 61, 32, 49,
     44, 32,114,115,108,116, 32,100,111, 10,105,102, 40,116, 98,
    108, 95,109, 91,105, 93, 61, 61, 32, 48, 32,111,114, 32,116,
     98,108, 95,110, 91,105, 93, 32, 61, 61, 32, 48, 41, 32,116,
    104,101,110, 10,116, 98,108, 91,105, 93, 32, 61, 32, 48, 10,
    101,108,115,101, 10,116, 98,108, 91,105, 93, 32, 61, 32, 49,
     10,101,110,100, 10,101,110,100, 10,114,101,116,117,114,110,
     32,116, 98,108, 95,116,111, 95,110,117,109, 98,101,114, 40,
    116, 98,108, 41, 10,101,110,100, 10,108,111, 99, 97,108, 32,
    102,117,110, 99,116,105,111,110, 32, 98,105,116, 95,110,111,
    116, 40,110, 41, 10,108,111, 99, 97,108, 32,116, 98,108, 32,
     61, 32,116,111, 95, 98,105,116,115, 40,110, 41, 10,108,111,
     99, 97,108, 32,115,105,122,101, 32, 61, 32,109, 97,116,104,
     46,109, 97,120, 40,116, 97, 98,108,101, 46,103,101,116,110,
     40,116, 98,108, 41, 44, 32, 51, 50, 41, 10,102,111,114, 32,
    105, 32, 61, 32, 49, 44, 32,115,105,122,101, 32,100,111, 10,
    105,102, 40,116, 98,108, 91,105, 93, 32, 61, 61, 32, 49, 41,
     32,116,104,101,110, 10,116, 98,108, 91,105, 93, 32, 61, 32,
     48, 10,101,108,115,101, 10,116, 98,108, 91,105, 93, 32, 61,
     32, 49, 10,101,110,100, 10,101,110,100, 10,114,101,116,117,
    114,110, 32,116, 98,108, 95,116,111, 95,110,117,109, 98,101,
    114, 40,116, 98,108, 41, 10,101,110,100, 10,108,111, 99, 97,
    108, 32,102,117,110, 99,116,105,111,110, 32, 98,105,116, 95,
    120,111,114, 40,109, 44, 32,110, 41, 10,108,111, 99, 97,108,
     32,116, 98,108, 95,109, 32, 61, 32,116,111, 95, 98,105,116,
    115, 40,109, 41, 10,108,111, 99, 97,108, 32,116, 98,108, 95,
    110, 32, 61, 32,116,111, 95, 98,105,116,115, 40,110, 41, 10,
    101,120,112, 97,110,100, 40,116, 98,108, 95,109, 44, 32,116,
     98,108, 95,110, 41, 10,108,111, 99, 97,108, 32,116, 98,108,
     32, 61, 32,123,125, 10,108,111, 99, 97,108, 32,114,115,108,
    116, 32, 61, 32,109, 97,116,104, 46,109, 97,120, 40,116, 97,
     98,108,101, 46,103,101,116,110, 40,116, 98,108, 95,109, 41,
     44, 32,116, 97, 98,108,101, 46,103,101,116,110, 40,116, 98,
    108, 95,110, 41, 41, 10,102,111,114, 32,105, 32, 61, 32, 49,
     44, 32,114,115,108,116, 32,100,111, 10,105,102, 40,116, 98,
    108, 95,109, 91,105, 93, 32,126, 61, 32,116, 98,108, 95,110,
     91,105, 93, 41, 32,116,104,101,110, 10,116, 98,108, 91,105,
     93, 32, 61, 32, 49, 10,101,108,115,101, 10,116, 98,108, 91,
    105, 93, 32, 61, 32, 48, 10,101,110,100, 10,101,110,100, 10,
    114,101,116,117,114,110, 32,116, 98,108, 95,116,111, 95,110,
    117,109, 98,101,114, 40,116, 98,108, 41, 10,101,110,100, 10,
    108,111, 99, 97,108, 32,102,117,110, 99,116,105,111,110, 32,
     98,105,116, 95,114,115,104,105,102,116, 40,110, 44, 32, 98,
    105,116,115, 41, 10, 99,104,101, 99,107, 95,105,110,116, 40,
    110, 41, 10,108,111, 99, 97,108, 32,104,105,103,104, 95, 98,
    105,116, 32, 61, 32, 48, 10,105,102, 40,110, 32, 60, 32, 48,
     41, 32,116,104,101,110, 10,110, 32, 61, 32, 98,105,116, 95,
    110,111,116, 40,109, 97,116,104, 46, 97, 98,115, 40,110, 41,
     41, 32, 43, 32, 49, 10,104,105,103,104, 95, 98,105,116, 32,
     61, 32, 50, 49, 52, 55, 52, 56, 51, 54, 52, 56, 10,101,110,
    100, 10,102,111,114, 32,105, 61, 49, 44, 32, 98,105,116,115,
     32,100,111, 10,110, 32, 61, 32,110, 47, 50, 10,110, 32, 61,
     32, 98,105,116, 95,111,114, 40,109, 97,116,104, 46,102,108,
    111,111,114, 40,110, 41, 44, 32,104,105,103,104, 95, 98,105,
    116, 41, 10,101,110,100, 10,114,101,116,117,114,110, 32,109,
     97,116,104, 46,102,108,111,111,114, 40,110, 41, 10,101,110,
    100, 10,108,111, 99, 97,108, 32,102,117,110, 99,116,105,111,
    110, 32, 98,105,116, 95,108,111,103,105, 99, 95,114,115,104,
    105,102,116, 40,110, 44, 32, 98,105,116,115, 41, 10, 99,104,
    101, 99,107, 95,105,110,116, 40,110, 41, 10,105,102, 40,110,
     32, 60, 32, 48, 41, 32,116,104,101,110, 10,110, 32, 61, 32,
     98,105,116, 95,110,111,116, 40,109, 97,116,104, 46, 97, 98,
    115, 40,110, 41, 41, 32, 43, 32, 49, 10,101,110,100, 10,102,
    111,114, 32,105, 61, 49, 44, 32, 98,105,116,115, 32,100,111,
     10,110, 32, 61, 32,110, 47, 50, 10,101,110,100, 10,114,101,
    116,117,114,110, 32,109, 97,116,104, 46,102,108,111,111,114,
     40,110, 41, 10,101,110,100, 10,108,111, 99, 97,108, 32,102,
    117,110, 99,116,105,111,110, 32, 98,105,116, 95,108,115,104,
    105,102,116, 40,110, 44, 32, 98,105,116,115, 41, 10, 99,104,
    101, 99,107, 95,105,110,116, 40,110, 41, 10,105,102, 40,110,
     32, 60, 32, 48, 41, 32,116,104,101,110, 10,110, 32, 61, 32,
     98,105,116, 95,110,111,116, 40,109, 97,116,104, 46, 97, 98,
    115, 40,110, 41, 41, 32, 43, 32, 49, 10,101,110,100, 10,102,
    111,114, 32,105, 61, 49, 44, 32, 98,105,116,115, 32,100,111,
     10,110, 32, 61, 32,110, 42, 50, 10,101,110,100, 10,114,101,
    116,117,114,110, 32, 98,105,116, 95, 97,110,100, 40,110, 44,
     32, 52, 50, 57, 52, 57, 54, 55, 50, 57, 53, 41, 10,101,110,
    100, 10,108,111, 99, 97,108, 32,102,117,110, 99,116,105,111,
    110, 32, 98,105,116, 95,120,111,114, 50, 40,109, 44, 32,110,
     41, 10,108,111, 99, 97,108, 32,114,104,115, 32, 61, 32, 98,
    105,116, 95,111,114, 40, 98,105,116, 95,110,111,116, 40,109,
     41, 44, 32, 98,105,116, 95,110,111,116, 40,110, 41, 41, 10,
    108,111, 99, 97,108, 32,108,104,115, 32, 61, 32, 98,105,116,
     95,111,114, 40,109, 44, 32,110, 41, 10,108,111, 99, 97,108,
     32,114,115,108,116, 32, 61, 32, 98,105,116, 95, 97,110,100,
     40,108,104,115, 44, 32,114,104,115, 41, 10,114,101,116,117,
    114,110, 32,114,115,108,116, 10,101,110,100, 10, 98,105,116,
     32, 61, 32,123, 10, 98,110,111,116, 32, 61, 32, 98,105,116,
     95,110,111,116, 44, 10, 98, 97,110,100, 32, 61, 32, 98,105,
    116, 95, 97,110,100, 44, 10, 98,111,114, 32, 61, 32, 98,105,
    116, 95,111,114, 44, 10, 98,120,111,114, 32, 61, 32, 98,105,
    116, 95,120,111,114, 44, 10, 98,114,115,104,105,102,116, 32,
     61, 32, 98,105,116, 95,114,115,104,105,102,116, 44, 10, 98,
    108,115,104,105,102,116, 32, 61, 32, 98,105,116, 95,108,115,
    104,105,102,116, 44, 10, 98,120,111,114, 50, 32, 61, 32, 98,
    105,116, 95,120,111,114, 50, 44, 10, 98,108,111,103,105, 99,
     95,114,115,104,105,102,116, 32, 61, 32, 98,105,116, 95,108,
    111,103,105, 99, 95,114,115,104,105,102,116, 44, 10,116,111,
     98,105,116,115, 32, 61, 32,116,111, 95, 98,105,116,115, 44,
     10,116,111,110,117,109, 98, 32, 61, 32,116, 98,108, 95,116,
    111, 95,110,117,109, 98,101,114, 44, 10,125, 10,101,110,100,
     10,102,111,114, 32,105, 32, 61, 32, 49, 44, 32, 49, 48, 48,
     32,100,111, 10,102,111,114, 32,106, 32, 61, 32, 49, 44, 32,
     49, 48, 48, 32,100,111, 10,105,102, 40, 98,105,116, 46, 98,
    120,111,114, 40,105, 44, 32,106, 41, 32,126, 61, 32, 98,105,
    116, 46, 98,120,111,114, 50, 40,105, 44, 32,106, 41, 41, 32,
    116,104,101,110, 10,101,114,114,111,114, 40, 34, 98,105,116,
     46,120,111,114, 32,102, 97,105,108,101,100, 46, 34, 41, 10,
    101,110,100, 10,101,110,100, 10,101,110,100, 10,32
   };
   tolua_dobuffer(tolua_S,(char*)B,sizeof(B),"tolua: embedded Lua code 1");
   lua_settop(tolua_S, top);
  } /* end of embedded lua code */


  { /* begin embedded lua code */
   int top = lua_gettop(tolua_S);
   static unsigned char B[] = {
    10, 72,101,120, 32,118, 48, 46, 51, 10, 72,101,120, 32, 99,
    111,110,118,101,114,115,105,111,110, 32,108,105, 98, 32,102,
    111,114, 32,108,117, 97, 46, 10, 80, 97,114,116, 32,111,102,
     32, 76,117, 97, 66,105,116, 40,104,116,116,112, 58, 47, 47,
    108,117, 97,102,111,114,103,101, 46,110,101,116, 47,112,114,
    111,106,101, 99,116,115, 47, 98,105,116, 47, 41, 46, 10, 85,
    110,100,101,114, 32,116,104,101, 32, 77, 73, 84, 32,108,105,
     99,101,110,115,101, 46, 10, 99,111,112,121,114,105,103,104,
    116, 40, 99, 41, 32, 50, 48, 48, 54, 32,104, 97,110,122,104,
     97,111, 32, 40, 97, 98,114, 97,115,104, 95,104, 97,110, 64,
    104,111,116,109, 97,105,108, 46, 99,111,109, 41, 10,100,111,
     10,108,111, 99, 97,108, 32,102,117,110, 99,116,105,111,110,
     32,116,111, 95,104,101,120, 40,110, 41, 10,105,102, 40,116,
    121,112,101, 40,110, 41, 32,126, 61, 32, 34,110,117,109, 98,
    101,114, 34, 41, 32,116,104,101,110, 10,101,114,114,111,114,
     40, 34,110,111,110, 45,110,117,109, 98,101,114, 32,116,121,
    112,101, 32,112, 97,115,115,101,100, 32,105,110, 46, 34, 41,
     10,101,110,100, 10,105,102, 40,110, 32, 45, 32,109, 97,116,
    104, 46,102,108,111,111,114, 40,110, 41, 32, 62, 32, 48, 41,
     32,116,104,101,110, 10,101,114,114,111,114, 40, 34,116,114,
    121,105,110,103, 32,116,111, 32, 97,112,112,108,121, 32, 98,
    105,116,119,105,115,101, 32,111,112,101,114, 97,116,105,111,
    110, 32,111,110, 32,110,111,110, 45,105,110,116,101,103,101,
    114, 33, 34, 41, 10,101,110,100, 10,105,102, 40,110, 32, 60,
     32, 48, 41, 32,116,104,101,110, 10,110, 32, 61, 32, 98,105,
    116, 46,116,111, 98,105,116,115, 40, 98,105,116, 46, 98,110,
    111,116, 40,109, 97,116,104, 46, 97, 98,115, 40,110, 41, 41,
     32, 43, 32, 49, 41, 10,110, 32, 61, 32, 98,105,116, 46,116,
    111,110,117,109, 98, 40,110, 41, 10,101,110,100, 10,104,101,
    120, 95,116, 98,108, 32, 61, 32,123, 39, 65, 39, 44, 32, 39,
     66, 39, 44, 32, 39, 67, 39, 44, 32, 39, 68, 39, 44, 32, 39,
     69, 39, 44, 32, 39, 70, 39,125, 10,104,101,120, 95,115,116,
    114, 32, 61, 32, 34, 34, 10,119,104,105,108,101, 40,110, 32,
    126, 61, 32, 48, 41, 32,100,111, 10,108, 97,115,116, 32, 61,
     32,109, 97,116,104, 46,109,111,100, 40,110, 44, 32, 49, 54,
     41, 10,105,102, 40,108, 97,115,116, 32, 60, 32, 49, 48, 41,
     32,116,104,101,110, 10,104,101,120, 95,115,116,114, 32, 61,
     32,116,111,115,116,114,105,110,103, 40,108, 97,115,116, 41,
     32, 46, 46, 32,104,101,120, 95,115,116,114, 10,101,108,115,
    101, 10,104,101,120, 95,115,116,114, 32, 61, 32,104,101,120,
     95,116, 98,108, 91,108, 97,115,116, 45, 49, 48, 43, 49, 93,
     32, 46, 46, 32,104,101,120, 95,115,116,114, 10,101,110,100,
     10,110, 32, 61, 32,109, 97,116,104, 46,102,108,111,111,114,
     40,110, 47, 49, 54, 41, 10,101,110,100, 10,105,102, 40,104,
    101,120, 95,115,116,114, 32, 61, 61, 32, 34, 34, 41, 32,116,
    104,101,110, 10,104,101,120, 95,115,116,114, 32, 61, 32, 34,
     48, 34, 10,101,110,100, 10,114,101,116,117,114,110, 32, 34,
     48,120, 34, 32, 46, 46, 32,104,101,120, 95,115,116,114, 10,
    101,110,100, 10,108,111, 99, 97,108, 32,102,117,110, 99,116,
    105,111,110, 32,116,111, 95,100,101, 99, 40,104,101,120, 41,
     10,105,102, 40,116,121,112,101, 40,104,101,120, 41, 32,126,
     61, 32, 34,115,116,114,105,110,103, 34, 41, 32,116,104,101,
    110, 10,101,114,114,111,114, 40, 34,110,111,110, 45,115,116,
    114,105,110,103, 32,116,121,112,101, 32,112, 97,115,115,101,
    100, 32,105,110, 46, 34, 41, 10,101,110,100, 10,104,101, 97,
    100, 32, 61, 32,115,116,114,105,110,103, 46,115,117, 98, 40,
    104,101,120, 44, 32, 49, 44, 32, 50, 41, 10,105,102, 40, 32,
    104,101, 97,100, 32,126, 61, 32, 34, 48,120, 34, 32, 97,110,
    100, 32,104,101, 97,100, 32,126, 61, 32, 34, 48, 88, 34, 41,
     32,116,104,101,110, 10,101,114,114,111,114, 40, 34,119,114,
    111,110,103, 32,104,101,120, 32,102,111,114,109, 97,116, 44,
     32,115,104,111,117,108,100, 32,108,101, 97,100, 32, 98,121,
     32, 48,120, 32,111,114, 32, 48, 88, 46, 34, 41, 10,101,110,
    100, 10,118, 32, 61, 32,116,111,110,117,109, 98,101,114, 40,
    115,116,114,105,110,103, 46,115,117, 98, 40,104,101,120, 44,
     32, 51, 41, 44, 32, 49, 54, 41, 10,114,101,116,117,114,110,
     32,118, 59, 10,101,110,100, 10,104,101,120, 32, 61, 32,123,
     10,116,111, 95,100,101, 99, 32, 61, 32,116,111, 95,100,101,
     99, 44, 10,116,111, 95,104,101,120, 32, 61, 32,116,111, 95,
    104,101,120, 44, 10,125, 10,101,110,100, 10,100, 32, 61, 32,
     52, 51, 52, 49, 54, 56, 56, 10,104, 32, 61, 32,116,111, 95,
    104,101,120, 40,100, 41, 10,112,114,105,110,116, 40,104, 41,
     10,112,114,105,110,116, 40,116,111, 95,100,101, 99, 40,104,
     41, 41, 10,102,111,114, 32,105, 32, 61, 32, 49, 44, 32, 49,
     48, 48, 48, 48, 48, 32,100,111, 10,104, 32, 61, 32,104,101,
    120, 46,116,111, 95,104,101,120, 40,105, 41, 10,100, 32, 61,
     32,104,101,120, 46,116,111, 95,100,101, 99, 40,104, 41, 10,
    105,102, 40,100, 32,126, 61, 32,105, 41, 32,116,104,101,110,
     10,101,114,114,111,114, 40, 34,102, 97,105,108,101,100, 32,
     34, 32, 46, 46, 32,105, 32, 46, 46, 32, 34, 44, 32, 34, 32,
     46, 46, 32,104, 41, 10,101,110,100, 10,101,110,100, 10,32
   };
   tolua_dobuffer(tolua_S,(char*)B,sizeof(B),"tolua: embedded Lua code 2");
   lua_settop(tolua_S, top);
  } /* end of embedded lua code */

 tolua_endmodule(tolua_S);
 return 1;
}


#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM >= 501
 TOLUA_API int luaopen_sjasm (lua_State* tolua_S) {
 return tolua_sjasm_open(tolua_S);
};
#endif

