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

#include <map>

struct TextFilePos {
	const char*		filename;
	uint32_t		line;				// line numbering start at 1 (human way) 0 = invalid/init value
	uint32_t 		colBegin, colEnd;	// columns coordinates for lines with multiple segments using ':'
					// colBegin is also reused for smartSmc offsets

	TextFilePos(const char* fileNamePtr = nullptr, uint32_t line = 0);
	void newFile(const char* fileNamePtr);	// requires stable immutable pointer (until sjasmplus exits)

	// advanceColumns are valid only when true == endsWithColon (else advanceColumns == 0)
	// default arguments are basically "next line"
	void nextSegment(bool endsWithColon = false, size_t advanceColumns = 0);

	inline bool operator == (const TextFilePos & b) const {
		// compares pointers to filenames (!), as pointers should be stable (archived by GetInputFile)
		return filename == b.filename && line == b.line;
	}
	inline bool operator != (const TextFilePos & b) const {
		return !(*this == b);
	}
};

typedef std::vector<TextFilePos> source_positions_t;

enum EStructureMembers {
	SMEMBUNKNOWN, SMEMBALIGN,
	SMEMBBYTE, SMEMBWORD, SMEMBBLOCK, SMEMBDWORD, SMEMBD24, SMEMBTEXT,
	SMEMBPARENOPEN, SMEMBPARENCLOSE
};

struct SLabelTableEntry;

extern std::string vorlab;
void InitVorlab();
char* ValidateLabel(const char* naam, bool setNameSpace, bool ignoreCharAfter = false);
char* ExportLabelToSld(const char* naam, const SLabelTableEntry* label);
char* ExportModuleToSld(bool endModule = false);
extern char* PreviousIsLabel;
bool LabelExist(char*& p, aint& val);
bool GetLabelPage(char*& p, aint& val);
bool GetLabelValue(char*& p, aint& val);
int GetTemporaryLabelValue(char*& op, aint& val, bool requireUnderscore = false);

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
constexpr unsigned LABEL_IS_SMC = (1<<7);
constexpr unsigned LABEL_IS_KEYWORD = (1<<8);
// constexpr unsigned LABEL_IS_USED = (1<<?);	// currently not explicitly used in Insert(..) (calculated implicitly)

struct SLabelTableEntry {
	aint				value = 0;
	int					updatePass = 0;	// last update was in pass
	short				page = LABEL_PAGE_UNDEFINED;
	unsigned			traits = 0;
	bool				used = false;
	Relocation::EType	isRelocatable = Relocation::OFF;
};

typedef std::map<std::string, SLabelTableEntry> symbol_map_t;

class CLabelTable {
private:
	symbol_map_t symbols;
public:
	CLabelTable(const CLabelTable&) = delete;
	CLabelTable& operator=(CLabelTable const &) = delete;
	CLabelTable() = default;
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

typedef void (*function_fn_t)(void);
typedef std::map<std::string, function_fn_t> function_map_t;

class CFunctionTable {
private:
	function_map_t functions;
public:
	CFunctionTable(const CFunctionTable&) = delete;
	CFunctionTable& operator=(CFunctionTable const &) = delete;
	CFunctionTable() = default;
	int Insert(const char*, function_fn_t);
	int insertd(const char*, function_fn_t);
	int zoek(const char*);
};

struct TemporaryLabel {
	aint nummer, value;
	bool isRelocatable;
	TemporaryLabel(aint number, aint address);
};

class CTemporaryLabelTable {
public:
	CTemporaryLabelTable(const CTemporaryLabelTable&) = delete;
	CTemporaryLabelTable& operator=(CTemporaryLabelTable const &) = delete;
	CTemporaryLabelTable();
	void InitPass();
	const TemporaryLabel* seekForward(const aint labelNumber) const;
	const TemporaryLabel* seekBack(const aint labelNumber) const;
	bool InsertRefresh(const aint labelNumber);
private:
	typedef std::vector<TemporaryLabel> temporary_labels_t;
	temporary_labels_t labels;
	temporary_labels_t::size_type refresh;
	bool insertImpl(const aint labelNumber);
	bool refreshImpl(const aint labelNumber);
};

class CStringsList {
public:
	char* string;
	CStringsList* next;
	TextFilePos source;
	~CStringsList();
	CStringsList(const char* stringSource, CStringsList* next = NULL);
	CStringsList(const CStringsList&) = delete;
	CStringsList& operator=(CStringsList const &) = delete;

	static bool contains(const CStringsList* strlist, const char* searchString);
};

class CDefineTableEntry {
public:
	char* name, * value;
	CStringsList* nss;
	CDefineTableEntry* next;
	CDefineTableEntry(const CDefineTableEntry&) = delete;
	CDefineTableEntry& operator=(CDefineTableEntry const &) = delete;
	CDefineTableEntry(const char*, const char*, CStringsList*, CDefineTableEntry*);
	~CDefineTableEntry();
	void Replace(const char* nvalue);
};

class CMacroDefineTable {
public:
	void ReInit();
	void AddMacro(char*, char*);
	CDefineTableEntry* getdefs();
	void setdefs(CDefineTableEntry*);
	const char* getverv(const char*) const;
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
	const char* Get(const char*);
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
	CStringsList* args = nullptr;
	CStringsList* body = nullptr;
	CMacroTableEntry() = default;
	CMacroTableEntry(const CMacroTableEntry&) = delete;
	CMacroTableEntry(CMacroTableEntry&& other) noexcept : args(other.args), body(other.body) {
		other.args = nullptr;
		other.body = nullptr;
	}
	CMacroTableEntry& operator=(CMacroTableEntry const &) = delete;
	~CMacroTableEntry() {
		delete args;
		delete body;
	}
};

class CMacroTable {
public:
	CMacroTable() : used(128, false) {}
	~CMacroTable() = default;
	void Add(const char*, char*&);
	int Emit(char*, char*&);
	void ReInit();
	CMacroTable(const CMacroTable&) = delete;
	CMacroTable& operator=(CMacroTable const &) = delete;
private:
	typedef std::map<std::string, CMacroTableEntry> macro_map_t;

	std::vector<bool> used;
	macro_map_t macs;
};

class CStructureEntry1 {
public:
	char* naam;
	aint offset;
	CStructureEntry1* next;
	CStructureEntry1(const CStructureEntry1&) = delete;
	CStructureEntry1& operator=(CStructureEntry1 const &) = delete;
	CStructureEntry1(char*, aint);
	~CStructureEntry1();
};

class CStructureEntry2 {
public:
	static constexpr aint TEXT_MAX_SIZE = 8192;
	CStructureEntry2* next;
	byte* text;
	aint offset, len, def;
	Relocation::EType defDeltaType;
	EStructureMembers type;

	CStructureEntry2(const CStructureEntry2&) = delete;
	CStructureEntry2& operator=(CStructureEntry2 const &) = delete;
	CStructureEntry2(aint noffset, aint nlen, aint ndef, Relocation::EType ndeltatype, EStructureMembers ntype);
	CStructureEntry2(aint noffset, aint nlen, byte* textData);
	~CStructureEntry2();
	aint ParseValue(char* & p);
};

class CStructure {
public:
	char* naam;
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
	CStructure(const CStructure&) = delete;
	CStructure& operator=(CStructure const &) = delete;
	CStructure(const char* nnaam, int no, CStructure* p);
	~CStructure();
private:
	CStructureEntry1* mnf, * mnl;
	CStructureEntry2* mbf, * mbl;
	void CopyLabel(char*, aint);
	void CopyMember(CStructureEntry2* item, aint newDefault, Relocation::EType newDeltaType);
};

class CStructureTable {
public:
	CStructure* Add(const char* naam, int no);
	void ReInit();
	CStructureTable(const CStructureTable&) = delete;
	CStructureTable& operator=(CStructureTable const &) = delete;
	CStructureTable();
	~CStructureTable();
	CStructure* zoek(const char*, int);
	int FindDuplicate(const char*);
	int Emit(char*, char*, char*&, int);
private:
	static aint ParseDesignedAddress(char* &p);
	CStructure* strs[128];
};

struct SRepeatStack {
	SRepeatStack(const SRepeatStack&) = delete;
	SRepeatStack& operator=(SRepeatStack const &) = delete;
	SRepeatStack(aint count, CStringsList* condition, CStringsList* firstLine);
	~SRepeatStack();

	int RepeatCount;
	CStringsList* RepeatCondition;
	TextFilePos sourcePos;
	CStringsList* Lines;
	CStringsList* Pointer;
	bool IsInWork;
	int Level;
};

//eof tables.h

