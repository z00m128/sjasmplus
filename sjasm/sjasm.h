/*

  SjASMPlus Z80 Cross Compiler

  This is modified sources of SjASM by Aprisobal - aprisobal@tut.by

  Copyright (c) 2006 Sjoerd Mastijn

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

#ifndef __SJASM
#define __SJASM

enum EMemoryType { MT_NONE, MT_SIZE };
enum EOutputVerbosity { OV_ALL = 0, OV_WARNING, OV_ERROR, OV_NONE };

namespace Options {
	extern char SymbolListFName[LINEMAX];
	extern char ListingFName[LINEMAX];
	extern char ExportFName[LINEMAX];
	extern char DestionationFName[LINEMAX];
	extern char RAWFName[LINEMAX];
	extern char UnrealLabelListFName[LINEMAX];

	extern EOutputVerbosity OutputVerbosity;
	extern bool IsPseudoOpBOF;
	extern bool IsAutoReloc;
	extern bool IsLabelTableInListing;
	extern bool IsDefaultListingName;
	extern bool IsReversePOP;
	extern bool IsShowFullPath;
	extern bool AddLabelListing;
	extern bool NoDestinationFile;
	extern bool FakeInstructions;
	extern bool IsNextEnabled;

	extern CStringsList* IncludeDirsList;
	extern CDefineTable CmdDefineTable;

	//extern EMemoryType MemoryType;
} // eof namespace Options

extern CDevice *Devices;
extern CDevice *Device;
extern CDeviceSlot *Slot;
extern CDevicePage *Page;
extern char* DeviceID;

// extend
extern char filename[LINEMAX], * lp, line[LINEMAX], temp[LINEMAX], ErrorLine[LINEMAX2], * bp;
extern char mline[LINEMAX2], sline[LINEMAX2], sline2[LINEMAX2];

extern char SourceFNames[128][MAX_PATH];
extern int CurrentSourceFName;

extern int ConvertEncoding;
extern int pass, IsLabelNotFound, ErrorCount, WarningCount, IncludeLevel, IsRunning, donotlist, listmacro;
extern int adrdisp, PseudoORG;
extern char* MemoryRAM, * MemoryPointer;
extern int MemoryCPage, MemoryPagesCount, StartAddress;
extern aint MemorySize;
extern int macronummer, lijst, reglenwidth;
extern aint CurAddress, AddressOfMAP, CurrentSourceLine, CompiledCurrentLine, destlen, size, PreviousErrorLine, maxlin, comlin;

extern void (*GetCPUInstruction)(void);
extern char* ModuleName, * vorlabp, * macrolabp, * LastParsedLabel;

extern FILE* FP_ListingFile;

enum EEncoding { ENCDOS, ENCWIN };
extern char* CurrentDirectory;

void ExitASM(int p);
extern CStringsList* lijstp;
extern stack< SRepeatStack> RepeatStack;

extern CLabelTable LabelTable;
extern CLocalLabelTable LocalLabelTable;
extern CDefineTable DefineTable;
extern CMacroDefineTable MacroDefineTable;
extern CMacroTable MacroTable;
extern CStructureTable StructureTable;
extern CAddressList* AddressList;
extern CStringsList* ModuleList;

#ifdef USE_LUA

extern lua_State *LUA;
extern int LuaLine;

#endif //USE_LUA

#endif
//eof sjasm.h
