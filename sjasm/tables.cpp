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

// tables.cpp

#include "sjdefs.h"

TextFilePos::TextFilePos() : filename(nullptr), line(0), colBegin(0), colEnd(0) {
}

void TextFilePos::newFile(const char* fileNamePtr) {
	filename = fileNamePtr;
	line = colBegin = colEnd = 0;
}

// advanceColumns are valid only when true == endsWithColon (else advanceColumns == 0)
// default arguments are basically "next line"
void TextFilePos::nextSegment(bool endsWithColon, size_t advanceColumns) {
	if (endsWithColon && 0 == colEnd) colEnd = 1;	// first segment of "colonized" line (do +1,+1)
	colBegin = colEnd;
	if (colBegin <= 1) ++line;		// first segment of any line, increment also line number
	if (endsWithColon)	colEnd += advanceColumns;
	else				colEnd = 0;
}

char* PreviousIsLabel = nullptr;

// since v1.14.2:
// When "setNameSpace == true" the naam is parsed as whole, reporting invalid labelname error
// When "setNameSpace == false" the naam is parsed only through valid label chars (early exit)
// => the labels can be evaluated straight from the expression string without copying them out!
char* ValidateLabel(const char* naam, bool setNameSpace) {
	const bool global = '@' == *naam;
	const bool local = '.' == *naam;
	if (!isLabelStart(naam)) {		// isLabelStart assures that only single modifier exist
		if (global || local) ++naam;// single modifier is parsed (even when invalid name)
		Error("Invalid labelname", naam);
		return nullptr;
	}
	if (global || local) ++naam;	// single modifier is parsed
	const bool inMacro = local && macrolabp;
	const bool inModule = !inMacro && !global && ModuleName[0];
	// check all chars of label
	const char* np = naam;
	while (islabchar(*np)) ++np;
	if ('[' == *np) return nullptr;	// this is DEFARRAY name, do not process it as label (silent exit)
	if (setNameSpace && *np) {
		// if this is supposed to be new label, there shoulnd't be anything else after it
		Error("Invalid labelname", naam);
		return nullptr;
	}
	// calculate expected length of fully qualified label name
	int labelLen = (np - naam), truncateAt = LABMAX;
	if (LABMAX < labelLen) Error("Label too long", naam, IF_FIRST);	// non-fatal error, will truncate it
	if (inMacro) labelLen += 1 + strlen(macrolabp);
	else if (local) labelLen += 1 + strlen(vorlabp);
	if (inModule) labelLen += 1 + strlen(ModuleName);
	// build fully qualified label name (in newly allocated memory buffer, with precise length)
	char* label = new char[1+labelLen];
	if (nullptr == label) ErrorOOM();
	label[0] = 0;
	if (inModule) {
		STRCAT(label, labelLen, ModuleName);	STRCAT(label, 2, ".");
	}
	if (inMacro) {
		STRCAT(label, labelLen, macrolabp);		STRCAT(label, 2, ">");
	} else if (local) {
		STRCAT(label, labelLen, vorlabp);		STRCAT(label, 2, ".");
	}
	char* lp = label + strlen(label), * newVorlabP = nullptr;
	if (setNameSpace && !local) newVorlabP = lp;	// here will start new non-local label prefix
	while (truncateAt-- && islabchar(*naam)) *lp++ = *naam++;	// add the new label (truncated if needed)
	*lp = 0;
	if (labelLen < lp - label) Error("internal error", nullptr, FATAL);		// should never happen :)
	if (newVorlabP) {
		free(vorlabp);
		vorlabp = STRDUP(newVorlabP);
		if (vorlabp == NULL) ErrorOOM();
	}
	return label;
}

static bool getLabel_invalidName = false;

static CLabelTableEntry* GetLabel(char*& p) {
	getLabel_invalidName = true;
	char* fullName = ValidateLabel(p, false);
	if (nullptr == fullName) return nullptr;
	getLabel_invalidName = false;
	const bool global = '@' == *p;
	const bool local = '.' == *p;
	bool inMacro = local && macrolabp;		// not just inside macro, but should be prefixed
	while (islabchar(*p)) ++p;		// advance pointer beyond the parsed label
	const int modNameLen = strlen(ModuleName);
	// find the label entry in the label table (for local macro labels it has to try all sub-parts!)
	// then regular full label has to be tried
	// and if it's regular non-local in module, then variant w/o current module has to be tried
	char *findName = fullName;
	bool inTableAlready = false;
	CLabelTableEntry* labelEntry = nullptr;
	temp[0] = 0;
	do {
		labelEntry = LabelTable.Find(findName);
		if (labelEntry) {
			inTableAlready = true;
			if (LASTPASS != pass) labelEntry->used = true;
			if (LABEL_PAGE_UNDEFINED != labelEntry->page) break;
			labelEntry = nullptr;
			IsLabelNotFound = 2;
		}
		// not found (the defined one, try more variants)
		if (inMacro) {				// try outer macro (if there is one)
			while ('>' != *findName && '.' != *findName) ++findName;
			// if no more outer macros, try module+non-local prefix with the original local label
			if ('>' == *findName++) {
				inMacro = false;
				if (modNameLen) {
					STRCAT(temp, LINEMAX-2, ModuleName); STRCAT(temp, 2, ".");
				}
				STRCAT(temp, LABMAX-1, vorlabp); STRCAT(temp, 2, ".");
				STRCAT(temp, LABMAX-1, findName);
				findName = temp;
			}
		} else {
			if (!global && !local && fullName == findName && modNameLen) {
				// this still may be global label without current module (but author didn't use "@")
				findName = fullName + modNameLen + 1;
			} else {
				findName = nullptr;	// all options exhausted
			}
		}
	} while (findName);
	if (nullptr == findName) {		// not found, check if it needs to be inserted into table
		// canonical name is either in "temp" (when in-macro) or in "fullName" (outside macro)
		findName = temp[0] ? temp : fullName;
		if (!inTableAlready) {
			LabelTable.Insert(findName, 0, true);
			IsLabelNotFound = 1;
		}
		Error("Label not found", findName);
	}
	delete[] fullName;
	return labelEntry;
}


bool GetLabelPage(char*& p, aint& val) {
	CLabelTableEntry* labelEntry = GetLabel(p);
	val = labelEntry ? labelEntry->page : LABEL_PAGE_UNDEFINED;
	// true even when not found, but valid label name (neeed for expression-eval logic)
	return !getLabel_invalidName;
}

bool GetLabelValue(char*& p, aint& val) {
	CLabelTableEntry* labelEntry = GetLabel(p);
	val = labelEntry ? labelEntry->value : 0;
	// true even when not found, but valid label name (neeed for expression-eval logic)
	return !getLabel_invalidName;
}

int GetLocalLabelValue(char*& op, aint& val) {
	char* p = op;
	if (SkipBlanks(p) || !isdigit((byte)*p)) return 0;
	char* const numberB = p;
	while (isdigit((byte)*p)) ++p;
	const char type = *p|0x20;		// [bB] => 'b', [fF] => 'f'
	if ('b' != type && 'f' != type) return 0;	// local label must have "b" or "f" after number
	const char following = p[1];	// should be EOL, colon or whitespace
	if (0 != following && ':' != following && !White(following)) return 0;
	// numberB -> p are digits to be parsed as integer
	if (!GetNumericValue_IntBased(op = numberB, p, val, 10)) return 0;
	++op;
	// ^^ advance main parsing pointer op beyond the local label (here it *is* local label)
	val = ('b' == type) ? LocalLabelTable.seekBack(val) : LocalLabelTable.seekForward(val);
	if (-1L == val) {
		Error("Local label not found", numberB, SUPPRESS);
		val = 0L;
		return 1;
	}
	return 1;
}

void CLabelTableEntry::ClearData() {
	if (name) free(name);
	name = NULL;
	value = 0;
	updatePass = 0;
	page = LABEL_PAGE_UNDEFINED;
	IsDEFL = IsEQU = used = false;
}

CLabelTableEntry::CLabelTableEntry() : name(NULL) {
	ClearData();
}

CLabelTable::CLabelTable() {
	NextLocation = 1;
}

int CLabelTable::Insert(const char* nname, aint nvalue, bool undefined, bool IsDEFL, bool IsEQU) {
	if (NextLocation >= LABTABSIZE * 2 / 3) {
		Error("Label table full", NULL, FATAL);
	}

	// Find label in label table
	CLabelTableEntry* label = Find(nname);
	if (label) {
		if (!label->IsDEFL && label->page != LABEL_PAGE_UNDEFINED && label->updatePass == pass) {
			return 0;
		} else {
			//if label already added (as used, or in previous pass), just refresh values
			label->value = nvalue;
			label->page = Page ? Page->Number : LABEL_PAGE_ROM;
			// in DISP mode set the page number by DISP page_number, or current device mapping
			if (PseudoORG) {
				label->page = LABEL_PAGE_UNDEFINED != dispPageNum ? dispPageNum :
								DeviceID ? Device->GetPageOfA16(nvalue) : LABEL_PAGE_ROM;
			}
			label->IsDEFL = IsDEFL;
			label->IsEQU = IsEQU;
			label->updatePass = pass;
			return 1;
		}
	}
	int tr = Hash(nname);
	while (HashTable[tr]) {
		if (++tr >= LABTABSIZE) tr = 0;
	}
	HashTable[tr] = NextLocation;
	label = LabelTable + NextLocation++;
	label->name = STRDUP(nname);
	if (label->name == NULL) ErrorOOM();
	label->IsDEFL = IsDEFL;
	label->IsEQU = IsEQU;
	label->updatePass = pass;
	label->value = nvalue;
	label->used = undefined;
	if (!undefined) {
		label->page = Page ? Page->Number : LABEL_PAGE_ROM;
		// in DISP mode set the page number by DISP page_number, or current device mapping
		if (PseudoORG) {
			label->page = LABEL_PAGE_UNDEFINED != dispPageNum ? dispPageNum :
							DeviceID ? Device->GetPageOfA16(nvalue) : LABEL_PAGE_ROM;
		}
	} else {
		label->page = LABEL_PAGE_UNDEFINED;
	}
	return 1;
}

int CLabelTable::Update(char* nname, aint nvalue) {
	CLabelTableEntry* label = Find(nname);
	if (label) label->value = nvalue;
	return NULL != label;
}

CLabelTableEntry* CLabelTable::Find(const char* name, bool onlyDefined)
{
	//FIXME get rid of this manual hash table implementation (seems still bugged for edge cases)
	int tr, htr, otr;
	otr = tr = Hash(name);
	while ((htr = HashTable[tr])) {
		if (LabelTable[htr].name && !strcmp(LabelTable[htr].name, name)) {
			if (onlyDefined && LABEL_PAGE_UNDEFINED == LabelTable[htr].page) return NULL;
			return LabelTable+htr;
		}
		if (LABTABSIZE <= ++tr) tr = 0;
		if (tr == otr) break;
	}
	return NULL;
}

bool CLabelTable::IsUsed(const char* name) {
	CLabelTableEntry* label = Find(name);
	return label ? label->used : false;
}

bool CLabelTable::Remove(const char* name) {
	CLabelTableEntry* label = Find(name);
	if (label) label->ClearData();
	return NULL != label;
}

void CLabelTable::RemoveAll() {
	for (int i = 1; i < NextLocation; ++i) LabelTable[i].ClearData();
	NextLocation = 1;
}

int CLabelTable::Hash(const char* s) {
	const char* ss = s;
	unsigned int h = 0,g;
	for (; *ss != '\0'; ss++) {
		h = (h << 4) + *ss;
		if ((g = h & 0xf0000000)) {
			h ^= g >> 24; h ^= g;
		}
	}
	return h % LABTABSIZE;
}

void CLabelTable::Dump() {
	FILE* listFile = GetListingFile();
	if (NULL == listFile) return;		// listing file must be already opened here

	char line[LINEMAX], *ep;
	fputs("\nValue    Label\n", listFile);
	fputs("------ - -----------------------------------------------------------\n", listFile);
	for (int i = 1; i < NextLocation; ++i) {
		if (LABEL_PAGE_UNDEFINED != LabelTable[i].page) {
			ep = line;
			*(ep) = 0;
			*(ep++) = '0';
			*(ep++) = 'x';
			PrintHexAlt(ep, LabelTable[i].value);
			*(ep++) = ' ';
			*(ep++) = LabelTable[i].used ? ' ' : 'X';
			*(ep++) = ' ';
			STRCPY(ep, LINEMAX - (ep - line), LabelTable[i].name);
			ep += strlen(LabelTable[i].name);
			*(ep++) = '\n';
			*(ep) = 0;
			fputs(line, listFile);
		}
	}
}

void CLabelTable::DumpForUnreal() {
	char ln[LINEMAX], * ep;
	FILE* FP_UnrealList;
	if (!FOPEN_ISOK(FP_UnrealList, Options::UnrealLabelListFName, "w")) {
		Error("Error opening file", Options::UnrealLabelListFName, FATAL);
	}
	const int PAGE_MASK = DeviceID ? Device->GetPage(0)->Size - 1 : 0x3FFF;
	for (int i = 1; i < NextLocation; ++i) {
		if (LABEL_PAGE_UNDEFINED == LabelTable[i].page) continue;
		int page = LabelTable[i].page;
		if (!strcmp(DeviceID, "ZXSPECTRUM48") && page < 4) {	//TODO fix this properly?
			// convert pages {0, 1, 2, 3} of ZX48 into ZX128-like {ROM, 5, 2, 0}
			// this can be fooled when there were multiple devices used, Label doesn't know into
			// which device it does belong, so even ZX128 labels will be converted.
			const int fakeZx128Pages[] = {LABEL_PAGE_ROM, 5, 2, 0};
			page = fakeZx128Pages[page];
		}
		int lvalue = LabelTable[i].value & PAGE_MASK;
		ep = ln;
		if (page < LABEL_PAGE_ROM) ep += sprintf(ep, "%02d", page&255);
		*(ep++) = ':';
		PrintHexAlt(ep, lvalue);
		*(ep++) = ' ';
		STRCPY(ep, LINEMAX-(ep-ln), LabelTable[i].name);
		STRCAT(ep, LINEMAX, "\n");
		fputs(ln, FP_UnrealList);
	}
	fclose(FP_UnrealList);
}

void CLabelTable::DumpForCSpect() {
	FILE* file;
	if (!FOPEN_ISOK(file, Options::CSpectMapFName, "w")) {
		Error("Error opening file", Options::CSpectMapFName, FATAL);
	}
	const int PAGE_SIZE = DeviceID ? Device->GetPage(0)->Size : 0x4000;
	const int PAGE_MASK = PAGE_SIZE - 1;
	for (int i = 1; i < NextLocation; ++i) {
		if (LABEL_PAGE_UNDEFINED == LabelTable[i].page) continue;
		const int labelType =
			LabelTable[i].IsEQU ? 1 :
			LabelTable[i].IsDEFL ? 2 :
			(LABEL_PAGE_ROM == LabelTable[i].page) ? 3 : 0;
		const short page = labelType ? 0 : LabelTable[i].page;
		const aint longAddress = (PAGE_MASK & LabelTable[i].value) + page * PAGE_SIZE;
		fprintf(file, "%08X %08X %02X ", 0xFFFF & LabelTable[i].value, longAddress, labelType);
		// convert primary+local label to be "@" delimited (not "." delimited)
		STRCPY(temp, LINEMAX, LabelTable[i].name);
		// look for "primary" label (where the local label starts)
		char* localLabelStart = strrchr(temp, '.');
		while (temp < localLabelStart) {	// the dot must be at least second character
			*localLabelStart = 0;			// terminate the possible "primary" part
			CLabelTableEntry* label = Find(temp, true);
			if (label) {
				*localLabelStart = '@';		// "primary" label exists, modify delimiter '.' -> '@'
				break;
			}
			*localLabelStart = '.';			// "primary" label didn't work, restore dot
			do {
				--localLabelStart;			// and look for next dot
			} while (temp < localLabelStart && '.' != *localLabelStart);
		}
		fprintf(file, "%s\n", temp);
	}
	fclose(file);
}

void CLabelTable::DumpSymbols() {
	FILE* symfp;
	if (!FOPEN_ISOK(symfp, Options::SymbolListFName, "w")) {
		Error("Error opening file", Options::SymbolListFName, FATAL);
	}
	for (int i = 1; i < NextLocation; ++i) {
		if (LabelTable[i].name && isalpha((byte)LabelTable[i].name[0])) {
			STRCPY(ErrorLine, LINEMAX, LabelTable[i].name);
			STRCAT(ErrorLine, LINEMAX2-1, ": equ ");
			STRCAT(ErrorLine, LINEMAX2-1, "0x");
			char lnrs[16], * l = lnrs;
			PrintHex32(l, LabelTable[i].value);
			*l = 0;
			STRCAT(ErrorLine, LINEMAX2-1, lnrs);
			STRCAT(ErrorLine, LINEMAX2-1, "\n");
			fputs(ErrorLine, symfp);
		}
	}
	fclose(symfp);
}

CFunctionTable::CFunctionTable() {
	NextLocation = 1;
}

int CFunctionTable::Insert(const char* nname, void(*nfunp) (void)) {
	char* p;
	if (NextLocation >= FUNTABSIZE * 2 / 3) {
		Error("Functions Table is full", NULL, FATAL);
	}
	int tr, htr;
	tr = Hash(nname);
	while ((htr = HashTable[tr])) {
		if (!strcmp((funtab[htr].name), nname)) {
			return 0;
		} else if (++tr >= FUNTABSIZE) {
			tr = 0;
		}
	}
	HashTable[tr] = NextLocation;
	funtab[NextLocation].name = STRDUP(nname);
	if (funtab[NextLocation].name == NULL) ErrorOOM();
	funtab[NextLocation].funp = nfunp;
	++NextLocation;

	STRCPY(p = temp, LINEMAX, nname);
	while ((*p = (char) toupper((byte)*p))) { ++p; }

	if (NextLocation >= FUNTABSIZE * 2 / 3) {
		Error("Functions Table is full", NULL, FATAL);
	}
	tr = Hash(temp);
	while ((htr = HashTable[tr])) {
		if (!strcmp((funtab[htr].name), temp)) {
			return 0;
		} else if (++tr >= FUNTABSIZE) {
			tr = 0;
		}
	}
	HashTable[tr] = NextLocation;
	funtab[NextLocation].name = STRDUP(temp);
	if (funtab[NextLocation].name == NULL) ErrorOOM();
	funtab[NextLocation].funp = nfunp;
	++NextLocation;

	return 1;
}

int CFunctionTable::insertd(const char* name, void(*nfunp) (void)) {
	if ('.' != name[0]) Error("Directive string must start with dot", NULL, FATAL);
	// insert the non-dot variant first, then dot variant
	return Insert(name+1, nfunp) && Insert(name, nfunp);
}

int CFunctionTable::zoek(const char* nname) {
	int tr, htr, otr;
	otr = tr = Hash(nname);
	while ((htr = HashTable[tr])) {
		if (!strcmp((funtab[htr].name), nname)) {
			(*funtab[htr].funp)();
			return 1;
		}
		if (++tr >= FUNTABSIZE) tr = 0;
		if (tr == otr) break;
	}
	return 0;
}

int CFunctionTable::Find(char* nname) {
	int tr, htr, otr;
	otr = tr = Hash(nname);
	while ((htr = HashTable[tr])) {
		if (!strcmp((funtab[htr].name), nname)) {
			return 1;
		}
		if (++tr >= FUNTABSIZE) {
			tr = 0;
		}
		if (tr == otr) {
			break;
		}
	}
	return 0;
}

int CFunctionTable::Hash(const char* s) {
	const char* ss = s;
	unsigned int h = 0;
	for (; *ss != '\0'; ss++) {
		h = (h << 3) + *ss;
	}
	return h % FUNTABSIZE;
}

CLocalLabelTableEntry::CLocalLabelTableEntry(aint number, aint address, CLocalLabelTableEntry* previous) {
	nummer = number;
	value = address;
	prev = previous; next = NULL;
	if (previous) previous->next = this;
}

CLocalLabelTable::CLocalLabelTable() {
	first = last = refresh = NULL;
}

CLocalLabelTable::~CLocalLabelTable() {
	while (last) {		// release all local labels
		refresh = last->prev;
		delete last;
		last = refresh;
	}
}

void CLocalLabelTable::InitPass() {
	// reset refresh pointer for next pass
	refresh = first;
}

bool CLocalLabelTable::insertImpl(const aint labelNumber) {
	last = new CLocalLabelTableEntry(labelNumber, CurAddress, last);
	if (!first) first = last;
	return true;
}

bool CLocalLabelTable::refreshImpl(const aint labelNumber) {
	if (!refresh || refresh->nummer != labelNumber) return false;
	if (refresh->value != CurAddress) Warning("Local label has different address");
	refresh->value = CurAddress;
	refresh = refresh->next;
	return true;
}

bool CLocalLabelTable::InsertRefresh(const aint nnummer) {
	return (1 == pass) ? insertImpl(nnummer) : refreshImpl(nnummer);
}

aint CLocalLabelTable::seekForward(const aint labelNumber) const {
	if (1 == pass) return 0;			// just building tables in first pass, no results yet
	CLocalLabelTableEntry* l = refresh;	// already points on first "forward" local label
	while (l && l->nummer != labelNumber) l = l->next;
	return l ? l->value : -1L;
}

aint CLocalLabelTable::seekBack(const aint labelNumber) const {
	if (1 == pass) return 0;			// just building tables in first pass, no results yet
	CLocalLabelTableEntry* l = refresh ? refresh->prev : last;
	while (l && l->nummer != labelNumber) l = l->prev;
	return l ? l->value : -1L;
}

CStringsList::CStringsList() : string(NULL), next(NULL)
{
	// all initialized already
}

CStringsList::~CStringsList() {
	if (string) free(string);
	if (next) delete next;
}


CDefineTableEntry::CDefineTableEntry(const char* nname, const char* nvalue, CStringsList* nnss, CDefineTableEntry* nnext)
		: name(NULL), value(NULL) {
	name = STRDUP(nname);
	value = new char[strlen(nvalue) + 1];
	if (NULL == name || NULL == value) ErrorOOM();
	char* s1 = value;
	while (White(*nvalue)) ++nvalue;
	while (*nvalue && *nvalue != '\n' && *nvalue != '\r') *s1++ = *nvalue++;
	*s1 = 0;
	next = nnext;
	nss = nnss;
}

CDefineTableEntry::~CDefineTableEntry() {
	if (name) free(name);
	if (value) delete[] value;
	if (nss) delete nss;
	if (next) delete next;
}

CDefineTable::~CDefineTable() {
	for (auto def : defs) if (def) delete def;
}

CDefineTable& CDefineTable::operator=(CDefineTable const & defTable) {
	RemoveAll();
	for (CDefineTableEntry* srcDef : defTable.defs) {
		CDefineTableEntry* srcD = srcDef;
		while (srcD) {
			Add(srcD->name, srcD->value, srcD->nss);
			srcD = srcD->next;
		}
	}
	return *this;
}

void CDefineTable::Init() {
	DefArrayList = NULL;
	for (auto & def : defs) def = NULL;
}

void CDefineTable::Add(const char* name, const char* value, CStringsList* nss) {
	if (FindDuplicate(name)) {
		Error("Duplicate define (replacing old value)", name);
	}
	defs[(*name)&127] = new CDefineTableEntry(name, value, nss, defs[(*name)&127]);
}

char* CDefineTable::Get(const char* name) {
	if (NULL != name) {
		CDefineTableEntry* p = defs[(*name)&127];
		while (p) {
			if (!strcmp(name, p->name)) {
				DefArrayList = p->nss;
				return p->value;
			}
			p = p->next;
		}
	}
	DefArrayList = NULL;
	return NULL;
}

int CDefineTable::FindDuplicate(const char* name) {
	CDefineTableEntry* p = defs[(*name)&127];
	while (p) {
		if (!strcmp(name, p->name)) {
			return 1;
		}
		p = p->next;
	}
	return 0;
}

int CDefineTable::Replace(const char* name, const char* value) {
	CDefineTableEntry* p = defs[(*name)&127];
	while (p) {
		if (!strcmp(name, p->name)) {
			delete[](p->value);
			p->value = new char[strlen(value)+1];
			strcpy(p->value,value);
			return 0;
		}
		p = p->next;
	}
	defs[(*name)&127] = new CDefineTableEntry(name, value, 0, defs[(*name)&127]);
	return 1;
}

int CDefineTable::Replace(const char* name, const int value) {
	char newIntValue[24];
	SPRINTF1(newIntValue, sizeof(newIntValue), "%d", value);
	return Replace(name, newIntValue);
}

int CDefineTable::Remove(const char* name) {
	CDefineTableEntry* p = defs[(*name)&127];
	CDefineTableEntry* p2 = NULL;
	while (p) {
		if (!strcmp(name, p->name)) {
			// unchain the particular item
			if (NULL == p2) defs[(*name)&127] = p->next;
			else			p2->next = p->next;
			p->next = NULL;
			// delete it
			delete p;
			DefArrayList = NULL;		// may be invalid here, so just reset it
			return 1;
		}
		p2 = p;
		p = p->next;
	}
	return 0;
}

void CDefineTable::RemoveAll() {
	DefArrayList = NULL;
	for (auto & def : defs) {
		if (!def) continue;
		delete def;
		def = NULL;
	}
}

CMacroDefineTable::CMacroDefineTable() : defs(nullptr) {
	for (auto & usedX : used) usedX = false;
}

CMacroDefineTable::~CMacroDefineTable() {
	if (defs) delete defs;
}

void CMacroDefineTable::ReInit() {
	if (defs) delete defs;
	defs = nullptr;
	for (auto & usedX : used) usedX = false;
}

void CMacroDefineTable::AddMacro(char* naam, char* vervanger) {
	CDefineTableEntry* tmpdefs = new CDefineTableEntry(naam, vervanger, 0, defs);
	defs = tmpdefs;
	used[(*naam)&127] = true;
}

CDefineTableEntry* CMacroDefineTable::getdefs() {
	return defs;
}

void CMacroDefineTable::setdefs(CDefineTableEntry* const ndefs) {
	if (ndefs == defs) return;			// the current HEAD of defines is already same as requested one
	// traverse through current HEAD until the requested chain is found, unchain the HEAD from it
	CDefineTableEntry* entry = defs;
	while (entry && ndefs != entry->next) entry = entry->next;
	if (entry) entry->next = nullptr;	// if "ndefs" is chained to current HEAD, unchain
	if (defs) delete defs;				// release front part of current chain from memory
	defs = ndefs;						// the requested chain is new current HEAD
}

char* CMacroDefineTable::getverv(char* name) {
	CDefineTableEntry* p = defs;
	if (!used[(*name)&127]) return NULL;
	while (p) {
		if (!strcmp(name, p->name)) return p->value;
		p = p->next;
	}
	return NULL;
}

int CMacroDefineTable::FindDuplicate(char* name) {
	CDefineTableEntry* p = defs;
	if (!used[(*name)&127]) {
		return 0;
	}
	while (p) {
		if (!strcmp(name, p->name)) {
			return 1;
		}
		p = p->next;
	}
	return 0;
}

CStringsList::CStringsList(const char* stringSource, CStringsList* nnext) {
	string = STRDUP(stringSource);
	next = nnext;
	source = CurSourcePos;
	definition = DefinitionPos.line ? DefinitionPos : CurSourcePos;
}

CMacroTableEntry::CMacroTableEntry(char* nnaam, CMacroTableEntry* nnext) {
	naam = nnaam; next = nnext; args = body = NULL;
}

CMacroTableEntry::~CMacroTableEntry() {
	if (naam) free(naam);	// must be of STRDUP origin!
	if (args) delete args;
	if (body) delete body;
	if (next) delete next;
}

CMacroTable::CMacroTable() : macs(nullptr) {
	for (auto & usedX : used) usedX = false;
}

CMacroTable::~CMacroTable() {
	if (macs) delete macs;
}

void CMacroTable::ReInit() {
	if (macs) delete macs;
	macs = nullptr;
	for (auto & usedX : used) usedX = false;
}

int CMacroTable::FindDuplicate(char* naam) {
	CMacroTableEntry* p = macs;
	if (!used[(*naam)&127]) {
		return 0;
	}
	while (p) {
		if (!strcmp(naam, p->naam)) {
			return 1;
		}
		p = p->next;
	}
	return 0;
}

void CMacroTable::Add(char* nnaam, char*& p) {
	char* n;
	CStringsList* s,* l = NULL,* f = NULL;
	if (FindDuplicate(nnaam)) {
		Error("Duplicate macroname", nnaam);return;
	}
	char* macroname = STRDUP(nnaam);
	if (macroname == NULL) ErrorOOM();
	macs = new CMacroTableEntry(macroname, macs);
	used[(*macroname)&127] = true;
	SkipBlanks(p);
	while (*p) {
		if (!(n = GetID(p))) {
			Error("Illegal macro argument", p, EARLY); break;
		}
		s = new CStringsList(n); if (!f) {
									  	f = s;
									  } if (l) {
											l->next = s;
										} l = s;
		SkipBlanks(p); if (*p == ',') {
					   	++p;
					   } else {
					   	break;
					   }
	}
	macs->args = f;
	if (*p) {
		Error("Unexpected", p, EARLY);
	}
	ListFile();
	if (!ReadFileToCStringsList(macs->body, "endm")) {
		Error("Unexpected end of macro", NULL, EARLY);
	}
}

int CMacroTable::Emit(char* naam, char*& p) {
	// search for the desired macro
	if (!used[(*naam)&127]) return 0;
	CMacroTableEntry* m = macs;
	while (m && strcmp(naam, m->naam)) m = m->next;
	if (!m) return 0;
	// macro found, emit it, prepare temporary instance label base
	char* omacrolabp = macrolabp;
	char labnr[LINEMAX], ml[LINEMAX];
	SPRINTF1(labnr, LINEMAX, "%d", macronummer++);
	macrolabp = labnr;
	if (omacrolabp) {
		STRCAT(macrolabp, LINEMAX-1, "."); STRCAT(macrolabp, LINEMAX-1, omacrolabp);
	} else {
		MacroDefineTable.ReInit();
	}
	// parse argument values
	CDefineTableEntry* odefs = MacroDefineTable.getdefs();
	CStringsList* a = m->args;
	while (a) {
		char* n = ml;
		const bool lastArg = NULL == a->next;
		if (!GetMacroArgumentValue(p, n) || (!lastArg && !comma(p))) {
			Error("Not enough arguments for macro", naam, SUPPRESS);
			macrolabp = 0;
			return 1;
		}
		MacroDefineTable.AddMacro(a->string, ml);
		a = a->next;
	}
	SkipBlanks(p);
	if (*p) {
		Error("Too many arguments for macro", naam, SUPPRESS);
		macrolabp = 0;
		return 1;
	}
	// arguments parsed, emit the macro lines and parse them
	lp = p;
	ListFile();
	++listmacro;
	CStringsList* olijstp = lijstp;
	lijstp = m->body;
	++lijst;
	STRCPY(ml, LINEMAX, line);
	while (lijstp) {
		DefinitionPos = lijstp->definition;
		STRCPY(line, LINEMAX, lijstp->string);
		substitutedLine = line;		// reset substituted listing
		eolComment = NULL;			// reset end of line comment
		lijstp = lijstp->next;
		ParseLineSafe();
	}
	DefinitionPos = TextFilePos();
	STRCPY(line, LINEMAX, ml);
	lijstp = olijstp;
	--lijst;
	MacroDefineTable.setdefs(odefs);
	macrolabp = omacrolabp;
	--listmacro; donotlist = 1;
	return 2;
}

CStructureEntry1::CStructureEntry1(char* nnaam, aint noffset) {
	next = 0;
	naam = STRDUP(nnaam);
	if (naam == NULL) ErrorOOM();
	offset = noffset;
}

CStructureEntry1::~CStructureEntry1() {
	free(naam);
	if (next) delete next;
}


CStructureEntry2::CStructureEntry2(aint noffset, aint nlen, aint ndef, EStructureMembers ntype) {
	next = 0; offset = noffset; len = nlen; def = ndef; type = ntype;
}

CStructureEntry2::~CStructureEntry2() {
	if (next) delete next;
}

// Parses source input for types: BYTE, WORD, DWORD, D24
aint CStructureEntry2::ParseValue(char* & p) {
	if (SMEMBBYTE != type && SMEMBWORD != type && SMEMBDWORD != type && SMEMBD24 != type) return def;
	SkipBlanks(p);
	if ('{' == *p) return def;	// unexpected {
	aint val;
	if (!ParseExpressionNoSyntaxError(p, val)) val = def;
	switch (type) {
		case SMEMBBYTE:
			check8(val);
			return(val & 0xFF);
		case SMEMBWORD:
			check16(val);
			return(val & 0xFFFF);
		case SMEMBD24:
			check24(val);
			return(val & 0xFFFFFF);
		case SMEMBDWORD:
			return val;
		default:
			return def;
	}
}

CStructure::CStructure(const char* nnaam, char* nid, int no, int ngl, CStructure* p) {
	mnf = mnl = NULL; mbf = mbl = NULL;
	naam = STRDUP(nnaam);
	if (naam == NULL) ErrorOOM();
	id = STRDUP(nid);
	if (id == NULL) ErrorOOM();
	next = p; noffset = no; global = ngl;
	maxAlignment = 0;
}

CStructure::~CStructure() {
	free(naam);
	free(id);
	if (mnf) delete mnf;
	if (mbf) delete mbf;
	if (next) delete next;
}

void CStructure::AddLabel(char* nnaam) {
	CopyLabel(nnaam, 0);
}

void CStructure::AddMember(CStructureEntry2* n) {
	if (!mbf)	mbf = n;
	else 		mbl->next = n;
	mbl = n;
	noffset += n->len;
}

void CStructure::CopyLabel(char* nnaam, aint offset) {
	CStructureEntry1* n = new CStructureEntry1(nnaam, noffset + offset);
	if (!mnf)	mnf = n;
	else		mnl->next = n;
	mnl = n;
}

void CStructure::CopyLabels(CStructure* st) {
	CStructureEntry1* np = st->mnf;
	if (!np || !PreviousIsLabel) return;
	char str[LINEMAX];
	STRCPY(str, LINEMAX-1, PreviousIsLabel);
	STRCAT(str, LINEMAX-1, ".");
	char * const stw = str + strlen(str);
	while (np) {
		STRCPY(stw, LINEMAX, np->naam);	// overwrite the second part of label
		CopyLabel(str, np->offset);
		np = np->next;
	}
}

void CStructure::CopyMember(CStructureEntry2* ni, aint ndef) {
	AddMember(new CStructureEntry2(noffset, ni->len, ndef, ni->type));
}

void CStructure::CopyMembers(CStructure* st, char*& lp) {
	aint val;
	int haakjes = 0;
	AddMember(new CStructureEntry2(noffset, 0, 0, SMEMBPARENOPEN));
	SkipBlanks(lp);
	if (*lp == '{') {
		++haakjes; ++lp;
	}
	CStructureEntry2* ip = st->mbf;
	while (ip) {
		switch (ip->type) {
		case SMEMBBLOCK:
			CopyMember(ip, ip->def);
			break;
		case SMEMBBYTE:
		case SMEMBWORD:
		case SMEMBD24:
		case SMEMBDWORD:
			if (!ParseExpressionNoSyntaxError(lp, val)) val = ip->def;
			CopyMember(ip, val);
			if (ip->next && SMEMBPARENCLOSE != ip->next->type) anyComma(lp);
			break;
		case SMEMBPARENOPEN:
			SkipBlanks(lp);
			if (*lp == '{') {
				++haakjes; ++lp;
			}
			CopyMember(ip, 0);
			break;
		case SMEMBPARENCLOSE:
			SkipBlanks(lp);
			if (haakjes && *lp == '}') {
				--haakjes; ++lp;
				if (ip->next && SMEMBPARENCLOSE != ip->next->type) anyComma(lp);
			}
			CopyMember(ip, 0);
			break;
		default:
			Error("internalerror CStructure::CopyMembers", NULL, FATAL);
		}
		ip = ip->next;
	}
	while (haakjes--) {
		if (!need(lp, '}')) Error("closing } missing");
	}
	AddMember(new CStructureEntry2(noffset, 0, 0, SMEMBPARENCLOSE));
}

static void InsertSingleStructLabel(char *name, const aint value) {
	char *op = name, *p;
	if (!(p = ValidateLabel(op, true))) {
		Error("Illegal labelname", op, EARLY);
		return;
	}
	if (pass == LASTPASS) {
		aint oval;
		if (!GetLabelValue(op, oval)) {
			Error("Internal error. ParseLabel()", op, FATAL);
		}
		if (value != oval) {
			Error("Label has different value in pass 2", p);
		}
	} else {
		if (!LabelTable.Insert(p, value, false, false, true)) Error("Duplicate label", p, EARLY);
	}
	delete[] p;
}

static void InsertStructSubLabels(const char* mainName, const CStructureEntry1* members, const aint address = 0) {
	char ln[LINEMAX+1];
	STRCPY(ln, LINEMAX, mainName);
	char * const lnsubw = ln + strlen(ln);
	while (members) {
		STRCPY(lnsubw, LINEMAX-strlen(ln), members->naam);		// overwrite sub-label part
		InsertSingleStructLabel(ln, members->offset + address);
		members = members->next;
	}
}

void CStructure::deflab() {
	char sn[LINEMAX] = { '@' };
	STRCPY(sn+1, LINEMAX-1, id);
	InsertSingleStructLabel(sn, noffset);
	STRCAT(sn, LINEMAX-1, ".");
	InsertStructSubLabels(sn, mnf);
}

void CStructure::emitlab(char* iid, aint address) {
	const aint misalignment = maxAlignment ? ((-address) & (maxAlignment - 1)) : 0;
	if (misalignment) {
		// emitting in misaligned position (considering the ALIGN used to define this struct)
		char warnTxt[LINEMAX];
		SPRINTF3(warnTxt, LINEMAX,
					"Struct %s did use ALIGN %d in definition, but here it is misaligned by %d bytes",
					naam, maxAlignment, misalignment);
		Warning(warnTxt);
	}
	char sn[LINEMAX];
	STRCPY(sn, LINEMAX-1, iid);
	InsertSingleStructLabel(sn, address);
	STRCAT(sn, LINEMAX-1, ".");
	InsertStructSubLabels(sn, mnf, address);
}

void CStructure::emitmembs(char*& p) {
	aint val;
	int haakjes = 0;
	SkipBlanks(p);
	if (*p == '{') {
		++haakjes; ++p;
	}
	CStructureEntry2* ip = mbf;
	while (ip) {
		switch (ip->type) {
		case SMEMBBLOCK:
			EmitBlock(ip->def != -1 ? ip->def : 0, ip->len, ip->def == -1, 8);
			break;
		case SMEMBBYTE:
			EmitByte(ip->ParseValue(p));
			if (ip->next && SMEMBPARENCLOSE != ip->next->type) anyComma(p);
			break;
		case SMEMBWORD:
			EmitWord(ip->ParseValue(p));
			if (ip->next && SMEMBPARENCLOSE != ip->next->type) anyComma(p);
			break;
		case SMEMBD24:
			val = ip->ParseValue(p);
			EmitByte(val & 0xFF);
			EmitWord((val>>8) & 0xFFFF);
			if (ip->next && SMEMBPARENCLOSE != ip->next->type) anyComma(p);
			break;
		case SMEMBDWORD:
			val = ip->ParseValue(p);
			EmitWord(val & 0xFFFF);
			EmitWord((val>>16) & 0xFFFF);
			if (ip->next && SMEMBPARENCLOSE != ip->next->type) anyComma(p);
			break;
		case SMEMBPARENOPEN:
			SkipBlanks(p);
			if (*p == '{') { ++haakjes; ++p; }
			break;
		case SMEMBPARENCLOSE:
			SkipBlanks(p);
			if (haakjes && *p == '}') {
				--haakjes; ++p;
			}
			if (ip->next && SMEMBPARENCLOSE != ip->next->type) anyComma(p);
			break;
		default:
			ErrorInt("Internal Error CStructure::emitmembs", ip->type, FATAL);
		}
		ip = ip->next;
	}
	while (haakjes--) {
		if (!need(p, '}')) Error("closing } missing");
	}
	if (!SkipBlanks(p)) Error("[STRUCT] Syntax error - too many arguments?");
}

CStructureTable::CStructureTable() {
	for (auto & structPtr : strs) structPtr = nullptr;
}

CStructureTable::~CStructureTable() {
	for (auto structPtr : strs) if (structPtr) delete structPtr;
}

void CStructureTable::ReInit() {
	for (auto & structPtr : strs) {
		if (structPtr) delete structPtr;
		structPtr = nullptr;
	}
}

CStructure* CStructureTable::Add(char* naam, int no, int gl) {
	char sn[LINEMAX], * sp;
	sn[0] = 0;
	if (!gl && *ModuleName) {
		STRCPY(sn, LINEMAX-2, ModuleName);
		STRCAT(sn, 2, ".");
	}
	STRCAT(sn, LINEMAX-1, naam);
	sp = sn;
	if (FindDuplicate(sp)) {
		Error("Duplicate structure name", naam, EARLY);
	}
	strs[(*sp)&127] = new CStructure(naam, sp, 0, gl, strs[(*sp)&127]);
	if (no) {
		strs[(*sp)&127]->AddMember(new CStructureEntry2(0, no, -1, SMEMBBLOCK));
	}
	return strs[(*sp)&127];
}

CStructure* CStructureTable::zoek(const char* naam, int gl) {
	char sn[LINEMAX], * sp;
	sn[0] = 0;
	if (!gl && *ModuleName) {
		STRCPY(sn, LINEMAX-2, ModuleName);
		STRCAT(sn, 2, ".");
	}
	STRCAT(sn, LINEMAX-1, naam);
	sp = sn;
	CStructure* p = strs[(*sp)&127];
	while (p) {
		if (!strcmp(sp, p->id)) return p;
		p = p->next;
	}
	if (gl || ! *ModuleName) return NULL;
	sp += 1 + strlen(ModuleName); p = strs[(*sp)&127];
	while (p) {
		if (!strcmp(sp, p->id)) return p;
		p = p->next;
	}
	return NULL;
}

int CStructureTable::FindDuplicate(char* naam) {
	CStructure* p = strs[(*naam)&127];
	while (p) {
		if (!strcmp(naam, p->naam)) return 1;
		p = p->next;
	}
	return 0;
}

aint CStructureTable::ParseDesignedAddress(char* &p) {
	if (!SkipBlanks(p) && ('=' == *p)) {
		char* adrP = ++p;
		aint resultAdr;
		if (ParseExpressionNoSyntaxError(p, resultAdr)) return resultAdr;
		Error("[STRUCT] Syntax error in designed address", adrP, SUPPRESS);
		return 0;
	}
	return INT_MAX;		// no "designed address" provided, emit structure bytes
}

int CStructureTable::Emit(char* naam, char* l, char*& p, int gl) {
	CStructure* st = zoek(naam, gl);
	if (!st) return 0;
	// create new labels corresponding to current/designed address
	aint address = CStructureTable::ParseDesignedAddress(p);
	if (l) st->emitlab(l, (INT_MAX == address) ? CurAddress : address);
	if (INT_MAX == address) st->emitmembs(p);	// address was not designed, emit also bytes
	else if (!l) Warning("[STRUCT] designed address without label = no effect");
	return 1;
}

int LuaGetLabel(char *name) {
	//TODO v2.0: deprecated, use default "calculate" feature to get identical results as asm line
	aint val;
	if (!GetLabelValue(name, val)) val = -1;
	return val;
}

//eof tables.cpp
