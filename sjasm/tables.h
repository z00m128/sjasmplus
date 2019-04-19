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

// bit flags for ValidateLabel
constexpr int VALIDATE_LABEL_SET_NAMESPACE = 0x01;
constexpr int VALIDATE_LABEL_AS_GLOBAL = 0x02;
char* ValidateLabel(char* naam, int flags);
extern char* PreviousIsLabel;
int GetLabelValue(char*& p, aint& val);
int GetLocalLabelValue(char*& op, aint& val);

class CLabelTableEntry {
public:
	char* name;
	char page;
	bool IsDEFL;
	unsigned char forwardref;
	aint value;
	char used;
	int updatePass;	// last updated in pass
	CLabelTableEntry();
};

class CLabelTable {
public:
	CLabelTable();
	int Insert(const char* nname, aint nvalue, bool undefined = false, bool IsDEFL = false);
	int Update(char*, aint);
	int GetValue(char* nname, aint& nvalue);
	int Find(char*);
	int Remove(char*);
	int IsUsed(char*);
	void RemoveAll();
	void Dump();
	void DumpForUnreal();
	void DumpSymbols();
private:
	int HashTable[LABTABSIZE], NextLocation;
	CLabelTableEntry LabelTable[LABTABSIZE];
	int Hash(const char*);
};

class CFunctionTableEntry {
public:
	char* name;
	void (*funp)(void);
};

class CFunctionTable {
public:
	CFunctionTable();
	int Insert(const char*, void(*) (void));
	int insertd(const char*, void(*) (void));
	/*int zoek(char*);*/
	int zoek(const char*);
	int Find(char*);
private:
	int HashTable[LABTABSIZE], NextLocation;
	CFunctionTableEntry funtab[LABTABSIZE];
	int Hash(const char*);
};

class CLocalLabelTableEntry {
public:
	aint nummer, value;
	CLocalLabelTableEntry* next, * prev;
	CLocalLabelTableEntry(long int number, long int address, CLocalLabelTableEntry* previous);
};

class CLocalLabelTable {
public:
	CLocalLabelTable();
	~CLocalLabelTable();
	void InitPass();
	aint seekForward(const aint labelNumber) const;
	aint seekBack(const aint labelNumber) const;
	bool InsertRefresh(const aint labelNumber);
private:
	bool insertImpl(const aint labelNumber);
	bool refreshImpl(const aint labelNumber);
	CLocalLabelTableEntry* first, * last, * refresh;
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
	int sourceLine;
	CStringsList() {
		string = NULL;
		next = NULL;
		sourceLine = 0;
	}
	~CStringsList() {
		if (string) free(string);
		if (next) delete next;
	}
	CStringsList(const char* stringSource, CStringsList* next = NULL);
};

class CDefineTableEntry {
public:
	char* name, * value;
	CStringsList* nss;
	CDefineTableEntry* next;
	CDefineTableEntry(const char*, const char*, CStringsList*, CDefineTableEntry*);
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
	CStringsList* DefArrayList;
	void Init();
	void Add(const char*, const char*, CStringsList*);
	char* Get(const char*);
	int FindDuplicate(const char*);
	int Replace(const char*, const char*);
	int Replace(const char*, const int);
	int Remove(const char*);
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
	~CMacroTableEntry(){if (next)delete next;};
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
	~CMacroTable(){if(macs) delete macs;};
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
	CStructureEntry2(aint noffset, aint nlen, aint ndef, EStructureMembers ntype);
	aint ParseValue(char* & p);
};

class CStructure {
public:
	char* naam, * id;
	int binding;
	int global;
	int maxAlignment;
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
	CStructure* zoek(const char*, int);
	int FindDuplicate(char*);
	int Emit(char*, char*, char*&, int);
private:
	CStructure* strs[128];
};

struct SRepeatStack {
	int RepeatCount;
	long CurrentSourceLine;
	CStringsList* Lines;
	CStringsList* Pointer;
	bool IsInWork;
	int Level;
};

struct SConditionalStack {
	long CurrentSourceLine;
	CStringsList* Lines;
	CStringsList* Pointer;
	bool IsInWork;
	int Level;
};

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
	CDevice(const char* name, CDevice* parent);
	~CDevice();
	void AddSlot(aint adr, aint size);
	void AddPage(aint size);
	CDevicePage* GetPage(aint);
	CDeviceSlot* GetSlot(aint);
	char* ID;
	CDevice* Next;
	int CurrentSlot;
	int CurrentPage;
	int SlotsCount;
	int PagesCount;
private:
	CDeviceSlot* Slots[256];
	CDevicePage* Pages[256];
};


int LuaGetLabel(char *name);

//eof tables.h

