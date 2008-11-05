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

// tables.h
using std::cout;
using std::cerr;
using std::endl;

enum EStructureMembers { SMEMBUNKNOWN, SMEMBALIGN, SMEMBBYTE, SMEMBWORD, SMEMBBLOCK, SMEMBDWORD, SMEMBD24, SMEMBPARENOPEN, SMEMBPARENCLOSE };

char* ValidateLabel(char*);
extern char* PreviousIsLabel;
int GetLabelValue(char*& p, aint& val);
int GetLocalLabelValue(char*& op, aint& val);

class CLabelTableEntry {
public:
	char* name;
	char page; /* added */
	bool IsDEFL; /* added */
	unsigned char forwardref; /* added */
	aint value;
	char used;
	CLabelTableEntry();
};

class CLabelTable {
public:
	CLabelTable();
	int Insert(char*, aint, bool, bool);
	int Update(char*, aint);
	int GetValue(char*, aint&);
	int Find(char*);
	int Remove(char*);
	int IsUsed(char*);
	void RemoveAll();
	void Dump();
	void DumpForUnreal(); /* added */
	void DumpSymbols(); /* added from SjASM 0.39g */
private:
	int HashTable[LABTABSIZE], NextLocation;
	CLabelTableEntry LabelTable[LABTABSIZE];
	int Hash(char*);
};

class CFunctionTableEntry {
public:
	char* name;
	void (*funp)(void);
};

class CFunctionTable {
public:
	CFunctionTable();
	int Insert(char*, void(*) (void));
	int insertd(char*, void(*) (void));
	/*int zoek(char*);*/
	int zoek(char*, bool =0);
	int Find(char*);
private:
	int HashTable[LABTABSIZE], NextLocation;
	CFunctionTableEntry funtab[LABTABSIZE];
	int Hash(char*);
};

class CLocalLabelTableEntry {
public:
	aint regel, nummer, value;
	CLocalLabelTableEntry* next, * prev;
	CLocalLabelTableEntry(aint, aint, CLocalLabelTableEntry*);
};

class CLocalLabelTable {
public:
	CLocalLabelTable();
	aint zoekf(aint);
	aint zoekb(aint);
	void Insert(aint, aint);
private:
	CLocalLabelTableEntry* first, * last;
};

class CAddressList {
public:
	aint val;
	CAddressList* next;
	CAddressList() {
		next = 0;
	}
	~CAddressList() {
		if (next) delete next;
	}
	CAddressList(aint nval, CAddressList* nnext) {
		val = nval; next = nnext;
	}
};

class CStringsList {
public:
	char* string;
	CStringsList* next;
	CStringsList() {
		next = 0;
	}
	~CStringsList() {
		if (next) delete next;
	}
	CStringsList(char*, CStringsList*);
};

class CDefineTableEntry {
public:
	char* name, * value;
	CStringsList* nss; /* added */
	CDefineTableEntry* next;
	CDefineTableEntry(char*, char*, CStringsList* /*added*/, CDefineTableEntry*);
};

class CMacroDefineTable {
public:
	void Init();
	void AddMacro(char*, char*);
	CDefineTableEntry* getdefs();
	void setdefs(CDefineTableEntry*);
	char* getverv(char*);
	int FindDuplicate(char*);
	CMacroDefineTable() {
		Init();
	}
private:
	int used[128];
	CDefineTableEntry* defs;
};

class CDefineTable {
public:
	CStringsList* DefArrayList; /* added */
	void Init();
	void Add(char*, char*, CStringsList* /*added*/);
	char* Get(char*);
	int FindDuplicate(char*);
	int Replace(char*, char*);
	int Remove(char*);
	void RemoveAll();
	CDefineTable() {
		Init();
	}
private:
	CDefineTableEntry* defs[128];
};

class CMacroTableEntry {
public:
	char* naam;
	CStringsList* args, * body;
	CMacroTableEntry* next;
	CMacroTableEntry(char*, CMacroTableEntry*);
};

class CMacroTable {
public:
	void Add(char*, char*&);
	int Emit(char*, char*&);
	int FindDuplicate(char*);
	void Init();
	CMacroTable() {
		Init();
	}
private:
	int used[128];
	CMacroTableEntry* macs;
};

class CStructureEntry1 {
public:
	char* naam;
	aint offset;
	CStructureEntry1* next;
	CStructureEntry1(char*, aint);
};

class CStructureEntry2 {
public:
	aint offset, len, def;
	EStructureMembers type;
	CStructureEntry2* next;
	CStructureEntry2(aint, aint, aint, EStructureMembers);
};

class CStructure {
public:
	char* naam, * id;
	int binding;
	int global;
	aint noffset;
	void AddLabel(char*);
	void AddMember(CStructureEntry2*);
	void CopyLabel(char*, aint);
	void CopyLabels(CStructure*);
	void CopyMember(CStructureEntry2*, aint);
	void CopyMembers(CStructure*, char*&);
	void deflab();
	void emitlab(char*);
	void emitmembs(char*&);
	CStructure* next;
	CStructure(char*, char*, int, int, int, CStructure*);
private:
	CStructureEntry1* mnf, * mnl;
	CStructureEntry2* mbf, * mbl;
};

class CStructureTable {
public:
	CStructure* Add(char*, int, int, int);
	void Init();
	CStructureTable() {
		Init();
	}
	CStructure* zoek(char*, int);
	int FindDuplicate(char*);
	int Emit(char*, char*, char*&, int);
private:
	CStructure* strs[128];
};

struct SRepeatStack {
	int RepeatCount;
	long CurrentGlobalLine;
	long CurrentLocalLine;
	long CurrentLine;
	CStringsList* Lines;
	CStringsList* Pointer;
	bool IsInWork;
	int Level;
	char* lp;
};

struct SConditionalStack {
	long CurrentGlobalLine;
	long CurrentLocalLine;
	long CurrentLine;
	CStringsList* Lines;
	CStringsList* Pointer;
	bool IsInWork;
	int Level;
	char* lp;
};

/*
class LabelTable2entrycls {
public:
  char *name;
  aint value;
  CLabelTableEntry();
};


class LabelTable2cls {
public:
  LabelTable2cls();
  int replace(char*,aint);
  int count=0;
private:
  int HashTable[LABTABSIZE],NextLocation;
  LabelTable2entrycls LabelTable[LABTABSIZE];
  int Hash(char*);
};
*/

class CDevicePage {
public:
	CDevicePage(aint, aint /*, CDevicePage **/);
	~CDevicePage();
	aint Size;
	aint Number;
	char *RAM;
	//CDevicePage* Next;
private:
};

class CDeviceSlot {
public:
	CDeviceSlot(aint, aint, aint /*, CDeviceSlot **/);
	~CDeviceSlot();
	aint Address;
	aint Size;
	CDevicePage* Page;
	aint Number;
	//CDeviceSlot* Next;
private:
};

class CDevice {
public:
	CDevice(char *, CDevice *);
	~CDevice();
	void AddSlot(aint adr, aint size);
	void AddPage(aint size);
	CDevicePage* GetPage(aint);
	CDeviceSlot* GetSlot(aint);
	char* ID;
	CDevice* Next;
	aint CurrentSlot;
	aint CurrentPage;
	aint SlotsCount;
	aint PagesCount;
private:
	CDeviceSlot* Slots[256];
	CDevicePage* Pages[256];
};


int LuaGetLabel(char *name);

//eof tables.h

