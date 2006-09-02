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

char* AddNewLabel(char*);
extern char* PreviousIsLabel;
int GetLabelValue(char*& p, aint& val);
int GetLocalLabelValue(char*& op, aint& val);

class CLabelTableEntry {
public:
	char* name;
	char page; /* added */
	bool IsDEFL; /* added */
	unsigned char forwardref; /* added */
	aint value, used;
	CLabelTableEntry();
};

class CLabelTable {
public:
	CLabelTable();
	int Insert(char*, aint, bool, bool);
	int Update(char*, aint);
	int zoek(char*, aint&);
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
	CAddressList(aint nval, CAddressList* nnext) {
		val = nval; next = nnext;
	}
};

class CStringList {
public:
	char* string;
	CStringList* next;
	CStringList() {
		next = 0;
	}
	CStringList(char*, CStringList*);
};

class CDefineTableEntry {
public:
	char* naam, * vervanger;
	CStringList* nss; /* added */
	CDefineTableEntry* next;
	CDefineTableEntry(char*, char*, CStringList* /*added*/, CDefineTableEntry*);
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
	CStringList* defarraylstp; /* added */
	void Init();
	void Add(char*, char*, CStringList* /*added*/);
	char* getverv(char*);
	int FindDuplicate(char*);
	CDefineTable() {
		Init();
	}
private:
	CDefineTableEntry* defs[128];
};

class CMacroTableEntry {
public:
	char* naam;
	CStringList* args, * body;
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
	EStructureMembers soort;
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
	int dupcount;
	long CurrentGlobalLine;
	long CurrentLocalLine;
	long CurrentLine;
	CStringList* lines;
	CStringList* pointer;
	char* lp;
	bool work;
	int level;
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
//eof tables.h

