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

struct TextFilePos {
	const char*		filename;
	uint32_t		line;				// line numbering start at 1 (human way) 0 = invalid/init value
	uint32_t 		colBegin, colEnd;	// columns coordinates are unused at this moment

	TextFilePos();
	void newFile(const char* fileNamePtr);	// requires stable immutable pointer (until sjasmplus exits)

	// advanceColumns are valid only when true == endsWithColon (else advanceColumns == 0)
	// default arguments are basically "next line"
	void nextSegment(bool endsWithColon = false, size_t advanceColumns = 0);
};

enum EStructureMembers { SMEMBUNKNOWN, SMEMBALIGN, SMEMBBYTE, SMEMBWORD, SMEMBBLOCK, SMEMBDWORD, SMEMBD24, SMEMBPARENOPEN, SMEMBPARENCLOSE };

char* ValidateLabel(const char* naam, bool setNameSpace);
extern char* PreviousIsLabel;
bool GetLabelPage(char*& p, aint& val);
bool GetLabelValue(char*& p, aint& val);
int GetLocalLabelValue(char*& op, aint& val);

constexpr int LABEL_PAGE_UNDEFINED = -1;
constexpr int LABEL_PAGE_ROM = 0x7F00;			// must be minimum of special values (but positive)

class CLabelTableEntry {
public:
	char*	name;
	aint	value;
	int		updatePass;	// last update was in pass
	short	page;
	bool	IsDEFL;
	bool	IsEQU;
	bool	used;
	CLabelTableEntry();
	void ClearData();
};

class CLabelTable {
public:
	CLabelTable();
	int Insert(const char* nname, aint nvalue, bool undefined = false, bool IsDEFL = false, bool IsEQU = false);
	int Update(char*, aint);
	CLabelTableEntry* Find(const char* name, bool onlyDefined = false);
	bool Remove(const char* name);
	bool IsUsed(const char* name);
	void RemoveAll();
	void Dump();
	void DumpForUnreal();
	void DumpForCSpect();
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
	int zoek(const char*);
	int Find(char*);
private:
	int HashTable[FUNTABSIZE], NextLocation;
	CFunctionTableEntry funtab[FUNTABSIZE];
	int Hash(const char*);
};

class CLocalLabelTableEntry {
public:
	aint nummer, value;
	CLocalLabelTableEntry* next, * prev;
	CLocalLabelTableEntry(aint number, aint address, CLocalLabelTableEntry* previous);
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

class CStringsList {
public:
	char* string;
	CStringsList* next;
	TextFilePos source;
	TextFilePos definition;
	CStringsList();
	~CStringsList();
	CStringsList(const char* stringSource, CStringsList* next = NULL);
};

class CDefineTableEntry {
public:
	char* name, * value;
	CStringsList* nss;
	CDefineTableEntry* next;
	CDefineTableEntry(const char*, const char*, CStringsList*, CDefineTableEntry*);
	~CDefineTableEntry();
};

class CMacroDefineTable {
public:
	void ReInit();
	void AddMacro(char*, char*);
	CDefineTableEntry* getdefs();
	void setdefs(CDefineTableEntry*);
	char* getverv(char*);
	int FindDuplicate(char*);
	CMacroDefineTable();
	CMacroDefineTable(const CMacroDefineTable&) = delete;
	CMacroDefineTable& operator=(CMacroDefineTable const&) = delete;
	~CMacroDefineTable();
private:
	bool used[128];
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
	~CDefineTable();
	CDefineTable(const CDefineTable&) = delete;
	CDefineTable& operator=(CDefineTable const & defTable);
private:
	CDefineTableEntry* defs[128];
};

class CMacroTableEntry {
public:
	char* naam;
	CStringsList* args, * body;
	CMacroTableEntry* next;
	CMacroTableEntry(char*, CMacroTableEntry*);
	~CMacroTableEntry();
};

class CMacroTable {
public:
	void Add(char*, char*&);
	int Emit(char*, char*&);
	int FindDuplicate(char*);
	void ReInit();
	CMacroTable();
	~CMacroTable();
private:
	bool used[128];
	CMacroTableEntry* macs;
};

class CStructureEntry1 {
public:
	char* naam;
	aint offset;
	CStructureEntry1* next;
	CStructureEntry1(char*, aint);
	~CStructureEntry1();
};

class CStructureEntry2 {
public:
	aint offset, len, def;
	EStructureMembers type;
	CStructureEntry2* next;
	CStructureEntry2(aint noffset, aint nlen, aint ndef, EStructureMembers ntype);
	~CStructureEntry2();
	aint ParseValue(char* & p);
};

class CStructure {
public:
	char* naam, * id;
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
	void emitlab(char* iid, aint address);
	void emitmembs(char*&);
	CStructure* next;
	CStructure(const char* nnaam, char* nid, int no, int ngl, CStructure* p);
	~CStructure();
private:
	CStructureEntry1* mnf, * mnl;
	CStructureEntry2* mbf, * mbl;
};

class CStructureTable {
public:
	CStructure* Add(char* naam, int no, int gl);
	void ReInit();
	CStructureTable();
	~CStructureTable();
	CStructure* zoek(const char*, int);
	int FindDuplicate(char*);
	int Emit(char*, char*, char*&, int);
private:
	static aint ParseDesignedAddress(char* &p);
	CStructure* strs[128];
};

struct SRepeatStack {
	int RepeatCount;
	TextFilePos sourcePos;
	aint CurrentSourceLine;
	CStringsList* Lines;
	CStringsList* Pointer;
	bool IsInWork;
	int Level;
};

struct SConditionalStack {
	aint CurrentSourceLine;
	CStringsList* Lines;
	CStringsList* Pointer;
	bool IsInWork;
	int Level;
};

int LuaGetLabel(char *name);

//eof tables.h

