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

namespace Options {
	extern char SymbolListFName[LINEMAX];
	extern char ListingFName[LINEMAX];
	extern char ExportFName[LINEMAX];
	extern char DestionationFName[LINEMAX];
	extern char RAWFName[LINEMAX];
	extern char UnrealLabelListFName[LINEMAX];

	extern bool IsPseudoOpBOF;
	extern bool IsAutoReloc;
	extern bool IsLabelTableInListing;
	extern bool IsReversePOP;
	extern bool IsShowFullPath;
	extern bool AddLabelListing;
	extern bool NoDestinationFile;
	extern bool FakeInstructions;

	extern CStringsList* IncludeDirsList;

	//extern EMemoryType MemoryType;
} // eof namespace Options

extern CDevice *Devices;
extern CDevice *Device;
extern CDeviceSlot *Slot;
extern CDevicePage *Page;
extern char* DeviceID;

// extend
extern char filename[LINEMAX], * lp, line[LINEMAX], temp[LINEMAX], * tp, pline[LINEMAX2], ErrorLine[LINEMAX2], * bp;
extern char mline[LINEMAX2], sline[LINEMAX2], sline2[LINEMAX2];

extern char SourceFNames[128][MAX_PATH];
extern int CurrentSourceFName;

extern bool displayinprocces, displayerror; /* added */
extern int ConvertEncoding; /* added */
extern int pass, IsLabelNotFound, ErrorCount, WarningCount, IncludeLevel, IsRunning, IsListingFileOpened, donotlist, listdata, listmacro;
extern int adrdisp, PseudoORG; /* added for spectrum mode */
extern char* MemoryRAM, * MemoryPointer; /* added for spectrum ram */
extern int MemoryCPage, MemoryPagesCount, StartAddress;
extern aint MemorySize;
extern int macronummer, lijst, reglenwidth, synerr;
extern aint CurAddress, AddressOfMAP, CurrentGlobalLine, CurrentLocalLine, CompiledCurrentLine, destlen, size, PreviousErrorLine, maxlin, comlin;

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
extern CAddressList* AddressList; /*from SjASM 0.39g*/
extern CStringsList* ModuleList;

extern lua_State *LUA;
extern int LuaLine;

#ifdef UNDER_CE
int main(int argc, _TCHAR* argv[]);
#endif

#endif
//eof sjasm.h
