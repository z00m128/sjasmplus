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

#include <unordered_map>

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

enum EStructureMembers {
	SMEMBUNKNOWN, SMEMBALIGN,
	SMEMBBYTE, SMEMBWORD, SMEMBBLOCK, SMEMBDWORD, SMEMBD24, SMEMBTEXT,
	SMEMBPARENOPEN, SMEMBPARENCLOSE
};

struct SLabelTableEntry;

char* ValidateLabel(const char* naam, bool setNameSpace);
char* ExportLabelToSld(const char* naam, const SLabelTableEntry* label);
char* ExportModuleToSld(bool endModule = false);
extern char* PreviousIsLabel;
bool GetLabelPage(char*& p, aint& val);
bool GetLabelValue(char*& p, aint& val);
int GetLocalLabelValue(char*& op, aint& val);

constexpr int LABEL_PAGE_UNDEFINED = -1;
constexpr int LABEL_PAGE_ROM = 0x7F00;			// must be minimum of special values (but positive)
constexpr int LABEL_PAGE_OUT_OF_BOUNDS = 0x7F80;	// label is defined, but not within Z80 address space

constexpr unsigned LABEL_IS_UNDEFINED = (1<<0);
constexpr unsigned LABEL_IS_DEFL = (1<<1);
constexpr unsigned LABEL_IS_EQU = (1<<2);
constexpr unsigned LABEL_IS_STRUCT_D = (1<<3);
constexpr unsigned LABEL_IS_STRUCT_E = (1<<4);
constexpr unsigned LABEL_HAS_RELOC_TRAIT = (1<<5);
constexpr unsigned LABEL_IS_RELOC = (1<<6);
// constexpr unsigned LABEL_IS_USED = (1<<7);	// currently not explicitly used in Insert(..) (calculated implicitly)

struct SLabelTableEntry {
	aint	value = 0;
	int		updatePass = 0;	// last update was in pass
	short	page = LABEL_PAGE_UNDEFINED;
	bool	IsDEFL = false;
	bool	IsEQU = false;
	bool	used = false;
	bool	isRelocatable = false;
	bool	isStructDefinition = false;
	bool	isStructEmit = false;
};

typedef std::unordered_map<std::string, SLabelTableEntry> symbol_map_t;

class CLabelTable {
private:
	symbol_map_t symbols;
public:
	CLabelTable() { symbols.reserve(LABTABSIZE); }
	int Insert(const char* nname, aint nvalue, unsigned traits = 0, short equPageNum = LABEL_PAGE_UNDEFINED);
	int Update(char* name, aint value);
	SLabelTableEntry* Find(const char* name, bool onlyDefined = false);
	bool Remove(const char* name);
	bool IsUsed(const char* name);
	void RemoveAll();
	void Dump();
	void DumpForUnreal();
	void DumpForCSpect();
	void DumpSymbols();
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
	bool isRelocatable;
	CLocalLabelTableEntry(aint number, aint address, CLocalLabelTableEntry* previous);
};

class CLocalLabelTable {
public:
	CLocalLabelTable();
	~CLocalLabelTable();
	void InitPass();
	CLocalLabelTableEntry* seekForward(const aint labelNumber) const;
	CLocalLabelTableEntry* seekBack(const aint labelNumber) const;
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
	static constexpr aint TEXT_MAX_SIZE = 8192;
	CStructureEntry2* next;
	byte* text;
	aint offset, len, def;
	bool defRelocatable;
	EStructureMembers type;

	CStructureEntry2(aint noffset, aint nlen, aint ndef, bool ndefrel, EStructureMembers ntype);
	CStructureEntry2(aint noffset, aint nlen, byte* textData);
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
	void CopyLabels(CStructure*);
	void CopyMembers(CStructure*, char*&);
	void deflab();
	void emitlab(char* iid, aint address, bool isRelocatable);
	void emitmembs(char*&);
	CStructure* next;
	CStructure(const char* nnaam, char* nid, int no, int ngl, CStructure* p);
	~CStructure();
private:
	CStructureEntry1* mnf, * mnl;
	CStructureEntry2* mbf, * mbl;
	void CopyLabel(char*, aint);
	void CopyMember(CStructureEntry2* item, aint newDefault, bool newDefIsRelative);
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

