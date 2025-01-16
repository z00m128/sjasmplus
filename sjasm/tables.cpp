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

TextFilePos::TextFilePos(const char* fileNamePtr, uint32_t line) : filename(fileNamePtr), line(line), colBegin(0), colEnd(0) {
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

// since v1.18.0:
// The ignore invalid char after feature disconnected from "setNameSpace" to "ignoreCharAfter"
// (it's for evaluating labels straight from the expressions, without copying them out first)
// The prefix "!" is now recognized as "do not set main label" for following local labels
// since v1.18.3:
// Inside macro prefix "@." will create non-macro local label instead of macro's instance
char* ValidateLabel(const char* naam, bool setNameSpace, bool ignoreCharAfter) {
	if (nullptr == naam) {
		Error("Invalid labelname");
		return nullptr;
	}
	if ('!' == *naam) {
		setNameSpace = false;
		++naam;
	}
	// check if local label defined inside macro wants to become non-macro local label
	const bool escMacro = setNameSpace && macrolabp && ('@' == naam[0]) && ('.' == naam[1]);
	if (escMacro) ++naam;			// such extra "@" is consumed right here and only '.' is left
	// regular single prefix case in other use cases
	const bool global = '@' == *naam;
	const bool local = '.' == *naam;
	if (!isLabelStart(naam)) {		// isLabelStart assures that only single modifier exist
		if (global || local) ++naam;// single modifier is parsed (even when invalid name)
		Error("Invalid labelname", naam);
		return nullptr;
	}
	if (global || local) ++naam;	// single modifier is parsed
	const bool inMacro = !escMacro && local && macrolabp;
	const bool inModule = !inMacro && !global && ModuleName[0];
	// check all chars of label
	const char* np = naam;
	while (islabchar(*np)) ++np;
	if ('[' == *np) return nullptr;	// this is DEFARRAY name, do not process it as label (silent exit)
	if (*np && !ignoreCharAfter) {
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
	char* const label = new char[1+labelLen];
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

static char sldLabelExport[2*LINEMAX];

char* ExportLabelToSld(const char* naam, const SLabelTableEntry* label) {
	// does re-parse the original source line again similarly to ValidateLabel
	// but prepares SLD 'L'-type line, with module/main/local comma separated + usage traits info
	assert(nullptr != label);
	assert(isLabelStart(naam));		// this should be called only when ValidateLabel did succeed
	const bool global = '@' == *naam;
	const bool local = '.' == *naam;
	if (global || local) ++naam;	// single modifier is parsed
	const bool inMacro = local && macrolabp;
	const bool inModule = !inMacro && !global && ModuleName[0];
	const bool isStructLabel = (label->traits & (LABEL_IS_STRUCT_D|LABEL_IS_STRUCT_E));
	// build fully qualified SLD info
	sldLabelExport[0] = 0;
	// module part
	if (inModule) STRCAT(sldLabelExport, LINEMAX, ModuleName);
	STRCAT(sldLabelExport, 2, ",");
	// main label part (the `vorlabp` is already the current label, if it was main label)
	// except for structure labels: the inner ones don't "set namespace" == vorlabp, use "naam" then
	// (but only if the main label of structure itself is not local, if it's local, use vorlabp)
	STRCAT(sldLabelExport, LABMAX, isStructLabel && !local ? naam : inMacro ? macrolabp : vorlabp);
	STRCAT(sldLabelExport, 2, ",");
	// local part
	if (local) STRCAT(sldLabelExport, LABMAX, naam);
	// usage traits
	if (label->traits&LABEL_IS_EQU) STRCAT(sldLabelExport, 20, ",+equ");
	if (inMacro) STRCAT(sldLabelExport, 20, ",+macro");
	if (label->traits&LABEL_IS_SMC) STRCAT(sldLabelExport, 20, ",+smc");
	if (Relocation::REGULAR == label->isRelocatable) STRCAT(sldLabelExport, 20, ",+reloc");
	if (Relocation::HIGH == label->isRelocatable) STRCAT(sldLabelExport, 20, ",+reloc_high");
	if (label->used) STRCAT(sldLabelExport, 20, ",+used");
	if (label->traits&LABEL_IS_STRUCT_D) STRCAT(sldLabelExport, 20, ",+struct_def");
	if (label->traits&LABEL_IS_STRUCT_E) STRCAT(sldLabelExport, 20, ",+struct_data");
	return sldLabelExport;
}

char* ExportModuleToSld(bool endModule) {
	assert(ModuleName[0]);
	STRNCPY(sldLabelExport, 2*LINEMAX, ModuleName, LINEMAX);
	STRCAT(sldLabelExport, LINEMAX-1, endModule ? ",,,+endmod" : ",,,+module");
	return sldLabelExport;
}

static bool getLabel_invalidName = false;

// does parse + consume input source at "p" (and stores result into "fullName")
//  ^^^ may report invalid label name error
// does search (and only search) LabelTable for various variants of label based on "fullName"
// No refresh of "used", no inserting into table when not found, no other errrors reported
// Leaves canonical name in "temp" global variable, if this is inside macro
// returns table entry, preferring the one with "page defined", if multiple entries are found
static SLabelTableEntry* SearchLabel(char*& p, bool setUsed, /*out*/ std::unique_ptr<char[]>& fullName) {
	getLabel_invalidName = true;
	fullName.reset(ValidateLabel(p, false, true));
	if (!fullName) return nullptr;
	getLabel_invalidName = false;
	const bool global = '@' == *p;
	const bool local = '.' == *p;
	while (islabchar(*p)) ++p;		// advance pointer beyond the parsed label
	// find the label entry in the label table (for local macro labels it has to try all sub-parts!)
	// then regular full label has to be tried
	// and if it's regular non-local in module, then variant w/o current module has to be tried
	bool inMacro = local && macrolabp;		// not just inside macro, but should be prefixed
	const int modNameLen = strlen(ModuleName);
	const char *findName = fullName.get();
	SLabelTableEntry* undefinedLabelEntry = nullptr;
	SLabelTableEntry* labelEntry = nullptr;
	temp[0] = 0;
	do {
		labelEntry = LabelTable.Find(findName);
		if (labelEntry) {
			if (setUsed && pass < LASTPASS) labelEntry->used = true;
			if (LABEL_PAGE_UNDEFINED != labelEntry->page) return labelEntry;	// found
			// if found, but "undefined" one, remember it as fall-back result
			undefinedLabelEntry = labelEntry;
			labelEntry = nullptr;
		}
		// not found (the defined one, try more variants)
		if (inMacro) {				// try outer macro (if there is one)
			while ('>' != *findName && '.' != *findName) ++findName;
			// if no more outer macros, try module+non-local prefix with the original local label
			if ('>' == *findName++) {
				inMacro = false;
				if (modNameLen) {
					#pragma GCC diagnostic push	// disable gcc8 warning about truncation - that's intended behaviour
					#if 8 <= __GNUC__
						#pragma GCC diagnostic ignored "-Wstringop-truncation"
					#endif
					STRCAT(temp, LINEMAX-2, ModuleName); STRCAT(temp, 2, ".");
					#pragma GCC diagnostic pop
				}
				STRCAT(temp, LABMAX-1, vorlabp); STRCAT(temp, 2, ".");
				STRCAT(temp, LABMAX-1, findName);
				findName = temp;
			}
		} else {
			if (!global && !local && fullName.get() == findName && modNameLen) {
				// this still may be global label without current module (but author didn't use "@")
				findName = fullName.get() + modNameLen + 1;
			} else {
				findName = nullptr;	// all options exhausted
			}
		}
	} while (findName);
	return undefinedLabelEntry;
}

static SLabelTableEntry* GetLabel(char*& p) {
	std::unique_ptr<char[]> fullName;
	SLabelTableEntry* labelEntry = SearchLabel(p, true, fullName);
	if (getLabel_invalidName) return nullptr;
	if (!labelEntry || LABEL_PAGE_UNDEFINED == labelEntry->page) {
		IsLabelNotFound = true;
		// don't insert labels or report errors during substitution phase
		if (IsSubstituting) return nullptr;
		// regular parsing/assembling, track new labels and report "not found" error
		char* findName = temp[0] ? temp : fullName.get();
		if (!labelEntry) {
			LabelTable.Insert(findName, 0, LABEL_IS_UNDEFINED);
		}
		Error("Label not found", findName, IF_FIRST);
		return nullptr;
	} else {
		return labelEntry;
	}
}

bool LabelExist(char*& p, aint& val) {
	std::unique_ptr<char[]> fullName;
	SLabelTableEntry* labelEntry = SearchLabel(p, false, fullName);
	val = (labelEntry && LABEL_PAGE_UNDEFINED != labelEntry->page) ? -1 : 0;
	return !getLabel_invalidName;
}

bool GetLabelPage(char*& p, aint& val) {
	SLabelTableEntry* labelEntry = GetLabel(p);
	val = labelEntry ? labelEntry->page : LABEL_PAGE_UNDEFINED;
	// true even when not found, but valid label name (neeed for expression-eval logic)
	return !getLabel_invalidName;
}

bool GetLabelValue(char*& p, aint& val) {
	SLabelTableEntry* labelEntry = GetLabel(p);
	if (labelEntry) {
		val = labelEntry->value;
		if (Relocation::areLabelsOffset) {
			switch (labelEntry->isRelocatable) {
				case Relocation::REGULAR:	val += Relocation::alternative_offset;			break;
				case Relocation::HIGH:		val += Relocation::alternative_offset >> 8;		break;
				default:					;
			}
		}
	} else {
		val = 0;
	}
	// true even when not found, but valid label name (needed for expression-eval logic)
	return !getLabel_invalidName;
}

int GetTemporaryLabelValue(char*& op, aint& val, bool requireUnderscore) {
	char* p = op;
	if (SkipBlanks(p) || !isdigit((byte)*p)) return 0;
	char* const numberB = p;
	while (isdigit((byte)*p)) ++p;
	const bool hasUnderscore = ('_' == *p);
	if (requireUnderscore && !hasUnderscore) return 0;
	// convert suffix [bB] => 'b', [fF] => 'f' and ignore underscore
	const char type = (hasUnderscore ? p[1] : p[0]) | 0x20;	// should be 'b' or 'f'
	const char following = hasUnderscore ? p[2] : p[1];		// should be non-label char
	if ('b' != type && 'f' != type) return 0;	// local label must have "b" or "f" after number
	if (islabchar(following)) return 0;			// that suffix didn't end correctly
	// numberB -> p are digits to be parsed as integer
	if (!GetNumericValue_IntBased(op = numberB, p, val, 10)) return 0;
	if ('_' == *op) ++op;
	++op;
	// ^^ advance main parsing pointer op beyond the local label (here it *is* local label)
	auto label = ('b' == type) ? TemporaryLabelTable.seekBack(val) : TemporaryLabelTable.seekForward(val);
	if (label) {
		val = label->value;
		if (requireUnderscore) {				// part of full expression, do relocation by +offset
			if (label->isRelocatable && Relocation::areLabelsOffset) {
				val += Relocation::alternative_offset;
			}
		} else {								// single-label-only in jump/call instructions
			Relocation::isResultAffected = label->isRelocatable;
			Relocation::deltaType = label->isRelocatable ? Relocation::REGULAR : Relocation::OFF;
		}
	} else {
		if (LASTPASS == pass) Error("Temporary label not found", numberB, SUPPRESS);
		val = 0L;
	}
	return 1;
}

static short getAddressPageNumber(const aint address, bool forceRecalculateByAddress) {
	// everything is "ROM" based when device is NONE
	if (!DeviceID) return LABEL_PAGE_ROM;
	// fast-shortcut for regular labels in current slot (if they fit into it)
	auto slot = Device->GetCurrentSlot();
	assert(Page && slot);
	if (!forceRecalculateByAddress && DISP_NONE == PseudoORG) {
		if (slot->Address <= address && address < slot->Address + slot->Size) {
			return Page->Number;
		}
	}
	// enforce explicit request of fake DISP page
	if (DISP_NONE != PseudoORG && LABEL_PAGE_UNDEFINED != dispPageNum) {
		return dispPageNum;
	}
	// in other case (implicit DISP, out-of-slot-bounds or forceRecalculateByAddress)
	// track down the page num from current memory mapping
	const short page = Device->GetPageOfA16(address);
	if (LABEL_PAGE_UNDEFINED == page) return LABEL_PAGE_OUT_OF_BOUNDS;
	return page;
}

int CLabelTable::Insert(const char* nname, aint nvalue, unsigned traits, short equPageNum) {
	const bool IsUndefined = !!(traits & LABEL_IS_UNDEFINED);

	// the EQU/DEFL is relocatable when the expression itself is relocatable
	// the regular label is relocatable when relocation is active
	const Relocation::EType deltaType = \
			(traits&LABEL_HAS_RELOC_TRAIT) ? \
				(traits & LABEL_IS_RELOC ? Relocation::REGULAR : Relocation::OFF) : \
				(traits & (LABEL_IS_DEFL|LABEL_IS_EQU)) ? \
					Relocation::deltaType : \
					Relocation::type && DISP_INSIDE_RELOCATE != PseudoORG ? \
						Relocation::REGULAR : Relocation::OFF;
	// Find label in label table
	symbol_map_t::iterator labelIt = symbols.find(nname);
	if (symbols.end() != labelIt) {
		//if label already added (as used, or in previous pass), just refresh values
		auto& label = labelIt->second;
		if (label.traits&LABEL_IS_KEYWORD) WarningById(W_OPKEYWORD, nname, W_EARLY);
		bool needsUpdate = label.traits&LABEL_IS_DEFL || label.page == LABEL_PAGE_UNDEFINED || label.updatePass < pass;
		if (needsUpdate) {
			label.value = nvalue;
			if ((traits & LABEL_IS_EQU) && LABEL_PAGE_UNDEFINED != equPageNum) {
				label.page = equPageNum;
			} else {
				label.page = getAddressPageNumber(nvalue, traits & (LABEL_IS_DEFL|LABEL_IS_EQU));
			}
			label.traits = traits;
			label.isRelocatable = deltaType;
			label.updatePass = pass;
		}
		return needsUpdate;
	}
	auto& label = symbols[nname];
	label.traits = traits;
	label.updatePass = pass;
	label.value = nvalue;
	label.used = IsUndefined;
	if ((traits & LABEL_IS_EQU) && LABEL_PAGE_UNDEFINED != equPageNum) {
		label.page = equPageNum;
	} else {
		label.page = IsUndefined ? LABEL_PAGE_UNDEFINED : getAddressPageNumber(nvalue, traits & (LABEL_IS_DEFL|LABEL_IS_EQU));
	}
	label.isRelocatable = IsUndefined ? Relocation::OFF : deltaType;	// ignore "relocatable" for "undefined"
	return 1;
}

int CLabelTable::Update(char* name, aint value) {
	auto labelIt = symbols.find(name);
	if (symbols.end() != labelIt) labelIt->second.value = value;
	return (symbols.end() != labelIt);
}

SLabelTableEntry* CLabelTable::Find(const char* name, bool onlyDefined) {
	symbol_map_t::iterator labelIt = symbols.find(name);
	if (symbols.end() == labelIt) return nullptr;
	return (onlyDefined && LABEL_PAGE_UNDEFINED == labelIt->second.page) ? nullptr : &labelIt->second;
}

bool CLabelTable::IsUsed(const char* name) {
	auto labelIt = symbols.find(name);
	return (symbols.end() != labelIt) ? labelIt->second.used : false;
}

bool CLabelTable::Remove(const char* name) {
	return symbols.erase(name);
}

void CLabelTable::RemoveAll() {
	symbols.clear();
}

static const std::vector<symbol_map_t::key_type> getDumpOrder(const symbol_map_t& table) {
	std::vector<symbol_map_t::key_type> order;
	order.reserve(table.size());
	for (const auto& it : table) order.emplace_back(it.first);
	if (Options::SortSymbols) {
		std::sort(
			order.begin(), order.end(),
			[&](const symbol_map_t::key_type& a, const symbol_map_t::key_type& b) {
				// if case insenstive are same, do case sensitive too!
				int caseres = strcasecmp(a.c_str(), b.c_str());
				if (0 == caseres) return a < b;
				return caseres < 0;
			}
		);
	}
	return order;
}

void CLabelTable::Dump() {
	FILE* listFile = GetListingFile();
	if (NULL == listFile) return;		// listing file must be already opened here

	const auto order = getDumpOrder(symbols);

	char line[LINEMAX], *ep;
	fputs("\nValue    Label\n", listFile);
	fputs("------ - -----------------------------------------------------------\n", listFile);
	for (const symbol_map_t::key_type& name: order) {
		const symbol_map_t::mapped_type& symbol = symbols.at(name);
		if (LABEL_PAGE_UNDEFINED == symbol.page) continue;
		ep = line;
		*(ep) = 0;
		*(ep++) = '0';
		*(ep++) = 'x';
		PrintHexAlt(ep, symbol.value);
		*(ep++) = ' ';
		*(ep++) = symbol.used ? ' ' : 'X';
		*(ep++) = ' ';
		STRNCPY(ep, LINEMAX, name.c_str(), LINEMAX - (ep - line) - 2);
		STRNCAT(ep, LINEMAX, "\n", 2);
		fputs(line, listFile);
	}
}

void CLabelTable::DumpForUnreal() {
	char ln[LINEMAX], * ep;
	FILE* FP_UnrealList;
	if (!FOPEN_ISOK(FP_UnrealList, Options::UnrealLabelListFName, "w")) {
		Error("opening file for write", Options::UnrealLabelListFName.c_str(), FATAL);
	}
	const int PAGE_MASK = DeviceID ? Device->GetPage(0)->Size - 1 : 0x3FFF;
	const int ADR_MASK = Options::EmitVirtualLabels ? 0xFFFF : PAGE_MASK;
	const auto order = getDumpOrder(symbols);
	for (const symbol_map_t::key_type& name: order) {
		const symbol_map_t::mapped_type& symbol = symbols.at(name);
		if (LABEL_PAGE_UNDEFINED == symbol.page) continue;
		int page = Options::EmitVirtualLabels ? LABEL_PAGE_OUT_OF_BOUNDS : symbol.page;
		if (!strcmp(DeviceID, "ZXSPECTRUM48") && page < 4) {	//TODO fix this properly?
			// convert pages {0, 1, 2, 3} of ZX48 into ZX128-like {ROM, 5, 2, 0}
			// this can be fooled when there were multiple devices used, Label doesn't know into
			// which device it does belong, so even ZX128 labels will be converted.
			const int fakeZx128Pages[] = {LABEL_PAGE_ROM, 5, 2, 0};
			page = fakeZx128Pages[page];
		}
		int lvalue = symbol.value & ADR_MASK;
		ep = ln;

		if (page < LABEL_PAGE_ROM) ep += sprintf(ep, "%02d", page&255);
		*(ep++) = ':';
		PrintHexAlt(ep, lvalue);

		*(ep++) = ' ';
		STRCPY(ep, LINEMAX-(ep-ln), name.c_str());
		STRCAT(ep, LINEMAX, "\n");
		fputs(ln, FP_UnrealList);
	}
	fclose(FP_UnrealList);
}

void CLabelTable::DumpForCSpect() {
	FILE* file;
	if (!FOPEN_ISOK(file, Options::CSpectMapFName, "w")) {
		Error("opening file for write", Options::CSpectMapFName.c_str(), FATAL);
	}
	const int CSD_PAGE_SIZE = Options::CSpectMapPageSize;
	const int CSD_PAGE_MASK = CSD_PAGE_SIZE - 1;
	const auto order = getDumpOrder(symbols);
	for (const symbol_map_t::key_type& name: order) {
		const symbol_map_t::mapped_type& symbol = symbols.at(name);
		if (LABEL_PAGE_UNDEFINED == symbol.page) continue;
		const int labelType =
			(symbol.traits&LABEL_IS_STRUCT_E) ? 0 :
			(symbol.traits&LABEL_IS_STRUCT_D) ? 4 :
			(symbol.traits&LABEL_IS_EQU) ? 1 :
			(symbol.traits&LABEL_IS_DEFL) ? 2 :
			(LABEL_PAGE_ROM <= symbol.page) ? 3 : 0;
		const short page = labelType ? 0 : symbol.page;
			// TODO:
			// page == -1 will put regular EQU like "BLUE" out of reach for disassembly window
			// (otherwise BLUE becomes label for address $C001 with default mapping)
			// BUT then it would be nice to provide real page data for equ which have them explicit
			// BUT I can't distinguish explicit/implicit page number, as there's heuristic to use current mapping
			// instead of using the LABEL_PAGE_OUT_OF_BOUNDS page number...
			// TODO: figure out when/why the implicit page number heuristic happenned and if you can detect
			// only explicit page numbers used in EQU, and export only those

		const aint longAddress = (CSD_PAGE_MASK & symbol.value) + page * CSD_PAGE_SIZE;
		fprintf(file, "%08X %08X %02X ", 0xFFFF & symbol.value, longAddress, labelType);
		// convert primary+local label to be "@" delimited (not "." delimited)
		STRCPY(temp, LINEMAX, name.c_str());
		// look for "primary" label (where the local label starts)
		char* localLabelStart = strrchr(temp, '.');
		while (temp < localLabelStart) {	// the dot must be at least second character
			*localLabelStart = 0;			// terminate the possible "primary" part
			if (Find(temp, true)) {
				*localLabelStart = '@';
				break;
			}
			*localLabelStart = '.';			// "primary" label didn't work, restore dot
			do {
				--localLabelStart;			// and look for next dot
			} while (temp < localLabelStart && '.' != *localLabelStart);
		}
		// convert whole label to upper-case, as CSpect search is malfunctioning otherwise.
		char* strToUpper = temp;
		while ((*strToUpper = (char) toupper((byte)*strToUpper))) { ++strToUpper; }
		fprintf(file, "%s\n", temp);
	}
	fclose(file);
}

void CLabelTable::DumpSymbols() {
	FILE* symfp;
	if (!FOPEN_ISOK(symfp, Options::SymbolListFName, "w")) {
		Error("opening file for write", Options::SymbolListFName.c_str(), FATAL);
	}
	const auto order = getDumpOrder(symbols);
	for (const symbol_map_t::key_type& name: order) {
		const symbol_map_t::mapped_type& symbol = symbols.at(name);
		if (isdigit((byte)name[0])) continue;
		if (symbol.traits&LABEL_IS_KEYWORD) continue;
		WriteLabelEquValue(name.c_str(), symbol.value, symfp);
	}
	fclose(symfp);
}

int CFunctionTable::Insert(const char* name_cstr, function_fn_t nfunp) {
	std::string name(name_cstr);
	if (!std::get<1>(functions.emplace(name, nfunp))) return 0;
	for (auto& c : name) c = toupper(c);
	return std::get<1>(functions.emplace(name, nfunp));
}

int CFunctionTable::insertd(const char* name, function_fn_t nfunp) {
	if ('.' != name[0]) Error("Directive string must start with dot", NULL, FATAL);
	// insert the non-dot variant first, then dot variant
	return Insert(name+1, nfunp) && Insert(name, nfunp);
}

int CFunctionTable::zoek(const char* name) {
	auto it = functions.find(name);
	if (functions.end() == it) return 0;
	(*it->second)();
	return 1;
}

TemporaryLabel::TemporaryLabel(aint number, aint address)
	: nummer(number), value(address), isRelocatable(bool(Relocation::type)) {}

CTemporaryLabelTable::CTemporaryLabelTable() {
	labels.reserve(128);
	refresh = 0;
}

void CTemporaryLabelTable::InitPass() {
	refresh = 0;		// reset refresh pointer for next pass
}

bool CTemporaryLabelTable::insertImpl(const aint labelNumber) {
	labels.emplace_back(labelNumber, CurAddress);
	return true;
}

bool CTemporaryLabelTable::refreshImpl(const aint labelNumber) {
	if (labels.size() <= refresh || labels.at(refresh).nummer != labelNumber) return false;
	TemporaryLabel & to_r = labels.at(refresh);
	if (to_r.value != CurAddress) Warning("Temporary label has different address");
	to_r.value = CurAddress;
	++refresh;
	return true;
}

bool CTemporaryLabelTable::InsertRefresh(const aint nnummer) {
	return (1 == pass) ? insertImpl(nnummer) : refreshImpl(nnummer);
}

const TemporaryLabel* CTemporaryLabelTable::seekForward(const aint labelNumber) const {
	if (1 == pass) return nullptr;					// just building tables in first pass, no results yet
	temporary_labels_t::size_type i = refresh;		// refresh already points at first "forward" temporary label
	while (i < labels.size() && labelNumber != labels[i].nummer) ++i;
	return (i < labels.size()) ? &labels[i] : nullptr;
}

const TemporaryLabel* CTemporaryLabelTable::seekBack(const aint labelNumber) const {
	if (1 == pass || refresh <= 0) return nullptr;	// just building tables or no temporary label "backward"
	temporary_labels_t::size_type i = refresh;		// after last "backward" temporary label
	while (i--) if (labelNumber == labels[i].nummer) return &labels[i];
	return nullptr;									// not found
}

CStringsList::CStringsList(const char* stringSource, CStringsList* nnext) {
	string = STRDUP(stringSource);
	next = nnext;
	if (!sourcePosStack.empty()) source = sourcePosStack.back();
}

CStringsList::~CStringsList() {
	if (string) free(string);
	if (next) delete next;
}

bool CStringsList::contains(const CStringsList* strlist, const char* searchString) {
	while (nullptr != strlist) {
		if (!strcmp(searchString, strlist->string)) return true;
		strlist = strlist->next;
	}
	return false;
}

CDefineTableEntry::CDefineTableEntry(const char* nname, const char* nvalue, CStringsList* nnss, CDefineTableEntry* nnext)
		: name(NULL), value(NULL) {
	name = STRDUP(nname);
	value = new char[strlen(nvalue) + 1];
	if (NULL == name || NULL == value) ErrorOOM();
	char* s1 = value;
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

void CDefineTableEntry::Replace(const char* nvalue) {
	if (value) delete[] value;
	value = new char[strlen(nvalue) + 1];
	strcpy(value, nvalue);
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
		Error("Duplicate define (replacing old value)", name, PASS03);
	}
	defs[(*name)&127] = new CDefineTableEntry(name, value, nss, defs[(*name)&127]);
}

static char defineGet__Counter__Buffer[32] = {};
static char defineGet__Line__Buffer[32] = {};

const char* CDefineTable::Get(const char* name) {
	DefArrayList = nullptr;
	if (nullptr == name || 0 == name[0]) return nullptr;
	// the __COUNTER__ and __LINE__ have fully dynamic custom implementation here
	if ('_' == name[1]) {
		if (!strcmp(name, "__COUNTER__")) {
			SPRINTF1(defineGet__Counter__Buffer, 30, "%d", PredefinedCounter);
			++PredefinedCounter;
			return defineGet__Counter__Buffer;
		}
		if (!strcmp(name, "__LINE__")) {
			SPRINTF1(defineGet__Line__Buffer, 30, "%d", sourcePosStack.empty() ? 0 : sourcePosStack.back().line);
			return defineGet__Line__Buffer;
		}
	}
	CDefineTableEntry* p = defs[(*name)&127];
	while (p && strcmp(name, p->name)) p = p->next;
	if (nullptr == p) return nullptr;
	DefArrayList = p->nss;
	return p->value;
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
			p->Replace(value);
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

const char* CMacroDefineTable::getverv(const char* name) const {
	if (nullptr == name) return nullptr;
	if (!used[(*name)&127]) return nullptr;
	const CDefineTableEntry* p = defs;
	while (p && strcmp(name, p->name)) p = p->next;
	return p ? p->value : nullptr;
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

CMacroTableEntry::CMacroTableEntry(char* nnaam, CMacroTableEntry* nnext)
	: naam(nnaam), args(nullptr), body(nullptr), next(nnext) {
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

int CMacroTable::FindDuplicate(const char* naam) {
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

void CMacroTable::Add(const char* nnaam, char*& p) {
	if (FindDuplicate(nnaam)) {
		Error("Duplicate macroname", nnaam);return;
	}
	char* macroname = STRDUP(nnaam);
	if (macroname == NULL) ErrorOOM();
	macs = new CMacroTableEntry(macroname, macs);
	used[(*macroname)&127] = true;
	CStringsList* last = nullptr;
	do {
		char* n = GetID(p);
		if (!n) {
			// either EOL when no previous argument, or valid name is required after comma (2nd+ loop)
			if ((1 == pass) && (last || *p)) Error("Illegal argument name", p, EARLY);
			SkipToEol(p);
			break;
		}
		if ((1 == pass) && CStringsList::contains(macs->args, n)) {
			Error("Duplicate argument name", n, EARLY);
		}
		CStringsList* argname = new CStringsList(n);
		if (!macs->args) {
			macs->args = argname;	// first argument name, make it head of list
		} else {
			last->next = argname;
		}
		last = argname;
	} while (anyComma(p));
	if ((1 == pass) && *p) {
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
			macrolabp = omacrolabp;
			return 1;
		}
		MacroDefineTable.AddMacro(a->string, ml);
		a = a->next;
	}
	SkipBlanks(p);
	if (*p) {
		Error("Too many arguments for macro", naam, SUPPRESS);
		macrolabp = omacrolabp;
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
	sourcePosStack.push_back(TextFilePos());
	while (lijstp) {
		sourcePosStack.back() = lijstp->source;
		STRCPY(line, LINEMAX, lijstp->string);
		substitutedLine = line;		// reset substituted listing
		eolComment = NULL;			// reset end of line comment
		lijstp = lijstp->next;
		ParseLineSafe();
	}
	sourcePosStack.pop_back();
	++CompiledCurrentLine;
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

CStructureEntry2::CStructureEntry2(aint noffset, aint nlen, aint ndef, Relocation::EType ndeltatype, EStructureMembers ntype) :
	next(nullptr), text(nullptr), offset(noffset), len(nlen), def(ndef), defDeltaType(ndeltatype), type(ntype)
{
}

CStructureEntry2::CStructureEntry2(aint noffset, aint nlen, byte* textData) :
	next(nullptr), text(textData), offset(noffset), len(nlen), def(0), defDeltaType(Relocation::OFF), type(SMEMBTEXT)
{
	assert(1 <= len && len <= TEXT_MAX_SIZE && nullptr != text);
}

CStructureEntry2::~CStructureEntry2() {
	if (next) delete next;
	if (text) delete[] text;
}

// Parses source input for types: BYTE, WORD, DWORD, D24
aint CStructureEntry2::ParseValue(char* & p) {
	if (SMEMBBYTE != type && SMEMBWORD != type && SMEMBDWORD != type && SMEMBD24 != type) return def;
	SkipBlanks(p);
	aint val = def;
	bool keepRelocatableFlags = false;	// keep flags from the ParseExpressionNoSyntaxError?
	// check for unexpected {
	if ('{' != *p) {
		if (!(keepRelocatableFlags = ParseExpressionNoSyntaxError(p, val))) {
			val = def;
		}
		switch (type) {
			case SMEMBBYTE:
				check8(val);
				val &= 0xFF;
				break;
			case SMEMBWORD:
				check16(val);
				val &= 0xFFFF;
				break;
			case SMEMBD24:
				check24(val);
				val &= 0xFFFFFF;
				break;
			case SMEMBDWORD:
				break;
			default:
				break;
		}
	}
	if (!Relocation::type) return val;
	if (SMEMBBYTE == type && Relocation::HIGH == Relocation::type) {
		if (!keepRelocatableFlags) {	// override flags, if parse expression was not successful
			Relocation::isResultAffected |= bool(defDeltaType);
			Relocation::deltaType = defDeltaType;
		}
		Relocation::resolveRelocationAffected(0, Relocation::HIGH);
	} else if (SMEMBWORD == type) {
		if (!keepRelocatableFlags) {	// override flags, if parse expression was not successful
			Relocation::isResultAffected |= bool(defDeltaType);
			Relocation::deltaType = defDeltaType;
		}
		Relocation::resolveRelocationAffected(0);
	}
	Relocation::checkAndWarn();
	return val;
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

void CStructure::CopyMember(CStructureEntry2* item, aint newDefault, Relocation::EType newDeltaType) {
	AddMember(new CStructureEntry2(noffset, item->len, newDefault, newDeltaType, item->type));
}

void CStructure::CopyMembers(CStructure* st, char*& lp) {
	aint val;
	int haakjes = 0;
	AddMember(new CStructureEntry2(noffset, 0, 0, Relocation::OFF, SMEMBPARENOPEN));
	SkipBlanks(lp);
	if (*lp == '{') {
		++haakjes; ++lp;
	}
	CStructureEntry2* ip = st->mbf;
	while (ip || 0 < haakjes) {
		Relocation::isResultAffected = false;
		// check if inside curly braces block, and input seems to be empty -> fetch next line
		if (0 < haakjes && !PrepareNonBlankMultiLine(lp)) break;
		if (nullptr == ip) {	// no more struct members expected, looking for closing '}'
			assert(0 < haakjes);
			if (!need(lp, '}')) break;
			--haakjes;
			continue;
		}
		assert(ip);
		switch (ip->type) {
		case SMEMBBLOCK:
			CopyMember(ip, ip->def, Relocation::OFF);
			break;
		case SMEMBBYTE:
		case SMEMBWORD:
		case SMEMBD24:
		case SMEMBDWORD:
			{
				Relocation::EType isRelocatable = Relocation::OFF;
				if (ParseExpressionNoSyntaxError(lp, val)) {
					isRelocatable = (Relocation::isResultAffected && (SMEMBWORD == ip->type || SMEMBBYTE == ip->type))
										? Relocation::deltaType : Relocation::OFF;
				} else {
					val = ip->def;
					isRelocatable = ip->defDeltaType;
				}
				CopyMember(ip, val, isRelocatable);
				if (SMEMBWORD == ip->type) {
					Relocation::resolveRelocationAffected(INT_MAX);	// clear flags + warn when can't be relocated
				} else if (SMEMBBYTE == ip->type) {
					Relocation::resolveRelocationAffected(INT_MAX, Relocation::HIGH);	// clear flags + warn when can't be relocated
				}
				if (ip->next && SMEMBPARENCLOSE != ip->next->type) anyComma(lp);
			}
			break;
		case SMEMBTEXT:
			{
				byte* textData = new byte[ip->len]();	// zero initialized for stable binary results
				if (nullptr == textData) ErrorOOM();
				GetStructText(lp, ip->len, textData, ip->text);
				AddMember(new CStructureEntry2(noffset, ip->len, textData));
				if (ip->next && SMEMBPARENCLOSE != ip->next->type) anyComma(lp);
			}
			break;
		case SMEMBPARENOPEN:
			SkipBlanks(lp);
			if (*lp == '{') {
				++haakjes; ++lp;
			}
			CopyMember(ip, 0, Relocation::OFF);
			break;
		case SMEMBPARENCLOSE:
			SkipBlanks(lp);
			if (haakjes && *lp == '}') {
				--haakjes; ++lp;
				if (ip->next && SMEMBPARENCLOSE != ip->next->type) anyComma(lp);
			}
			CopyMember(ip, 0, Relocation::OFF);
			break;
		default:
			Error("internalerror CStructure::CopyMembers", NULL, FATAL);
		}
		Relocation::checkAndWarn();
		ip = ip->next;
	}
	if (haakjes) {
		Error("closing } missing");
	}
	AddMember(new CStructureEntry2(noffset, 0, 0, Relocation::OFF, SMEMBPARENCLOSE));
}

static void InsertSingleStructLabel(const bool setNameSpace, char *name, const bool isRelocatable, const aint value, const bool isDefine = true) {
	char *op = name;
	std::unique_ptr<char[]> p(ValidateLabel(op, setNameSpace));
	if (!p) {
		Error("Illegal labelname", op, EARLY);
		return;
	}
	if (pass == LASTPASS) {
		aint oval;
		if (!GetLabelValue(op, oval)) {
			Error("Internal error. ParseLabel()", op, FATAL);
		}
		if (value != oval) {
			Error("Label has different value in pass 2", p.get());
		}
		if (IsSldExportActive()) {		// SLD (Source Level Debugging) tracing-data logging
			SLabelTableEntry* symbol = LabelTable.Find(p.get(), true);
			assert(symbol);	// should have been already defined before last pass
			if (symbol) {
				WriteToSldFile(isDefine ? -1 : symbol->page, value, 'L', ExportLabelToSld(name, symbol));
			}
		}
	} else {
		Relocation::isResultAffected = isRelocatable;
		Relocation::deltaType = isRelocatable ? Relocation::REGULAR : Relocation::OFF;
		assert(!isDefine || Relocation::OFF == Relocation::deltaType);	// definition labels are always nonrel
		unsigned traits = LABEL_HAS_RELOC_TRAIT \
						| (isDefine ? LABEL_IS_STRUCT_D : LABEL_IS_STRUCT_E) \
						| (isRelocatable ? LABEL_IS_RELOC : 0);
		if (!LabelTable.Insert(p.get(), value, traits)) Error("Duplicate label", p.get(), EARLY);
	}
}

static void InsertStructSubLabels(const char* mainName, const bool isRelocatable, const CStructureEntry1* members, const aint address = 0, const bool isDefine = true) {
	char ln[LINEMAX+1];
	STRCPY(ln, LINEMAX, mainName);
	char * const lnsubw = ln + strlen(ln);
	while (members) {
		STRCPY(lnsubw, LINEMAX-strlen(ln), members->naam);		// overwrite sub-label part
		InsertSingleStructLabel(false, ln, isRelocatable, members->offset + address, isDefine);
		members = members->next;
	}
}

void CStructure::deflab() {
	const size_t moduleNameLength = strlen(ModuleName);
	char sn[LINEMAX] = { '@', 0 };
	if (moduleNameLength && (0 == strncmp(id, ModuleName, moduleNameLength)) \
		&& ('.' == id[moduleNameLength]) && (id[moduleNameLength+1]))
	{
		// looks like the structure name starts with current module name, use non-global way then
		STRCPY(sn, LINEMAX-1, id + moduleNameLength + 1);
	} else {
		// the structure name does not match current module, use the global "@id" way to define it
		STRCPY(sn+1, LINEMAX-1, id);
	}
	InsertSingleStructLabel(true, sn, false, noffset);
	STRCAT(sn, LINEMAX-1, ".");
	InsertStructSubLabels(sn, false, mnf);
}

void CStructure::emitlab(char* iid, aint address, const bool isRelocatable) {
	const aint misalignment = maxAlignment ? ((-address) & (maxAlignment - 1)) : 0;
	if (misalignment) {
		// emitting in misaligned position (considering the ALIGN used to define this struct)
		char warnTxt[LINEMAX];
		SPRINTF3(warnTxt, LINEMAX,
					"Struct %s did use ALIGN %d in definition, but here it is misaligned by %d bytes",
					naam, maxAlignment, misalignment);
		Warning(warnTxt);
	}
	char sn[LINEMAX] { 0 };
	STRCPY(sn, LINEMAX-1, iid);
	InsertSingleStructLabel(true, sn, isRelocatable, address, false);
	STRCAT(sn, LINEMAX-1, ".");
	InsertStructSubLabels(sn, isRelocatable, mnf, address, false);
}

void CStructure::emitmembs(char*& p) {
	byte* emitTextBuffer = nullptr;
	aint val;
	int haakjes = 0;
	SkipBlanks(p);
	if (*p == '{') {
		++haakjes; ++p;
	}
	CStructureEntry2* ip = mbf;
	Relocation::isResultAffected = false;
	while (ip || 0 < haakjes) {
		// check if inside curly braces block, and input seems to be empty -> fetch next line
		if (0 < haakjes && !PrepareNonBlankMultiLine(p)) break;
		if (nullptr == ip) {	// no more struct members expected, looking for closing '}'
			assert(0 < haakjes);
			if (!need(p, '}')) break;
			--haakjes;
			continue;
		}
		assert(ip);
		switch (ip->type) {
		case SMEMBBLOCK:
			EmitBlock(ip->def != -1 ? ip->def : 0, ip->len, ip->def == -1, 8);
			if (8 < ip->len) ListFile();	// "..." elipsis happened in listing, force listing
			break;
		case SMEMBBYTE:
			EmitByte(ip->ParseValue(p));
			if (ip->next && SMEMBPARENCLOSE != ip->next->type) anyComma(p);
			break;
		case SMEMBWORD:
			// ParseValue will also add relocation data if needed (so the "ParseValue" name is misleading)
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
		case SMEMBTEXT:
			{
				if (nullptr == emitTextBuffer) {
					emitTextBuffer = new byte[CStructureEntry2::TEXT_MAX_SIZE+2];
					if (nullptr == emitTextBuffer) ErrorOOM();
				}
				memset(emitTextBuffer, 0, ip->len);
				GetStructText(p, ip->len, emitTextBuffer, ip->text);
				for (aint ii = 0; ii < ip->len; ++ii) EmitByte(emitTextBuffer[ii]);
			}
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
	if (haakjes) {
		Error("closing } missing");
	}
	if (!SkipBlanks(p)) Error("[STRUCT] Syntax error - too many arguments?");
	Relocation::checkAndWarn();
	if (nullptr != emitTextBuffer) delete[] emitTextBuffer;
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
		Error("[STRUCT] Structure already exist", naam);
		return nullptr;
	}
	strs[(*sp)&127] = new CStructure(naam, sp, 0, gl, strs[(*sp)&127]);
	if (no) {
		strs[(*sp)&127]->AddMember(new CStructureEntry2(0, no, -1, Relocation::OFF, SMEMBBLOCK));
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
	if (l) {
		const Relocation::EType relocatable =
			(INT_MAX == address) ?
				(Relocation::type ? Relocation::REGULAR : Relocation::OFF)
				: Relocation::isResultAffected ? Relocation::deltaType : Relocation::OFF;
		st->emitlab(l, (INT_MAX == address) ? CurAddress : address, relocatable == Relocation::REGULAR);
	}
	if (INT_MAX == address) st->emitmembs(p);	// address was not designed, emit also bytes
	else if (!l) Warning("[STRUCT] designed address without label = no effect");
	return 1;
}

SRepeatStack::SRepeatStack(aint count, CStringsList* condition, CStringsList* firstLine)
	: RepeatCount(count), RepeatCondition(condition), Lines(firstLine), Pointer(firstLine), IsInWork(false), Level(0)
{
	assert(!sourcePosStack.empty());
	sourcePos = sourcePosStack.back();
}

SRepeatStack::~SRepeatStack() {
	if (RepeatCondition) delete RepeatCondition;
	if (Lines) delete Lines;
}

//eof tables.cpp
