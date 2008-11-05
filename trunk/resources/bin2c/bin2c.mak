# Microsoft Developer Studio Generated NMAKE File, Based on bin2c.dsp
!IF "$(CFG)" == ""
CFG=bin2c - Win32 Debug
!MESSAGE No configuration specified. Defaulting to bin2c - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "bin2c - Win32 Release" && "$(CFG)" != "bin2c - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "bin2c.mak" CFG="bin2c - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "bin2c - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "bin2c - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 

CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "bin2c - Win32 Release"

OUTDIR=.\Release
INTDIR=.\Release
# Begin Custom Macros
OutDir=.\Release
# End Custom Macros

ALL : "$(OUTDIR)\bin2c.exe"


CLEAN :
	-@erase "$(INTDIR)\bin2c.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(OUTDIR)\bin2c.exe"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /MD /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /D "_AFXDLL" /Fp"$(INTDIR)\bin2c.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c 
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\bin2c.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=LIBCTINY.LIB MSVCRT.LIB KERNEL32.LIB /nologo /subsystem:console /incremental:no /pdb:"$(OUTDIR)\bin2c.pdb" /machine:I386 /out:"$(OUTDIR)\bin2c.exe" /MERGE:.rdata=.data /MERGE:.text=.data /MERGE:.reloc=.data /FILEALIGN:0x200 /IGNORE:4078 /IGNORE:4089 
LINK32_OBJS= \
	"$(INTDIR)\bin2c.obj"

"$(OUTDIR)\bin2c.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "bin2c - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug
# Begin Custom Macros
OutDir=.\Debug
# End Custom Macros

ALL : "$(OUTDIR)\bin2c.exe"


CLEAN :
	-@erase "$(INTDIR)\bin2c.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\vc60.pdb"
	-@erase "$(OUTDIR)\bin2c.exe"
	-@erase "$(OUTDIR)\bin2c.ilk"
	-@erase "$(OUTDIR)\bin2c.pdb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP_PROJ=/nologo /MLd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /Fp"$(INTDIR)\bin2c.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c 
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\bin2c.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /incremental:yes /pdb:"$(OUTDIR)\bin2c.pdb" /debug /machine:I386 /out:"$(OUTDIR)\bin2c.exe" /pdbtype:sept 
LINK32_OBJS= \
	"$(INTDIR)\bin2c.obj"

"$(OUTDIR)\bin2c.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ENDIF 

.c{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<


!IF "$(NO_EXTERNAL_DEPS)" != "1"
!IF EXISTS("bin2c.dep")
!INCLUDE "bin2c.dep"
!ELSE 
!MESSAGE Warning: cannot find "bin2c.dep"
!ENDIF 
!ENDIF 


!IF "$(CFG)" == "bin2c - Win32 Release" || "$(CFG)" == "bin2c - Win32 Debug"
SOURCE=.\bin2c.cpp

"$(INTDIR)\bin2c.obj" : $(SOURCE) "$(INTDIR)"



!ENDIF 

