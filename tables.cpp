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

char* PreviousIsLabel;

char* AddNewLabel(char* naam) {
	char* np = naam,* lp,* label,* mlp = macrolabp;
	int p = 0,l = 0;
	label = new char[LINEMAX];
	if (label == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	lp = label;
	label[0] = 0;
	if (mlp && *np == '@') {
		++np; mlp = 0;
	}
	switch (*np) {
	case '@':
		p = 1; ++np; break;
	case '.':
		l = 1; ++np; break;
	default:
		break;
	}
	naam = np;
	if (!isalpha((unsigned char) * np) && *np != '_') {
		Error("Invalid labelname", naam); return 0;
	}
	while (*np) {
		if (isalnum((unsigned char) * np) || *np == '_' || *np == '.' || *np == '?' || *np == '!' || *np == '#' || *np == '@') {
			++np;
		} else {
			Error("Invalid labelname", naam); return 0;
		}
	}
	if (strlen(naam) > LABMAX) {
		Error("Label too long", naam, PASS1);
		naam[LABMAX] = 0;
	}
	if (mlp && l) {
		STRCAT(lp, LINEMAX, macrolabp); STRCAT(lp, LINEMAX, ">");
	} else {
		if (!p && ModuleName) {
			//int len1=strlen(lp);
			//int len2=strlen(ModuleName);
			STRCAT(lp, LINEMAX, ModuleName);
			STRCAT(lp, LINEMAX, ".");
		}
		if (l) {
			STRCAT(lp, LINEMAX, vorlabp); STRCAT(lp, LINEMAX, ".");
		} else {
			vorlabp = STRDUP(naam);
			if (vorlabp == NULL) {
				Error("No enough memory!", 0, FATAL);
			}
		}
	}
	STRCAT(lp, LINEMAX, naam);
	return label;
}

int GetLabelValue(char*& p, aint& val) {
	char* mlp = macrolabp,* op = p;
	int g = 0,l = 0,oIsLabelNotFound = IsLabelNotFound,plen;
	unsigned int len;
	char* np;
	if (mlp && *p == '@') {
		++op; mlp = 0;
	}
	if (mlp) {
		switch (*p) {
		case '@':
			g = 1; ++p; break;
		case '.':
			l = 1; ++p; break;
		default:
			break;
		}
		temp[0] = 0;
		if (l) {
			STRCAT(temp, LINEMAX, macrolabp); STRCAT(temp, LINEMAX, ">");
			len = strlen(temp); np = temp + len; plen = 0;
			if (!isalpha((unsigned char) * p) && *p != '_') {
				Error("Invalid labelname", temp); return 0;
			}
			while (isalnum((unsigned char) * p) || *p == '_' || *p == '.' || *p == '?' || *p == '!' || *p == '#' || *p == '@') {
				*np = *p; ++np; ++p;
			}
			*np = 0;
			if (strlen(temp) > LABMAX + len) {
				Error("Label too long", temp + len);
				temp[LABMAX + len] = 0;
			}
			np = temp; g = 1;
			do {
				if (LabelTable.zoek(np, val)) {
					return 1;
				}
				IsLabelNotFound = oIsLabelNotFound;
				while ('o') {
					if (*np == '>') {
						g = 0; break;
					}
					if (*np == '.') {
						++np; break;
					}
					++np;
				}
			} while (g);
		}
	}

	p = op;
	switch (*p) {
	case '@':
		g = 1; ++p; break;
	case '.':
		l = 1; ++p; break;
	default:
		break;
	}
	temp[0] = 0;
	if (!g && ModuleName) {
		STRCAT(temp, LINEMAX, ModuleName); STRCAT(temp, LINEMAX, ".");
	}
	if (l) {
		STRCAT(temp, LINEMAX, vorlabp); STRCAT(temp, LINEMAX, ".");
	}
	len = strlen(temp); np = temp + len;
	if (!isalpha((unsigned char) * p) && *p != '_') {
		Error("Invalid labelname", temp); return 0;
	}
	while (isalnum((unsigned char) * p) || *p == '_' || *p == '.' || *p == '?' || *p == '!' || *p == '#' || *p == '@') {
		*np = *p; ++np; ++p;
	}
	*np = 0;
	if (strlen(temp) > LABMAX + len) {
		Error("Label too long", temp + len);
		temp[LABMAX + len] = 0;
	}
	if (LabelTable.zoek(temp, val)) {
		return 1;
	}
	IsLabelNotFound = oIsLabelNotFound;
	if (!l && !g && LabelTable.zoek(temp + len, val)) {
		return 1;
	}
	if (pass == 2) {
		Error("Label not found", temp); return 1;
	}
	val = 0;
	return 1;
}

int GetLocalLabelValue(char*& op, aint& val) {
	aint nval;
	int nummer;
	char* p = op,naam[LINEMAX],* np,ch;
	SkipBlanks(p);
	np = naam;
	if (!isdigit((unsigned char) * p)) {
		return 0;
	}
	while (*p) {
		if (!isdigit((unsigned char) * p)) {
			break;
		}
		*np = *p; ++p; ++np;
	}
	*np = 0; nummer = atoi(naam);
	ch = *p++;
	if (isalnum((unsigned char) * p)) {
		return 0;
	}
	switch (ch) {
	case 'b':
	case 'B':
		nval = LocalLabelTable.zoekb(nummer); break;
	case 'f':
	case 'F':
		nval = LocalLabelTable.zoekf(nummer); break;
	default:
		return 0;
	}
	if (nval == (aint) - 1) {
		if (pass == 2) {
			Error("Label not found", naam, SUPPRESS); return 1;
		} else {
			nval = 0;
		}
	}
	op = p; val = nval;
	return 1;
}

int IsLabelUsed(char*& p, aint& val) {
	char* mlp = macrolabp,* op = p;
	int g = 0,l = 0,oIsLabelNotFound = IsLabelNotFound,plen;
	unsigned int len;
	char* np;
	if (mlp && *p == '@') {
		++op; mlp = 0;
	}
	if (mlp) {
		switch (*p) {
		case '@':
			g = 1; ++p; break;
		case '.':
			l = 1; ++p; break;
		default:
			break;
		}
		temp[0] = 0;
		if (l) {
			STRCAT(temp, LINEMAX, macrolabp); STRCAT(temp, LINEMAX, ">");
			len = strlen(temp); np = temp + len; plen = 0;
			if (!isalpha((unsigned char) * p) && *p != '_') {
				Error("Invalid labelname", temp); return 0;
			}
			while (isalnum((unsigned char) * p) || *p == '_' || *p == '.' || *p == '?' || *p == '!' || *p == '#' || *p == '@') {
				*np = *p; ++np; ++p;
			}
			*np = 0;
			if (strlen(temp) > LABMAX + len) {
				Error("Label too long", temp + len);
				temp[LABMAX + len] = 0;
			}
			np = temp; g = 1;
			do {
				if (LabelTable.zoek(np, val)) {
					return 1;
				}
				IsLabelNotFound = oIsLabelNotFound;
				while ('o') {
					if (*np == '>') {
						g = 0; break;
					}
					if (*np == '.') {
						++np; break;
					}
					++np;
				}
			} while (g);
		}
	}

	p = op;
	switch (*p) {
	case '@':
		g = 1; ++p; break;
	case '.':
		l = 1; ++p; break;
	default:
		break;
	}
	temp[0] = 0;
	if (!g && ModuleName) {
		STRCAT(temp, LINEMAX, ModuleName); STRCAT(temp, LINEMAX, ".");
	}
	if (l) {
		STRCAT(temp, LINEMAX, vorlabp); STRCAT(temp, LINEMAX, ".");
	}
	len = strlen(temp); np = temp + len;
	if (!isalpha((unsigned char) * p) && *p != '_') {
		Error("Invalid labelname", temp); return 0;
	}
	while (isalnum((unsigned char) * p) || *p == '_' || *p == '.' || *p == '?' || *p == '!' || *p == '#' || *p == '@') {
		*np = *p; ++np; ++p;
	}
	*np = 0;
	if (strlen(temp) > LABMAX + len) {
		Error("Label too long", temp + len);
		temp[LABMAX + len] = 0;
	}
	if (LabelTable.zoek(temp, val)) {
		return 1;
	}
	IsLabelNotFound = oIsLabelNotFound;
	if (!l && !g && LabelTable.zoek(temp + len, val)) {
		return 1;
	}
	val = 0;
	return 0;
}

CLabelTableEntry::CLabelTableEntry() {
	name = NULL; value = used = 0;
}

CLabelTable::CLabelTable() {
	NextLocation = 1;
}

/* modified */
int CLabelTable::Insert(char* nname, aint nvalue, bool undefined = false, bool IsDEFL = false) {
	if (NextLocation >= LABTABSIZE * 2 / 3) {
		Error("Label table full", 0, FATAL);
	}
	int tr, htr;
	tr = Hash(nname);
	while (htr = HashTable[tr]) {
		if (!strcmp((LabelTable[htr].name), nname)) {
			/*if (LabelTable[htr].IsDEFL) {
							cout << "A" << LabelTable[htr].value << endl;
						}*/
			//old: if (LabelTable[htr].page!=-1) return 0;
			if (!LabelTable[htr].IsDEFL && LabelTable[htr].page != -1) {
				return 0;
			} else {
				//if label already added as used
				LabelTable[htr].value = nvalue;
				LabelTable[htr].page = MemoryCPage;
				LabelTable[htr].IsDEFL = IsDEFL; /* added */
				return 1;
			}
		} else if (++tr >= LABTABSIZE) {
			tr = 0;
		}
	}
	HashTable[tr] = NextLocation;
	LabelTable[NextLocation].name = STRDUP(nname);
	if (LabelTable[NextLocation].name == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	LabelTable[NextLocation].IsDEFL = IsDEFL; /* added */
	LabelTable[NextLocation].value = nvalue;
	LabelTable[NextLocation].used = -1;
	if (!undefined) {
		LabelTable[NextLocation].page = MemoryCPage;
	} else {
		LabelTable[NextLocation].page = -1;
	} /* added */
	++NextLocation;
	return 1;
}

/* added */
int CLabelTable::Update(char* nname, aint nvalue) {
	int tr, htr, otr;
	otr = tr = Hash(nname);
	while (htr = HashTable[tr]) {
		if (!strcmp((LabelTable[htr].name), nname)) {
			LabelTable[htr].value = nvalue;
			return 1;
		}
		if (++tr >= LABTABSIZE) {
			tr = 0;
		}
		if (tr == otr) {
			break;
		}
	}
	return 1;
}

int CLabelTable::zoek(char* nname, aint& nvalue) {
	int tr, htr, otr;
	otr = tr = Hash(nname);
	while (htr = HashTable[tr]) {
		if (!strcmp((LabelTable[htr].name), nname)) {
			if (LabelTable[htr].page == -1) {
				IsLabelNotFound = 2; nvalue = 0; return 0;
			} else {
				nvalue = LabelTable[htr].value;
				if (pass == 2) {
					++LabelTable[htr].used;
				} return 1;
			}
		}
		if (++tr >= LABTABSIZE) {
			tr = 0;
		}
		if (tr == otr) {
			break;
		}
	}
	this->Insert(nname, 0, true);
	IsLabelNotFound = 1;
	nvalue = 0;
	return 0;
}

int CLabelTable::Hash(char* s) {
	char* ss = s;
	unsigned int h = 0,g;
	for (; *ss != '\0'; ss++) {
		h = (h << 4) + *ss;
		if (g = h & 0xf0000000) {
			h ^= g >> 24; h ^= g;
		}
	}
	return h % LABTABSIZE;
}

/* added */
char hd2[] = {
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
};

/* added */
void PrintHEX__(char*& p, aint h) {
	aint hh = h&0xffffffff;
	if (hh >> 28 != 0) {
		*(p++) = hd2[hh >> 28];
	} hh &= 0xfffffff;
	if (hh >> 24 != 0) {
		*(p++) = hd2[hh >> 24];
	} hh &= 0xffffff;
	if (hh >> 20 != 0) {
		*(p++) = hd2[hh >> 20];
	} hh &= 0xfffff;
	if (hh >> 16 != 0) {
		*(p++) = hd2[hh >> 16];
	} hh &= 0xffff;
	*(p++) = hd2[hh >> 12]; hh &= 0xfff;
	*(p++) = hd2[hh >> 8];  hh &= 0xff;
	*(p++) = hd2[hh >> 4];  hh &= 0xf;
	*(p++) = hd2[hh];
}

void CLabelTable::Dump() {
	char line[LINEMAX], * ep;
	if (!IsListingFileOpened) {
		IsListingFileOpened = 1; OpenList();
	}
	/*fputs("\nvalue      label\n",FP_ListingFile);*/
	fputs("\nvalue   label\n", FP_ListingFile);
	/*fputs("-------- - -----------------------------------------------------------\n",FP_ListingFile);*/
	fputs("----- - -----------------------------------------------------------\n", FP_ListingFile);
	for (int i = 1; i < NextLocation; ++i) {
		if (LabelTable[i].page != -1) {
			ep = line; *ep = 0;
			/*PrintHEX32(ep,LabelTable[i].value); *(ep++)=' ';*/
			PrintHEX__(ep, LabelTable[i].value); *(ep++) = 'h'; *(ep++) = ' ';
			*(ep++) = LabelTable[i].used ? ' ' : 'X'; *(ep++) = ' ';
			STRCPY(ep, LINEMAX, LabelTable[i].name);
			STRCAT(line, LINEMAX, "\n");
			fputs(line, FP_ListingFile);
		}
	}
}

/* added */
void CLabelTable::DumpForUnreal() {
	char ln[LINEMAX], * ep;
	int page;
	if (!FP_UnrealList && !FOPEN_ISOK(FP_UnrealList, Options::UnrealLabelListFName, "w")) {
		Error("Error opening file", Options::UnrealLabelListFName, FATAL);
	}
	for (int i = 1; i < NextLocation; ++i) {
		if (LabelTable[i].page != -1) {
			page = LabelTable[i].page;
			int lvalue = LabelTable[i].value;
			if (lvalue >= 0 && lvalue < 0x4000) {
				page = -1;
			} else if (lvalue >= 0x4000 && lvalue < 0x8000) {
				page = 5;
				lvalue -= 0x4000;
			} else if (lvalue >= 0x8000 && lvalue < 0xc000) {
				page = 2;
				lvalue -= 0x8000;
			} else {
				lvalue -= 0xc000;
			}
			ep = ln;
			if (page != -1) {
				*(ep++) = '0';
				*(ep++) = page + '0';
			} else if (page > 9) {
				*(ep++) = ((int)fmod((float)page, 7)) + '0';
				*(ep++) = ((int)floor((float)(page / 10))) + '0';
			} else {
				continue;
			}
			//*(ep++)='R';
			*(ep++) = ':';
			PrintHEX__(ep, lvalue);
			*(ep++) = ' ';
			STRCPY(ep, LINEMAX-(ep-ln), LabelTable[i].name);
			STRCAT(ln, LINEMAX, "\n");
			fputs(ln, FP_UnrealList);
		}
	}
	fclose(FP_UnrealList);
}

/* from SjASM 0.39g */
void CLabelTable::DumpSymbols() {
	FILE* symfp;
	char lnrs[16], * l;
	if (!FOPEN_ISOK(symfp, Options::SymbolListFName, "w")) {
		Error("Error opening file", Options::SymbolListFName, FATAL);
	}
	for (int i = 1; i < NextLocation; ++i) {
		if (isalpha(LabelTable[i].name[0])) {
			STRCPY(ErrorLine, LINEMAX, LabelTable[i].name);
			STRCAT(ErrorLine, LINEMAX2, ": equ ");
			l = lnrs;
			PrintHEX32(l, LabelTable[i].value);
			*l = 0; 
			STRCAT(ErrorLine, LINEMAX2, lnrs);
			STRCAT(ErrorLine, LINEMAX2, "h\n");
			fputs(ErrorLine, symfp);
		}
	}
	fclose(symfp);
}

CFunctionTable::CFunctionTable() {
	NextLocation = 1;
}

int CFunctionTable::Insert(char* nname, void(*nfunp) (void)) {
	char* p;
	if (NextLocation >= FUNTABSIZE * 2 / 3) {
		cout << "Functions Table is full" << endl; ExitASM(1);
	}
	int tr, htr;
	tr = Hash(nname);
	while (htr = HashTable[tr]) {
		if (!strcmp((funtab[htr].name), nname)) {
			return 0;
		} else if (++tr >= FUNTABSIZE) {
			tr = 0;
		}
	}
	HashTable[tr] = NextLocation;
	funtab[NextLocation].name = STRDUP(nname);
	if (funtab[NextLocation].name == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	funtab[NextLocation].funp = nfunp;
	++NextLocation;

	STRCPY(p = temp, LINEMAX, nname);
	while (*p = (char) toupper(*p)) { ++p; }

	if (NextLocation >= FUNTABSIZE * 2 / 3) {
		cout << "Functions Table is full" << endl; ExitASM(1);
	}
	tr = Hash(temp);
	while (htr = HashTable[tr]) {
		if (!strcmp((funtab[htr].name), temp)) {
			return 0;
		} else if (++tr >= FUNTABSIZE) {
			tr = 0;
		}
	}
	HashTable[tr] = NextLocation;
	funtab[NextLocation].name = STRDUP(temp);
	if (funtab[NextLocation].name == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	funtab[NextLocation].funp = nfunp;
	++NextLocation;

	return 1;
}

int CFunctionTable::insertd(char* nname, void(*nfunp) (void)) {
	size_t len = strlen(nname) + 2;
	char* buf = new char[len];
	//if (buf == NULL) {
	//	Error("No enough memory!", 0, FATAL);
	//}
	STRCPY(buf, len, nname);
	if (!Insert(buf, nfunp)) {
		return 0;
	}
	STRCPY(buf + 1, len, nname);
	buf[0] = '.';
	return Insert(buf, nfunp);
}

int CFunctionTable::zoek(char* nname, bool bol) {
	int tr, htr, otr;
	otr = tr = Hash(nname);
	while (htr = HashTable[tr]) {
		if (!strcmp((funtab[htr].name), nname)) {
			if (bol && ((sizeof(nname) == 3 && (!strcmp("END", nname) || !strcmp("end", nname))) || (sizeof(nname) == 4 && (!strcmp(".END", nname) || !strcmp(".end", nname))))) {
				//do nothing (now you can use END as labels)
			} else {
				(*funtab[htr].funp)(); return 1;
			}
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

int CFunctionTable::Find(char* nname) {
	int tr, htr, otr;
	otr = tr = Hash(nname);
	while (htr = HashTable[tr]) {
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

int CFunctionTable::Hash(char* s) {
	char* ss = s;
	unsigned int h = 0;
	for (; *ss != '\0'; ss++) {
		h = (h << 3) + *ss;
	}
	return h % FUNTABSIZE;
}

/* modified */
CLocalLabelTableEntry::CLocalLabelTableEntry(aint nnummer, aint nvalue, CLocalLabelTableEntry* n) {
	regel = CurrentLine; nummer = nnummer; value = nvalue;
	//regel=CurrentLocalLine; nummer=nnummer; value=nvalue;
	prev = n; next = NULL; if (n) {
						   	n->next = this;
						   }
}

CLocalLabelTable::CLocalLabelTable() {
	first = last = NULL;
}

void CLocalLabelTable::Insert(aint nnummer, aint nvalue) {
	last = new CLocalLabelTableEntry(nnummer, nvalue, last);
	if (!first) {
		first = last;
	}
}

/* modified */
aint CLocalLabelTable::zoekf(aint nnum) {
	CLocalLabelTableEntry* l = first;
	while (l) {
		if (l->regel <= CurrentLine) {
			l = l->next;
		} else {
			break;
		}
	}
	//while (l) if (l->regel<=CurrentLocalLine) l=l->next; else break;
	while (l) {
		if (l->nummer == nnum) {
			return l->value;
		} else {
			l = l->next;
		}
	}
	return (aint) - 1;
}

/* modified */
aint CLocalLabelTable::zoekb(aint nnum) {
	CLocalLabelTableEntry* l = last;
	while (l) {
		if (l->regel > CurrentLine) {
			l = l->prev;
		} else {
			break;
		}
	}
	//while (l) if (l->regel>CurrentLocalLine) l=l->prev; else break;
	while (l) {
		if (l->nummer == nnum) {
			return l->value;
		} else {
			l = l->prev;
		}
	}
	return (aint) - 1;
}

CDefineTableEntry::CDefineTableEntry(char* nnaam, char* nvervanger, CStringList* nnss/*added*/, CDefineTableEntry* nnext) {
	char* s1, * s2;
	naam = STRDUP(nnaam);
	if (naam == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	vervanger = new char[strlen(nvervanger) + 1];
	if (vervanger == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	s1 = vervanger; s2 = nvervanger; SkipBlanks(s2);
	while (*s2 && *s2 != '\n' && *s2 != '\r') {
		*s1 = *s2; ++s1; ++s2;
	} *s1 = 0;
	next = nnext;
	nss = nnss;
}

void CDefineTable::Init() {
	for (int i = 0; i < 128; defs[i++] = 0) {
		;
	}
}

void CDefineTable::Add(char* naam, char* vervanger, CStringList* nss/*added*/) {
	if (FindDuplicate(naam)) {
		Error("Duplicate define", naam);
	}
	defs[*naam] = new CDefineTableEntry(naam, vervanger, nss, defs[*naam]);
}

char* CDefineTable::getverv(char* naam) {
	CDefineTableEntry* p = defs[*naam];
	defarraylstp = 0;
	while (p) {
		if (!strcmp(naam, p->naam)) {
			if (p->nss) {
				defarraylstp = p->nss;
			}
			return p->vervanger;
		}
		p = p->next;
	}
	return NULL;
}

int CDefineTable::FindDuplicate(char* naam) {
	CDefineTableEntry* p = defs[*naam];
	while (p) {
		if (!strcmp(naam, p->naam)) {
			return 1;
		}
		p = p->next;
	}
	return 0;
}

void CMacroDefineTable::Init() {
	defs = NULL;
	for (int i = 0; i < 128; used[i++] = 0) {
		;
	}
}

void CMacroDefineTable::AddMacro(char* naam, char* vervanger) {
	defs = new CDefineTableEntry(naam, vervanger, 0, defs);
	used[*naam] = 1;
}

CDefineTableEntry* CMacroDefineTable::getdefs() {
	return defs;
}

void CMacroDefineTable::setdefs(CDefineTableEntry* ndefs) {
	defs = ndefs;
}

char* CMacroDefineTable::getverv(char* naam) {
	CDefineTableEntry* p = defs;
	if (!used[*naam]) {
		return NULL;
	}
	while (p) {
		if (!strcmp(naam, p->naam)) {
			return p->vervanger;
		}
		p = p->next;
	}
	return NULL;
}

int CMacroDefineTable::FindDuplicate(char* naam) {
	CDefineTableEntry* p = defs;
	if (!used[*naam]) {
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

CStringList::CStringList(char* nstring, CStringList* nnext) {
	string = STRDUP(nstring);
	//if (string == NULL) {
	//	Error("No enough memory!", 0, FATAL);
	//}
	next = nnext;
}

CMacroTableEntry::CMacroTableEntry(char* nnaam, CMacroTableEntry* nnext) {
	naam = nnaam; next = nnext; args = body = NULL;
}

void CMacroTable::Init() {
	macs = NULL;
	for (int i = 0; i < 128; used[i++] = 0) {
		;
	}
}

int CMacroTable::FindDuplicate(char* naam) {
	CMacroTableEntry* p = macs;
	if (!used[*naam]) {
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

/* modified */
void CMacroTable::Add(char* nnaam, char*& p) {
	char* n;
	CStringList* s,* l = NULL,* f = NULL;
	/*if (FindDuplicate(nnaam)) Error("Duplicate macroname",0,PASS1);*/
	if (FindDuplicate(nnaam)) {
		Error("Duplicate macroname", 0, PASS1);return;
	}
	char* macroname;
	macroname = STRDUP(nnaam); /* added */
	if (macroname == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	macs = new CMacroTableEntry(macroname/*nnaam*/, macs);
	used[*macroname/*nnaam*/] = 1;
	SkipBlanks(p);
	while (*p) {
		if (!(n = GetID(p))) {
			Error("Illegal macro argument", p, PASS1); break;
		}
		s = new CStringList(n, NULL); if (!f) {
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
	if (*p/* && *p!=':'*/) {
		Error("Unexpected", p, PASS1);
	}
	ListFile();
	if (!ReadFileToCStringList(macs->body, "endm")) {
		Error("Unexpected end of macro", 0, PASS1);
	}
}

int CMacroTable::Emit(char* naam, char*& p) {
	CStringList* a, * olijstp;
	char* n, labnr[LINEMAX], ml[LINEMAX], * omacrolabp;
	CMacroTableEntry* m = macs;
	CDefineTableEntry* odefs;
	int olistmacro, olijst;
	if (!used[*naam]) {
		return 0;
	}
	while (m) {
		if (!strcmp(naam, m->naam)) {
			break;
		}
		m = m->next;
	}
	if (!m) {
		return 0;
	}
	omacrolabp = macrolabp;
	SPRINTF1(labnr, LINEMAX, "%d", macronummer++);
	macrolabp = labnr;
	if (omacrolabp) {
		STRCAT(macrolabp, LINEMAX, "."); STRCAT(macrolabp, LINEMAX, omacrolabp);
	} else {
		MacroDefineTable.Init();
	}
	odefs = MacroDefineTable.getdefs();
	//*lp=0; /* added */
	a = m->args;
	/* old:
	while (a) {
	  n=ml;
	  SkipBlanks(p);
	  if (!*p) { Error("Not enough arguments",0); return 1; }
	  if (*p=='<') {
		++p;
		while (*p!='>') {
		  if (!*p) { Error("Not enough arguments",0); return 1; }
		  if (*p=='!') {
			++p; if (!*p) { Error("Not enough arguments",0); return 1; }
		  }
		  *n=*p; ++n; ++p;
		}
		++p;
	  } else while (*p!=',' && *p) { *n=*p; ++n; ++p; }
	  *n=0; MacroDefineTable.AddMacro(a->string,ml);
	  SkipBlanks(p); a=a->next; if (a && *p!=',') { Error("Not enough arguments",0); return 1; }
	  if (*p==',') ++p;
	}
	SkipBlanks(p); if (*p) Error("Too many arguments",0);
	*/
	/* (begin new) */
	while (a) {
		n = ml;
		SkipBlanks(p);
		if (!*p) {
			Error("Not enough arguments for macro", naam); macrolabp = 0; return 1;
		}
		if (*p == '<') {
			++p;
			while (*p != '>') {
				if (!*p) {
					Error("Not enough arguments for macro", naam); macrolabp = 0; return 1;
				}
				if (*p == '!') {
					++p; if (!*p) {
						 	Error("Not enough arguments for macro", naam); macrolabp = 0; return 1;
						 }
				}
				*n = *p; ++n; ++p;
			}
			++p;
		} else {
			while (*p && *p != ',') {
				*n = *p; ++n; ++p;
			}
		}
		*n = 0;
		MacroDefineTable.AddMacro(a->string, ml);
		SkipBlanks(p); a = a->next; if (a && *p != ',') {
										Error("Not enough arguments for macro", naam); macrolabp = 0; return 1;
									}
		if (*p == ',') {
			++p;
		}
	}
	SkipBlanks(p);
	lp = p;
	if (*p) {
		Error("Too many arguments for macro", naam);
	}
	/* (end new) */
	ListFile();
	olistmacro = listmacro; listmacro = 1;
	olijstp = lijstp; olijst = lijst;
	lijstp = m->body; lijst = 1;
	STRCPY(ml, LINEMAX, line);
	while (lijstp) {
		STRCPY(line, LINEMAX, lijstp->string);
		lijstp = lijstp->next;
		/* ParseLine(); */
		ParseLineSafe();
	}
	STRCPY(line, LINEMAX, ml);
	lijst = olijst;
	lijstp = olijstp;
	MacroDefineTable.setdefs(odefs);
	macrolabp = omacrolabp;
	/*listmacro=olistmacro; donotlist=1; return 0;*/
	listmacro = olistmacro; donotlist = 1; return 2;
}

CStructureEntry1::CStructureEntry1(char* nnaam, aint noffset) {
	next = 0;
	naam = STRDUP(nnaam);
	if (naam == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	offset = noffset;
}

CStructureEntry2::CStructureEntry2(aint noffset, aint nlen, aint ndef, EStructureMembers nsoort) {
	next = 0; offset = noffset; len = nlen; def = ndef; soort = nsoort;
}

CStructure::CStructure(char* nnaam, char* nid, int idx, int no, int ngl, CStructure* p) {
	mnf = mnl = 0; mbf = mbl = 0;
	naam = STRDUP(nnaam); 
	if (naam == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	id = STRDUP(nid);
	if (id == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	binding = idx; next = p; noffset = no; global = ngl;
}

void CStructure::AddLabel(char* nnaam) {
	CStructureEntry1* n = new CStructureEntry1(nnaam, noffset);
	if (!mnf) {
		mnf = n;
	} if (mnl) {
	  	mnl->next = n;
	  } mnl = n;
}

void CStructure::AddMember(CStructureEntry2* n) {
	if (!mbf) {
		mbf = n;
	} if (mbl) {
	  	mbl->next = n;
	  } mbl = n;
	noffset += n->len;
}

void CStructure::CopyLabel(char* nnaam, aint offset) {
	CStructureEntry1* n = new CStructureEntry1(nnaam, noffset + offset);
	if (!mnf) {
		mnf = n;
	} if (mnl) {
	  	mnl->next = n;
	  } mnl = n;
}

void CStructure::CopyLabels(CStructure* st) {
	char str[LINEMAX], str2[LINEMAX];
	CStructureEntry1* np = st->mnf;
	if (!np || !PreviousIsLabel) {
		return;
	}
	str[0] = 0;
	STRCAT(str, LINEMAX, PreviousIsLabel);
	STRCAT(str, LINEMAX, ".");
	while (np) {
		STRCPY(str2, LINEMAX, str);
		STRCAT(str2, LINEMAX, np->naam);
		CopyLabel(str2, np->offset);
		np = np->next;
	}
}

void CStructure::CopyMember(CStructureEntry2* ni, aint ndef) {
	CStructureEntry2* n = new CStructureEntry2(noffset, ni->len, ndef, ni->soort);
	if (!mbf) {
		mbf = n;
	} if (mbl) {
	  	mbl->next = n;
	  } mbl = n;
	noffset += n->len;
}

void CStructure::CopyMembers(CStructure* st, char*& lp) {
	CStructureEntry2* ip;
	aint val;
	int haakjes = 0;
	ip = new CStructureEntry2(noffset, 0, 0, SMEMBPARENOPEN); AddMember(ip);
	SkipBlanks(lp); if (*lp == '{') {
						++haakjes; ++lp;
					}
	ip = st->mbf;
	while (ip) {
		switch (ip->soort) {
		case SMEMBBLOCK:
			CopyMember(ip, ip->def); break;
		case SMEMBBYTE:
		case SMEMBWORD:
		case SMEMBD24:
		case SMEMBDWORD:
			synerr = 0; if (!ParseExpression(lp, val)) {
							val = ip->def;
						} synerr = 1; CopyMember(ip, val); comma(lp); break;
		case SMEMBPARENOPEN:
			SkipBlanks(lp); if (*lp == '{') {
								++haakjes; ++lp;
							} break;
		case SMEMBPARENCLOSE:
			SkipBlanks(lp); if (haakjes && *lp == '}') {
								--haakjes; ++lp; comma(lp);
							} break;
		default:
			Error("internalerror CStructure::CopyMembers", 0, FATAL);
		}
		ip = ip->next;
	}
	while (haakjes--) {
		if (!need(lp, '}')) {
			Error("closing } missing", 0);
		}
	}
	ip = new CStructureEntry2(noffset, 0, 0, SMEMBPARENCLOSE); AddMember(ip);
}

void CStructure::deflab() {
	char ln[LINEMAX], sn[LINEMAX], * p, * op;
	aint oval;
	CStructureEntry1* np = mnf;
	STRCPY(sn, LINEMAX, "@");
	STRCAT(sn, LINEMAX, id);
	op = p = sn;
	p = AddNewLabel(p);
	if (pass == 2) {
		if (!GetLabelValue(op, oval)) {
			Error("Internal error. ParseLabel()", 0, FATAL);
		}
		if (noffset != oval) {
			Error("Label has different value in pass 2", temp);
		}
	} else {
		if (!LabelTable.Insert(p, noffset)) {
			Error("Duplicate label", tp, PASS1);
		}
	}
	STRCAT(sn, LINEMAX, ".");
	while (np) {
		STRCPY(ln, LINEMAX, sn);
		STRCAT(ln, LINEMAX, np->naam);
		op = ln;
		if (!(p = AddNewLabel(ln))) {
			Error("Illegal labelname", ln, PASS1);
		}
		if (pass == 2) {
			if (!GetLabelValue(op, oval)) {
				Error("Internal error. ParseLabel()", 0, FATAL);
			}
			if (np->offset != oval) {
				Error("Label has different value in pass 2", temp);
			}
		} else {
			if (!LabelTable.Insert(p, np->offset)) {
				Error("Duplicate label", tp, PASS1);
			}
		}
		np = np->next;
	}
}

void CStructure::emitlab(char* iid) {
	char ln[LINEMAX], sn[LINEMAX], * p, * op;
	aint oval;
	CStructureEntry1* np = mnf;
	STRCPY(sn, LINEMAX, iid);
	op = p = sn;
	p = AddNewLabel(p);
	if (pass == 2) {
		if (!GetLabelValue(op, oval)) {
			Error("Internal error. ParseLabel()", 0, FATAL);
		}
		if (CurAddress != oval) {
			Error("Label has different value in pass 2", temp);
		}
	} else {
		if (!LabelTable.Insert(p, CurAddress)) {
			Error("Duplicate label", tp, PASS1);
		}
	}
	STRCAT(sn, LINEMAX, ".");
	while (np) {
		STRCPY(ln, LINEMAX, sn);
		STRCAT(ln, LINEMAX, np->naam);
		op = ln;
		if (!(p = AddNewLabel(ln))) {
			Error("Illegal labelname", ln, PASS1);
		}
		if (pass == 2) {
			if (!GetLabelValue(op, oval)) {
				Error("Internal error. ParseLabel()", 0, FATAL);
			}
			if (np->offset + CurAddress != oval) {
				Error("Label has different value in pass 2", temp);
			}
		} else {
			if (!LabelTable.Insert(p, np->offset + CurAddress)) {
				Error("Duplicate label", tp, PASS1);
			}
		}
		np = np->next;
	}
}

void CStructure::emitmembs(char*& p) {
	int* e,et = 0,t;
	e = new int[noffset + 1];
	CStructureEntry2* ip = mbf;
	aint val;
	int haakjes = 0;
	SkipBlanks(p); if (*p && *p == '{') {
				   	++haakjes; ++p;
				   }
	while (ip) {
		switch (ip->soort) {
		case SMEMBBLOCK:
			t = ip->len; while (t--) {
						 	e[et++] = ip->def;
						 } break;
		case SMEMBBYTE:
			synerr = 0; if (!ParseExpression(p, val)) {
							val = ip->def;
						} synerr = 1;
			e[et++] = val % 256;
			check8(val); comma(p);
			break;
		case SMEMBWORD:
			synerr = 0; if (!ParseExpression(p, val)) {
							val = ip->def;
						} synerr = 1;
			e[et++] = val % 256; e[et++] = (val >> 8) % 256;
			check16(val); comma(p);
			break;
		case SMEMBD24:
			synerr = 0; if (!ParseExpression(p, val)) {
							val = ip->def;
						} synerr = 1;
			e[et++] = val % 256; e[et++] = (val >> 8) % 256; e[et++] = (val >> 16) % 256;
			check24(val); comma(p);
			break;
		case SMEMBDWORD:
			synerr = 0; if (!ParseExpression(p, val)) {
							val = ip->def;
						} synerr = 1;
			e[et++] = val % 256; e[et++] = (val >> 8) % 256; e[et++] = (val >> 16) % 256; e[et++] = (val >> 24) % 256;
			comma(p);
			break;
		case SMEMBPARENOPEN:
			SkipBlanks(p); if (*p == '{') {
						   	++haakjes; ++p;
						   } break;
		case SMEMBPARENCLOSE:
			SkipBlanks(p); if (haakjes && *p == '}') {
						   	--haakjes; ++p; comma(p);
						   } break;
		default:
			Error("internalerror CStructure::emitmembs", 0, FATAL);
		}
		ip = ip->next;
	}
	while (haakjes--) {
		if (!need(p, '}')) {
			Error("closing } missing", 0);
		}
	}
	SkipBlanks(p); if (*p) {
				   	Error("[STRUCT] Syntax error - too many arguments?", 0);
				   } /* this line from SjASM 0.39g */
	e[et] = -1; EmitBytes(e);
	delete e;
}

void CStructureTable::Init() {
	for (int i = 0; i < 128; strs[i++] = 0) {
		;
	}
}

CStructure* CStructureTable::Add(char* naam, int no, int idx, int gl) {
	char sn[LINEMAX], * sp;
	sn[0] = 0;
	if (!gl && ModuleName) {
		STRCPY(sn, LINEMAX, ModuleName);
		STRCAT(sn, LINEMAX, ".");
	}
	//sp = STRCAT(sn, LINEMAX, naam); //mmmm
	STRCAT(sn, LINEMAX, naam);
	sp = sn;
	if (FindDuplicate(sp)) {
		Error("Duplicate structurename", naam, PASS1);
	}
	strs[*sp] = new CStructure(naam, sp, idx, 0, gl, strs[*sp]);
	if (no) {
		strs[*sp]->AddMember(new CStructureEntry2(0, no, 0, SMEMBBLOCK));
	}
	return strs[*sp];
}

CStructure* CStructureTable::zoek(char* naam, int gl) {
	char sn[LINEMAX], * sp;
	sn[0] = 0;
	if (!gl && ModuleName) {
		STRCPY(sn, LINEMAX, ModuleName);
		STRCAT(sn, LINEMAX, ".");
	}
	//sp = STRCAT(sn, LINEMAX, naam); //mmm
	STRCAT(sn, LINEMAX, naam);
	sp = sn;
	CStructure* p = strs[*sp];
	while (p) {
		if (!strcmp(sp, p->id)) {
			return p;
		} p = p->next;
	}
	if (!gl && ModuleName) {
		sp += 1 + strlen(ModuleName); p = strs[*sp];
		while (p) {
			if (!strcmp(sp, p->id)) {
				return p;
			} p = p->next;
		}
	}
	return 0;
}

int CStructureTable::FindDuplicate(char* naam) {
	CStructure* p = strs[*naam];
	while (p) {
		if (!strcmp(naam, p->naam)) {
			return 1;
		} p = p->next;
	}
	return 0;
}

int CStructureTable::Emit(char* naam, char* l, char*& p, int gl) {
	CStructure* st = zoek(naam, gl);
	if (!st) {
		return 0;
	}
	if (l) {
		st->emitlab(l);
	}
	st->emitmembs(p);
	return 1;
}

//eof tables.cpp
