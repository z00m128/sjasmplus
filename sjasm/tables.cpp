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

char* ValidateLabel(char* naam, int set_namespace) {
	char* np = naam,* lp,* label,* mlp = macrolabp;
	int p = 0,l = 0;
	label = new char[LINEMAX];
	if (label == NULL) {
		ErrorInt("No enough memory!", LINEMAX, FATAL);
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
		Error("Invalid labelname", naam);
		return 0;
	}
	while (*np) {
		if (isalnum((unsigned char) * np) || *np == '_' || *np == '.' || *np == '?' || *np == '!' || *np == '#' || *np == '@') {
			++np;
		} else {
			Error("Invalid labelname", naam);
			return 0;
		}
	}
	if (strlen(naam) > LABMAX) {
		Error("Label too long", naam);
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
		} else if (set_namespace) {
			free(vorlabp);
			vorlabp = STRDUP(naam);
			if (vorlabp == NULL) {
				Error("No enough memory!", NULL, FATAL);
			}
		}
	}
	STRCAT(lp, LINEMAX, naam);
	return label;
}

int GetLabelValue(char*& p, aint& val) {
	char* mlp = macrolabp, *op = p;
	int g = 0, l = 0, oIsLabelNotFound = IsLabelNotFound;//, plen;
	unsigned int len;
	char* np;
	if (mlp && *p == '@') {
		++op;
		mlp = 0;
	}
	if (mlp) {
		switch (*p) {
		case '@':
			g = 1;
			++p;
			break;
		case '.':
			l = 1;
			++p;
			break;
		default:
			break;
		}
		temp[0] = 0;
		if (l) {
			STRCAT(temp, LINEMAX, macrolabp);
			STRCAT(temp, LINEMAX, ">");
			len = strlen(temp);
			np = temp + len;
//			plen = 0;
			if (!isalpha((unsigned char) * p) && *p != '_') {
				Error("Invalid labelname", temp);
				return 0;
			}
			while (isalnum((unsigned char) * p) || *p == '_' || *p == '.' || *p == '?' || *p == '!' || *p == '#' || *p == '@') {
				*np = *p;
				++np;
				++p;
			}
			*np = 0;
			if (strlen(temp) > LABMAX + len) {
				Error("Label too long", temp + len);
				temp[LABMAX + len] = 0;
			}
			np = temp;
			g = 1;
			do {
				if (LabelTable.GetValue(np, val)) {
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
		g = 1;
		++p;
		break;
	case '.':
		l = 1;
		++p;
		break;
	default:
		break;
	}
	temp[0] = 0;
	if (!g && ModuleName) {
		STRCAT(temp, LINEMAX, ModuleName);
		STRCAT(temp, LINEMAX, ".");
	}
	if (l) {
		STRCAT(temp, LINEMAX, vorlabp);
		STRCAT(temp, LINEMAX, ".");
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
	if (LabelTable.GetValue(temp, val)) {
		return 1;
	}
	IsLabelNotFound = oIsLabelNotFound;
	if (!l && !g && LabelTable.GetValue(temp + len, val)) {
		return 1;
	}
	if (pass == LASTPASS) {
		Error("Label not found", temp); return 1;
	}
	val = 0;
	return 1;
}

int GetLocalLabelValue(char*& op, aint& val) {
	aint nval = 0;
	int nummer = 0;
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
		if (pass == LASTPASS) {
			Error("Local label not found", naam, SUPPRESS);
			return 1;
		} else {
			nval = 0;
		}
	}
	op = p; val = nval;
	return 1;
}

CLabelTableEntry::CLabelTableEntry() {
	name = NULL; value = used = 0; updatePass = pass;
}

CLabelTable::CLabelTable() {
	NextLocation = 1;
}

int CLabelTable::Insert(const char* nname, aint nvalue, bool undefined = false, bool IsDEFL = false) {
	if (NextLocation >= LABTABSIZE * 2 / 3) {
		Error("Label table full", NULL, FATAL);
	}

	// Find label in label table
	int tr, htr;
	tr = Hash(nname);
	while ((htr = HashTable[tr])) {
		if (!strcmp((LabelTable[htr].name), nname)) {
			if (!LabelTable[htr].IsDEFL && LabelTable[htr].page != -1 && LabelTable[htr].updatePass == pass) {
				return 0;
			} else {
				//if label already added (as used, or in previous pass), just refresh values
				LabelTable[htr].value = nvalue;
				LabelTable[htr].page = MemoryCPage;
				LabelTable[htr].IsDEFL = IsDEFL;
				LabelTable[htr].updatePass = pass;
				return 1;
			}
		} else if (++tr >= LABTABSIZE) {
			tr = 0;
		}
	}
	HashTable[tr] = NextLocation;
	LabelTable[NextLocation].name = STRDUP(nname);
	if (LabelTable[NextLocation].name == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}
	LabelTable[NextLocation].IsDEFL = IsDEFL;
	LabelTable[NextLocation].updatePass = pass;
	LabelTable[NextLocation].value = nvalue;
	if (!undefined) {
		LabelTable[NextLocation].used = -1;
		LabelTable[NextLocation].page = MemoryCPage;
	} else {
		LabelTable[NextLocation].used = 1;
		LabelTable[NextLocation].page = -1;
	}
	++NextLocation;
	return 1;
}

int CLabelTable::Update(char* nname, aint nvalue) {
	int tr, htr, otr;
	otr = tr = Hash(nname);
	while ((htr = HashTable[tr])) {
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

int CLabelTable::GetValue(char* nname, aint& nvalue) {
	int tr, htr, otr;
	otr = tr = Hash(nname);
	while ((htr = HashTable[tr])) {
		if (!strcmp((LabelTable[htr].name), nname)) {
			if (LabelTable[htr].used == -1 && pass != LASTPASS)
			{
				LabelTable[htr].used = 1;
			}

			if (LabelTable[htr].page == -1) {
				IsLabelNotFound = 2;
				nvalue = 0;
				return 0;
			} else {
				nvalue = LabelTable[htr].value;
				//if (pass == LASTPASS - 1) {

				//}

				return 1;
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

int CLabelTable::Find(char* nname) {
	int tr, htr, otr;
	otr = tr = Hash(nname);
	while ((htr = HashTable[tr])) {
		if (!strcmp((LabelTable[htr].name), nname)) {
			if (LabelTable[htr].page == -1) {
				return 0;
			} else {
				return 1;
			}
		}
		if (++tr >= LABTABSIZE) {
			tr = 0;
		}
		if (tr == otr) {
			break;
		}
	}
	return 0;
}

int CLabelTable::IsUsed(char* nname) {
	int tr, htr, otr;
	otr = tr = Hash(nname);
	while ((htr = HashTable[tr])) {
		if (!strcmp((LabelTable[htr].name), nname)) {
			if (LabelTable[htr].used > 0) {
				return 1;
			} else {
				return 0;
			}
		}
		if (++tr >= LABTABSIZE) {
			tr = 0;
		}
		if (tr == otr) {
			break;
		}
	}
	return 0;
}

int CLabelTable::Remove(char* nname) {
	int tr, htr, otr;
	otr = tr = Hash(nname);
	while ((htr = HashTable[tr])) {
		if (!strcmp((LabelTable[htr].name), nname)) {
			*LabelTable[htr].name = 0;
			LabelTable[htr].value = 0;
			LabelTable[htr].used = 0;
			LabelTable[htr].page = 0;
			LabelTable[htr].forwardref = 0;

			return 1;
		}
		if (++tr >= LABTABSIZE) {
			tr = 0;
		}
		if (tr == otr) {
			break;
		}
	}
	return 0;
}

void CLabelTable::RemoveAll() {
	for (int i = 1; i < NextLocation; ++i) {
		*LabelTable[i].name = 0;
		LabelTable[i].value = 0;
		LabelTable[i].used = 0;
		LabelTable[i].page = 0;
		LabelTable[i].forwardref = 0;
	}
	NextLocation = 0;
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
	char line[LINEMAX], *ep;

	if (NULL == FP_ListingFile) return;		// listing file must be already opened here

	/*fputs("\nvalue      label\n",FP_ListingFile);*/
	fputs("\nValue    Label\n", FP_ListingFile);
	/*fputs("-------- - -----------------------------------------------------------\n",FP_ListingFile);*/
	fputs("------ - -----------------------------------------------------------\n", FP_ListingFile);
	for (int i = 1; i < NextLocation; ++i) {
		if (LabelTable[i].page != -1) {
			ep = line;
			*(ep) = 0;
			*(ep++) = '0';
			*(ep++) = 'x';
			PrintHEXAlt(ep, LabelTable[i].value);
			*(ep++) = ' ';
			*(ep++) = LabelTable[i].used > 0 ? ' ' : 'X';
			*(ep++) = ' ';
			STRCPY(ep, LINEMAX - (ep - &line[0]), LabelTable[i].name);
			ep += strlen(LabelTable[i].name);
			*(ep++) = '\n';
			*(ep) = 0;
			fputs(line, FP_ListingFile);
		}
	}
}

void CLabelTable::DumpForUnreal() {
	char ln[LINEMAX], * ep;
	int page;
	if (FP_UnrealList == NULL && !FOPEN_ISOK(FP_UnrealList, Options::UnrealLabelListFName, "w")) {
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
			PrintHEXAlt(ep, lvalue);
			*(ep++) = ' ';
			STRCPY(ep, LINEMAX-(ep-ln), LabelTable[i].name);
			STRCAT(ln, LINEMAX, "\n");
			fputs(ln, FP_UnrealList);
		}
	}
	fclose(FP_UnrealList);
}

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
			STRCAT(ErrorLine, LINEMAX2, "0x");
			PrintHEX32(l, LabelTable[i].value);
			*l = 0;
			STRCAT(ErrorLine, LINEMAX2, lnrs);
			STRCAT(ErrorLine, LINEMAX2, "\n");
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
	if (funtab[NextLocation].name == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}
	funtab[NextLocation].funp = nfunp;
	++NextLocation;

	STRCPY(p = temp, LINEMAX, nname);
	while ((*p = (char) toupper(*p))) { ++p; }

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
	if (funtab[NextLocation].name == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}
	funtab[NextLocation].funp = nfunp;
	++NextLocation;

	return 1;
}

int CFunctionTable::insertd(const char* nname, void(*nfunp) (void)) {
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

CLocalLabelTableEntry::CLocalLabelTableEntry(aint nnummer, aint nvalue, CLocalLabelTableEntry* n) {
	regel = CompiledCurrentLine;
	nummer = nnummer;
	value = nvalue;
	//regel=CurrentLocalLine; nummer=nnummer; value=nvalue;
	prev = n; next = NULL;
	if (n) {
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

aint CLocalLabelTable::zoekf(aint nnum) {
	CLocalLabelTableEntry* l = first;
	while (l && l->regel <= CompiledCurrentLine) l = l->next;
	while (l) {
		if (l->nummer == nnum) {
			return l->value;
		}
		l = l->next;
	}
	return (aint) - 1;
}

aint CLocalLabelTable::zoekb(aint nnum) {
	CLocalLabelTableEntry* l = last;
	while (l && l->regel > CompiledCurrentLine) l = l->prev;
	while (l) {
		if (l->nummer == nnum) {
			return l->value;
		}
		l = l->prev;
	}
	return (aint) - 1;
}

CDefineTableEntry::CDefineTableEntry(const char* nname, const char* nvalue, CStringsList* nnss, CDefineTableEntry* nnext) {
	char* s1;
    char* sbegin,*s2;
	name = STRDUP(nname);
	if (name == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}
	value = new char[strlen(nvalue) + 1];
	if (value == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}
	s1 = value;
	sbegin = s2 = strdup(nvalue);
	SkipBlanks(s2);
	while (*s2 && *s2 != '\n' && *s2 != '\r') {
		*s1 = *s2; ++s1; ++s2;
	}
	*s1 = 0;
	free(sbegin);

	next = nnext;
	nss = nnss;
}

void CDefineTable::Init() {
	for (int i = 0; i < 128; defs[i++] = 0) {
		;
	}
}

void CDefineTable::Add(const char* name, const char* value, CStringsList* nss) {
	if (FindDuplicate(name)) {
		Error("Duplicate define", name);
	}
	defs[(unsigned char)*name] = new CDefineTableEntry(name, value, nss, defs[(unsigned char)*name]);
}

char* CDefineTable::Get(const char* name) {
	CDefineTableEntry* p = defs[(unsigned char)*name];
	DefArrayList = 0;
	while (p) {
		if (!strcmp(name, p->name)) {
			if (p->nss) {
				DefArrayList = p->nss;
			}
			return p->value;
		}
		p = p->next;
	}
	return NULL;
}

int CDefineTable::FindDuplicate(const char* name) {
	CDefineTableEntry* p = defs[(unsigned char)*name];
	while (p) {
		if (!strcmp(name, p->name)) {
			return 1;
		}
		p = p->next;
	}
	return 0;
}

int CDefineTable::Replace(const char* name, const char* value) {
	CDefineTableEntry* p = defs[(unsigned char)*name];
	while (p) {
		if (!strcmp(name, p->name)) {
			delete[](p->value);
			p->value = new char[strlen(value)+1];
			strcpy(p->value,value);

			return 0;
		}
		p = p->next;
	}
	defs[(unsigned char)*name] = new CDefineTableEntry(name, value, 0, defs[(unsigned char)*name]);
	return 1;
}

int CDefineTable::Replace(const char* name, const int value) {
	char newIntValue[24];
	SPRINTF1(newIntValue, sizeof(newIntValue), "%d", value);
	return Replace(name, newIntValue);
}

int CDefineTable::Remove(const char* name) {
	CDefineTableEntry* p = defs[(unsigned char)*name];
	CDefineTableEntry* p2 = NULL;
	if (p && !strcmp(name, p->name)) {
		defs[(unsigned char)*name] = p->next;
	} else
		while (p) {
		if (!strcmp(name, p->name)) {
			if (p2 != NULL) {
				p2->next = p->next;
			} else {
				p = p->next;
			}

			return 1;
		}
		p2 = p;
		p = p->next;
	}
	return 0;
}

void CDefineTable::RemoveAll() {
	for (int i=0; i < 128; i++)
	{
		if (defs[i] != NULL)
		{
			delete defs[i];
			defs[i] = NULL;
		}
	}
}

void CMacroDefineTable::Init() {
	defs = NULL;
	for (int i = 0; i < 128; used[i++] = 0) {
		;
	}
}

void CMacroDefineTable::AddMacro(char* naam, char* vervanger) {
	CDefineTableEntry* tmpdefs = new CDefineTableEntry(naam, vervanger, 0, defs);
	defs = tmpdefs;
	// By Antipod: http://zx.pk.ru/showpost.php?p=159487&postcount=264
	if ( !strcmp( naam, "_aFunc" ) )
	{
		defs = tmpdefs;
	}
	// --
	used[(unsigned char)*naam] = 1;
}

CDefineTableEntry* CMacroDefineTable::getdefs() {
	return defs;
}

void CMacroDefineTable::setdefs(CDefineTableEntry* ndefs) {
	defs = ndefs;
}

char* CMacroDefineTable::getverv(char* name) {
	CDefineTableEntry* p = defs;
	if (!used[(unsigned char)*name] && *name != KDelimiter) {
		return NULL;
	}// std check
	while (p) {
		if (!strcmp(name, p->name)) {
			return p->value;// full match
		}
		p = p->next;
	}
	// extended check for '_'
	// By Antipod: http://zx.pk.ru/showpost.php?p=159487&postcount=264
	char** array = NULL;
	int count = 0;
	int positions[ KTotalJoinedParams + 1 ];
	SplitToArray( name, array, count, positions );

	int tempBufPos = 0;
	bool replaced = false;
	for ( int i = 0; i<count; i++ )
	{
		p = defs;

		if ( *array[ i ] != KDelimiter )
		{
			bool found = false;
			while( p )
			{
				if ( !strcmp( array[ i ], p->name ) )
				{
					replaced = found = true;
					tempBufPos = Copy( tempBuf, tempBufPos, p->value, 0, strlen( p->value ) );
					break;
				}
				p = p->next;
			}
			if ( !found )
			{
				tempBufPos = Copy( tempBuf, tempBufPos, array[ i ], 0, strlen( array[i] ) );
			}
		}
		else
		{
			tempBuf[ tempBufPos++ ] = KDelimiter;
			tempBuf[ tempBufPos ] = 0;
		}
	}

	FreeArray( array, count );

	return replaced ? tempBuf : NULL;
	// --
}

void CMacroDefineTable::SplitToArray( const char* aName, char**& aArray, int& aCount, int* aPositions ) const
{
	int nameLen = strlen( aName );
	aCount = 0;
	int itemSizes[ KTotalJoinedParams ];
	int currentItemsize = 0;
	bool newLex = false;
	int prevLexPos = 0;
	for ( int i = 0; i<nameLen; i++, currentItemsize++ )
	{
		if ( aName[ i ] == KDelimiter || aName[ prevLexPos ] == KDelimiter )
		{
			newLex = true;
		}

		if ( newLex && currentItemsize )
		{
			itemSizes[ aCount ] = currentItemsize;
			currentItemsize = 0;
			aPositions[ aCount ] = prevLexPos;
			prevLexPos = i;
			aCount++;
			newLex = false;
		}

		if ( aCount == KTotalJoinedParams )
		{
			Error("Too much joined params!", NULL, FATAL);
		}
	}

	if ( currentItemsize )
	{
		itemSizes[ aCount ] = currentItemsize;
		aPositions[ aCount ] = prevLexPos;
		aCount++;
	}

	if ( aCount )
	{
		aArray = new char*[ aCount ];
		for ( int i = 0; i<aCount; i++ )
		{
			int itemSize = itemSizes[ i ];
			if ( itemSize )
			{
				aArray[ i ] = new char[ itemSize + 1 ];
				Copy( aArray[ i ], 0, &aName[ aPositions[ i ] ], 0, itemSize );
			}
			else
			{
				Error("Internal error. SplitToArray()", NULL, FATAL);
			}
		}
	}
}

int CMacroDefineTable::Copy( char* aDest, int aDestPos, const char* aSource, int aSourcePos, int aBytes ) const
{
	int i = 0;
    for ( i = 0; i < aBytes; i++ )
    {
        aDest[ i + aDestPos ] = aSource[ i + aSourcePos ];
    }
	aDest[ i + aDestPos ] = 0;
	return i + aDestPos;
}

void CMacroDefineTable::FreeArray( char** aArray, int aCount )
{
	if ( aArray )
	{
		for ( int i = 0; i<aCount; i++ )
		{
			delete [] aArray[ i ];
		}
	}
	delete aArray;
}
// --

int CMacroDefineTable::FindDuplicate(char* name) {
	CDefineTableEntry* p = defs;
	if (!used[(unsigned char)*name]) {
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
	if (!used[(unsigned char)*naam]) {
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
	char* macroname;
	macroname = STRDUP(nnaam);
	if (macroname == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}
	macs = new CMacroTableEntry(macroname, macs);
	used[(unsigned char)*macroname] = 1;
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
	if (!used[(unsigned char)*naam]) return 0;
	CMacroTableEntry* m = macs;
	while (m && strcmp(naam, m->naam)) m = m->next;
	if (!m) return 0;
	// macro found, emit it, prepare temporary instance label base
	char* omacrolabp = macrolabp;
	char labnr[LINEMAX], ml[LINEMAX];
	SPRINTF1(labnr, LINEMAX, "%d", macronummer++);
	macrolabp = labnr;
	if (omacrolabp) {
		STRCAT(macrolabp, LINEMAX, "."); STRCAT(macrolabp, LINEMAX, omacrolabp);
	} else {
		MacroDefineTable.Init();
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
	CStringsList* olijstp = lijstp; int olijst = lijst;
	lijstp = m->body; lijst = 1;
	STRCPY(ml, LINEMAX, line);
	while (lijstp) {
		STRCPY(line, LINEMAX, lijstp->string);
		//_COUT ">>" _CMDL line _ENDL;
		lijstp = lijstp->next;
		/* ParseLine(); */
		ParseLineSafe();
	}
	STRCPY(line, LINEMAX, ml);
	lijst = olijst;
	lijstp = olijstp;
	MacroDefineTable.setdefs(odefs);
	macrolabp = omacrolabp;
	--listmacro; donotlist = 1;
	return 2;
}

CStructureEntry1::CStructureEntry1(char* nnaam, aint noffset) {
	next = 0;
	naam = STRDUP(nnaam);
	if (naam == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}
	offset = noffset;
}

CStructureEntry2::CStructureEntry2(aint noffset, aint nlen, aint ndef, EStructureMembers ntype) {
	next = 0; offset = noffset; len = nlen; def = ndef; type = ntype;
}

CStructure::CStructure(char* nnaam, char* nid, int idx, int no, int ngl, CStructure* p) {
	mnf = mnl = 0; mbf = mbl = 0;
	naam = STRDUP(nnaam);
	if (naam == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}
	id = STRDUP(nid);
	if (id == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}
	binding = idx; next = p; noffset = no; global = ngl;
}

void CStructure::AddLabel(char* nnaam) {
	CStructureEntry1* n = new CStructureEntry1(nnaam, noffset);
	if (!mnf) {		//FIXME Ped7g how about simple std::vector or similar and stop doing all this fuss manually with cryptic short names?
		mnf = n;
	}
	if (mnl) {
		mnl->next = n;
	}
	mnl = n;
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
	while (np) {	//FIXME Ped7g - optimize this? (need test first to validate rewritten code)
		STRCPY(str2, LINEMAX, str);
		STRCAT(str2, LINEMAX, np->naam);
		CopyLabel(str2, np->offset);
		np = np->next;
	}
}

void CStructure::CopyMember(CStructureEntry2* ni, aint ndef) {
	CStructureEntry2* n = new CStructureEntry2(noffset, ni->len, ndef, ni->type);
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
		switch (ip->type) {
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
			Error("internalerror CStructure::CopyMembers", NULL, FATAL);
		}
		ip = ip->next;
	}
	while (haakjes--) {
		if (!need(lp, '}')) {
			Error("closing } missing");
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
	op = sn;
	p = ValidateLabel(sn, 1);
	if (pass == LASTPASS) {
		if (!GetLabelValue(op, oval)) {
			Error("Internal error. ParseLabel()", op, FATAL);
		}
		if (noffset != oval) {
			Error("Label has different value in pass 2", temp);
		}
	} else {
		if (!LabelTable.Insert(p, noffset)) {
			Error("Duplicate label", tp, EARLY);
		}
	}
	free(p);
	STRCAT(sn, LINEMAX, ".");
	while (np) {
		STRCPY(ln, LINEMAX, sn);
		STRCAT(ln, LINEMAX, np->naam);
		op = ln;
		if (!(p = ValidateLabel(ln, 1))) {
			Error("Illegal labelname", ln, EARLY);
		}
		if (pass == LASTPASS) {
			if (!GetLabelValue(op, oval)) {
				Error("Internal error. ParseLabel()", op, FATAL);
			}
			if (np->offset != oval) {
				Error("Label has different value in pass 2", temp);
			}
		} else {
			if (!LabelTable.Insert(p, np->offset)) {
				Error("Duplicate label", tp, EARLY);
			}
		}
		free(p);
		np = np->next;
	}
}

void CStructure::emitlab(char* iid) {
	char ln[LINEMAX], sn[LINEMAX], * p, * op;
	aint oval;
	CStructureEntry1* np = mnf;
	STRCPY(sn, LINEMAX, iid);
	op = p = sn;
	p = ValidateLabel(p, 1);
	if (pass == LASTPASS) {
		if (!GetLabelValue(op, oval)) {
			Error("Internal error. ParseLabel()", op, FATAL);
		}
		if (CurAddress != oval) {
			Error("Label has different value in pass 2", temp);
		}
	} else {
		if (!LabelTable.Insert(p, CurAddress)) {
			Error("Duplicate label", tp, EARLY);
		}
	}
	free(p);
	STRCAT(sn, LINEMAX, ".");
	while (np) {
		STRCPY(ln, LINEMAX, sn);
		STRCAT(ln, LINEMAX, np->naam);
		op = ln;
		if (!(p = ValidateLabel(ln, 1))) {
			Error("Illegal labelname", ln, EARLY);
		}
		if (pass == LASTPASS) {
			if (!GetLabelValue(op, oval)) {
				Error("Internal error. ParseLabel()", op, FATAL);
			}
			if (np->offset + CurAddress != oval) {
				Error("Label has different value in pass 2", temp);
			}
		} else {
			if (!LabelTable.Insert(p, np->offset + CurAddress)) {
				Error("Duplicate label", tp, EARLY);
			}
		}
		free(p);
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
		switch (ip->type) {
		case SMEMBBLOCK:
			t = ip->len;
			while (t--) {
				e[et++] = ip->def;
			}
			break;

		case SMEMBBYTE:
			synerr = 0;
			if (!ParseExpression(p, val)) {
				val = ip->def;
			}
			synerr = 1;
			e[et++] = val & 0xFF;
			check8(val); comma(p);
			break;
		case SMEMBWORD:
			synerr = 0;
			if (!ParseExpression(p, val)) {
				val = ip->def;
			}
			synerr = 1;
			e[et++] = val & 0xFF; e[et++] = (val >> 8) & 0xFF;
			check16(val); comma(p);
			break;
		case SMEMBD24:
			synerr = 0; if (!ParseExpression(p, val)) {
							val = ip->def;
						} synerr = 1;
			e[et++] = val & 0xFF; e[et++] = (val >> 8) & 0xFF; e[et++] = (val >> 16) & 0xFF;
			check24(val); comma(p);
			break;
		case SMEMBDWORD:
			synerr = 0; if (!ParseExpression(p, val)) {
							val = ip->def;
						} synerr = 1;
			e[et++] = val & 0xFF; e[et++] = (val >> 8) & 0xFF; e[et++] = (val >> 16) & 0xFF; e[et++] = (val >> 24) & 0xFF;
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
			ErrorInt("Internal Error CStructure::emitmembs", ip->type, FATAL);
		}
		ip = ip->next;
	}
	while (haakjes--) {
		if (!need(p, '}')) {
			Error("closing } missing");
		}
	}
	SkipBlanks(p);
	if (*p) Error("[STRUCT] Syntax error - too many arguments?");
	if (et) {
		e[et] = -1;
		EmitBytes(e);
	}
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
		Error("Duplicate structure name", naam, EARLY);
	}
	strs[(unsigned char)*sp] = new CStructure(naam, sp, idx, 0, gl, strs[(unsigned char)*sp]);
	if (no) {
		strs[(unsigned char)*sp]->AddMember(new CStructureEntry2(0, no, 0, SMEMBBLOCK));
	}
	return strs[(unsigned char)*sp];
}

CStructure* CStructureTable::zoek(const char* naam, int gl) {
	char sn[LINEMAX], * sp;
	sn[0] = 0;
	if (!gl && ModuleName) {
		STRCPY(sn, LINEMAX, ModuleName);
		STRCAT(sn, LINEMAX, ".");
	}
	//sp = STRCAT(sn, LINEMAX, naam); //mmm
	STRCAT(sn, LINEMAX, naam);
	sp = sn;
	CStructure* p = strs[(unsigned char)*sp];
	while (p) {
		if (!strcmp(sp, p->id)) {
			return p;
		} p = p->next;
	}
	if (!gl && ModuleName) {
		sp += 1 + strlen(ModuleName); p = strs[(unsigned char)*sp];
		while (p) {
			if (!strcmp(sp, p->id)) {
				return p;
			} p = p->next;
		}
	}
	return 0;
}

int CStructureTable::FindDuplicate(char* naam) {
	CStructure* p = strs[(unsigned char)*naam];
	while (p) {
		if (!strcmp(naam, p->naam)) {
			return 1;
		} p = p->next;
	}
	return 0;
}

int CStructureTable::Emit(char* naam, char* l, char*& p, int gl) {
	//_COUT naam _ENDL; ExitASM(1);
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


CDevice::CDevice(const char *name, CDevice *n) {
	ID = STRDUP(name);
	Next = NULL;
	if (n) {
	   	n->Next = this;
    }
	CurrentSlot = 0;
	CurrentPage = 0;
	SlotsCount = 0;
	PagesCount = 0;

	for (int i=0;i<256;i++) {
		Slots[i] = 0;
		Pages[i] = 0;
	}
}

CDevice::~CDevice() {
	//CDefineSlot *Slot;

	//Slot = Slots;
	//while (Slot != NULL) {
	//	Slot = Slots->Next;
	for (int i=0;i<256;i++) {
		if (Slots[i]) delete Slots[i];
	}
	//}

	//Page = Pages;
	//while (Page != NULL) {
	//	Page = Pages->Next;
	for (int i=0;i<256;i++) {
		if (Pages[i]) delete Pages[i];
	}
	//}

	if (Next) {
		delete Next;
	}
}

void CDevice::AddSlot(aint adr, aint size) {
	Slots[SlotsCount] = new CDeviceSlot(adr, size, SlotsCount);
	SlotsCount++;
}

void CDevice::AddPage(aint size) {
	Pages[PagesCount] = new CDevicePage(size, PagesCount);
	PagesCount++;
}

CDeviceSlot* CDevice::GetSlot(aint num) {
	if (Slots[num]) {
		return Slots[num];
	}

	Error("Wrong slot number", lp);
	return Slots[0];
}

CDevicePage* CDevice::GetPage(aint num) {
	if (Pages[num]) {
		return Pages[num];
	}

	Error("Wrong page number", lp);
	return Pages[0];
}

CDeviceSlot::CDeviceSlot(aint adr, aint size, aint number /*, CDeviceSlot *n*/) {
	Address = adr;
	Size = size;
	Number = number;
	/*Next = NULL;
	if (n) {
	   	n->Next = this;
    }*/
}

CDevicePage::CDevicePage(aint size, aint number /*, CDevicePage *n*/) {
	Size = size;
	Number = number;
	RAM = (char*) calloc(size, sizeof(char));
	if (RAM == NULL) {
		ErrorInt("No enough memory", size, FATAL);
	}
	/*Next = NULL;
	if (n) {
	   	n->Next = this;
    }*/
}

CDeviceSlot::~CDeviceSlot() {
	/*if (Next) {
		delete Next;
	}*/
}

CDevicePage::~CDevicePage() {
	/*try {
		free(RAM);
	} catch(...) {

	}*/
	/*if (Next) {
		delete Next;
	}*/
}

int LuaGetLabel(char *name) {
	aint val;

	if (!LabelTable.GetValue(name, val)) {
		return -1;
	} else {
		return val;
	}
}

//eof tables.cpp
