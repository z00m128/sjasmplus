/* 

  SjASMPlus Z80 Cross Compiler

  This is modified source of SjASM by Aprisobal - aprisobal@tut.by

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

// reader.cpp

#include "sjdefs.h"

/* modified */
int cmphstr(char*& p1, char* p2) {
	unsigned int i = 0;
	/* old:
	if (isupper(*p1)) 
	  while (p2[i]) { 
		if (p1[i]!=toupper(p2[i])) return 0; 
		++i; 
	  }
	else 
	  while (p2[i]) { 
		if (p1[i]!=p2[i]) return 0; 
		++i; 
	  }*/
	/* (begin) */  
	unsigned int v = 0;
	if (strlen(p1) >= strlen(p2)) {
		if (isupper(*p1)) {
			while (p2[i]) {
				if (p1[i] != toupper(p2[i])) {
					v = 0;
				} else {
					++v;
				} 
				++i;
			}
			if (strlen(p2) != v) {
				return 0;
			}
		} else {
			while (p2[i]) {
				if (p1[i] != p2[i]) {
					v = 0;
				} else {
					++v;
				} 
				++i;
			}
			if (strlen(p2) != v) {
				return 0;
			}
		}
		/* (end) */

		if (i <= strlen(p1) && p1[i] > ' '/* && p1[i]!=':'*/) {
			return 0;
		}
		p1 += i;
		return 1;
	} else {
		return 0;
	}
}

int White() {
	return (*lp && *lp <= ' ');
}

int SkipBlanks() {
	while (*lp && *lp <= ' ') {
		++lp;
	}
	return (*lp == 0);
}

void SkipBlanks(char*& p) {
	while (*p && *p <= ' ') {
		++p;
	}
}

/* added */
void SkipParam(char*& p) {
	SkipBlanks(p);
	if (!(*p)) {
		return;
	}
	while (((*p) != '\0') && ((*p) != ',')) {
		p++;
	}
}

/* modified */
int NeedEQU() {
	char* olp = lp;
	SkipBlanks();
	/*if (*lp=='=') { ++lp; return 1; }*/
	/* cut: if (*lp=='=') { ++lp; return 1; } */
	if (*lp == '.') {
		++lp;
	}
	if (cmphstr(lp, "equ")) {
		return 1;
	}
	lp = olp;
	return 0;
}

/* added */
int NeedDEFL() {
	char* olp = lp;
	SkipBlanks();
	if (*lp == '=') {
		++lp; return 1;
	}
	if (*lp == '.') {
		++lp;
	}
	if (cmphstr(lp, "defl")) {
		return 1;
	}
	lp = olp;
	return 0;
}

int NeedField() {
	char* olp = lp;
	SkipBlanks();
	if (*lp == '#') {
		++lp; return 1;
	}
	if (*lp == '.') {
		++lp;
	}
	if (cmphstr(lp, "field")) {
		return 1;
	}
	lp = olp;
	return 0;
}

int comma(char*& p) {
	SkipBlanks(p);
	if (*p != ',') {
		return 0;
	}
	++p; return 1;
}

int cpc = '4';

/* not modified */
int oparen(char*& p, char c) {
	SkipBlanks(p);
	if (*p != c) {
		return 0;
	}
	if (c == '[') {
		cpc = ']';
	}
	if (c == '(') {
		cpc = ')';
	}
	if (c == '{') {
		cpc = '}';
	}
	++p; return 1;
}

int cparen(char*& p) {
	SkipBlanks(p);
	if (*p != cpc) {
		return 0;
	}
	++p; return 1;
}

char* getparen(char* p) {
	int teller = 0;
	SkipBlanks(p);
	while (*p) {
		if (*p == '(') {
			++teller;
		} else if (*p == ')') {
			if (teller == 1) {
				SkipBlanks(++p); return p;
			} else {
				--teller;
			}
		}
		++p;
	}
	return 0;
}

char nidtemp[LINEMAX]; /* added */
/* modified */
char* GetID(char*& p) {
	/*char nid[LINEMAX],*/ char* np;
	np = nidtemp;
	SkipBlanks(p);
	//if (!isalpha(*p) && *p!='_') return 0;
	if (*p && !isalpha((unsigned char) * p) && *p != '_') {
		return 0;
	}
	while (*p) {
		if (!isalnum((unsigned char) * p) && *p != '_' && *p != '.' && *p != '?' && *p != '!' && *p != '#' && *p != '@') {
			break;
		}
		*np = *p; ++p; ++np;
	}
	*np = 0;
	/*return STRDUP(nid);*/
	return nidtemp;
}

char instrtemp[LINEMAX]; /* added */
/* modified */
char* getinstr(char*& p) {
	/*char nid[LINEMAX],*/ char* np;
	np = instrtemp;
	SkipBlanks(p);
	if (!isalpha((unsigned char) * p) && *p != '.') {
		return 0;
	} else {
		*np = *p; ++p; ++np;
	}
	while (*p) {
		if (!isalnum((unsigned char) * p) && *p != '_') {
			break;
		} /////////////////////////////////////
		*np = *p; ++p; ++np;
	}
	*np = 0;
	/*return STRDUP(nid);*/
	return instrtemp;
}

/* changes applied from SjASM 0.39g */
int check8(aint val) {
	if (val != (val & 255) && ~val > 127) {
		Error("Bytes lost", 0); return 0;
	}
	return 1;
}

/* changes applied from SjASM 0.39g */
int check8o(long val) {
	if (val < -128 || val > 127) {
		Error("Offset out of range", 0); return 0;
	}
	return 1;
}

/* changes applied from SjASM 0.39g */
int check16(aint val) {
	if (val != (val & 65535) && ~val > 32767) {
		Error("Bytes lost", 0); return 0;
	}
	return 1;
}

/* changes applied from SjASM 0.39g */
int check24(aint val) {
	if (val != (val & 16777215) && ~val > 8388607) {
		Error("Bytes lost", 0); return 0;
	}
	return 1;
}

int need(char*& p, char c) {
	SkipBlanks(p);
	if (*p != c) {
		return 0;
	}
	++p; return 1;
}

int needa(char*& p, char* c1, int r1, char* c2, int r2, char* c3, int r3) {
	//  SkipBlanks(p);
	if (!isalpha((unsigned char) * p)) {
		return 0;
	}
	if (cmphstr(p, c1)) {
		return r1;
	}
	if (c2 && cmphstr(p, c2)) {
		return r2;
	}
	if (c3 && cmphstr(p, c3)) {
		return r3;
	}
	return 0;
}

int need(char*& p, char* c) {
	SkipBlanks(p);
	while (*c) {
		if (*p != *c) {
			c += 2; continue;
		}
		++c;
		if (*c == ' ') {
			++p; return *(c - 1);
		}
		if (*c == '_' && *(p + 1) != *(c - 1)) {
			++p; return *(c - 1);
		}
		if (*(p + 1) == *c) {
			p += 2; return *(c - 1) + *c;
		}
		++c;
	}
	return 0;
}

int getval(int p) {
	switch (p) {
	case '0':
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	case '8':
	case '9':
		return p - '0';
	default:
		if (isupper((unsigned char)p)) {
			return p - 'A' + 10;
		}
		if (islower((unsigned char)p)) {
			return p - 'a' + 10;
		}
		return 200;
	}
}

int GetConstant(char*& op, aint& val) {
	aint base,pb = 1,v,oval;
	char* p = op,* p2,* p3;
	SkipBlanks(p); p3 = p;
	val = 0;
	switch (*p) {
	case '#':
	case '$':
		++p;
		while (isalnum((unsigned char) * p)) {
			if ((v = getval(*p)) >= 16) {
				Error("Digit not in base", op); return 0;
			}
			oval = val; val = val * 16 + v; ++p; if (oval > val) {
												 	Error("Overflow", 0, SUPPRESS);
												 }
		}
		if (p - p3 < 2) {
			Error("Syntax error", op, CATCHALL); return 0;
		}
		op = p; return 1;
	case '%':
		++p;
		while (isdigit((unsigned char) * p)) {
			if ((v = getval(*p)) >= 2) {
				Error("Digit not in base", op); return 0;
			}
			oval = val; val = val * 2 + v; ++p; if (oval > val) {
													Error("Overflow", 0, SUPPRESS);
												}
		}
		if (p - p3 < 2) {
			Error("Syntax error", op, CATCHALL); return 0;
		}
		op = p; return 1;
	case '0':
		++p;
		if (*p == 'x' || *p == 'X') {
			++p;
			while (isalnum((unsigned char) * p)) {
				if ((v = getval(*p)) >= 16) {
					Error("Digit not in base", op); return 0;
				}
				oval = val; val = val * 16 + v; ++p; if (oval > val) {
													 	Error("Overflow", 0, SUPPRESS);
													 }
			}
			if (p - p3 < 3) {
				Error("Syntax error", op, CATCHALL); return 0;
			}
			op = p; return 1;
		}
	default:
		while (isalnum((unsigned char) * p)) {
			++p;
		}
		p2 = p--;
		if (isdigit((unsigned char) * p)) {
			base = 10;
		} else if (*p == 'b') {
			base = 2; --p;
		} else if (*p == 'h') {
			base = 16; --p;
		} else if (*p == 'B') {
			base = 2; --p;
		} else if (*p == 'H') {
			base = 16; --p;
		} else if (*p == 'o') {
			base = 8; --p;
		} else if (*p == 'q') {
			base = 8; --p;
		} else if (*p == 'd') {
			base = 10; --p;
		} else if (*p == 'O') {
			base = 8; --p;
		} else if (*p == 'Q') {
			base = 8; --p;
		} else if (*p == 'D') {
			base = 10; --p;
		} else {
			return 0;
		}
		do {
			if ((v = getval(*p)) >= base) {
				Error("Digit not in base", op); return 0;
			}
			oval = val; val += v * pb; if (oval > val) {
									   	Error("Overflow", 0, SUPPRESS);
									   }
			pb *= base;
		} while (p-- != p3);
		op = p2;
		return 1;
	}
}

int GetCharConstChar(char*& op, aint& val) {
	if ((val = *op++) != '\\') {
		return 1;
	}
	switch (val = *op++) {
	case '\\':
	case '\'':
	case '\"':
	case '\?':
		return 1;
	case 'n':
	case 'N':
		val = 10; return 1;
	case 't':
	case 'T':
		val = 9; return 1;
	case 'v':
	case 'V':
		val = 11; return 1;
	case 'b':
	case 'B':
		val = 8; return 1;
	case 'r':
	case 'R':
		val = 13; return 1;
	case 'f':
	case 'F':
		val = 12; return 1;
	case 'a':
	case 'A':
		val = 7; return 1;
	case 'e':
	case 'E':
		val = 27; return 1;
	case 'd':
	case 'D':
		val = 127; return 1;
	default:
		--op; val = '\\'; Error("Unknown escape", op); return 1;
	}
	return 0;
}

/* added */
int GetCharConstCharSingle(char*& op, aint& val) {
	if ((val = *op++) != '\\') {
		return 1;
	}
	switch (val = *op++) {
	case '\'':
		return 1;
	}
	--op; val = '\\';
	return 1;
}

int GetCharConst(char*& p, aint& val) {
	aint s = 24,r,t = 0; val = 0;
	char* op = p,q;
	if (*p != '\'' && *p != '"') {
		return 0;
	}
	q = *p++;
	do {
		if (!*p || *p == q) {
			p = op; return 0;
		}
		GetCharConstChar(p, r);
		val += r << s; s -= 8; ++t;
	} while (*p != q);
	if (t > 4) {
		Error("Overflow", 0, SUPPRESS);
	}
	val = val >> (s + 8);
	++p;
	return 1;
}

/* modified */
int GetBytes(char*& p, int e[], int add, int dc) {
	aint val;
	int t = 0;
	while ('o') {
		SkipBlanks(p);
		if (!*p) {
			Error("Expression expected", 0, SUPPRESS); break;
		}
		if (t == 128) {
			Error("Too many arguments", p, SUPPRESS); break;
		}
		if (*p == '"') {
			p++;
			do {
				if (!*p || *p == '"') {
					Error("Syntax error", p, SUPPRESS); e[t] = -1; return t;
				}
				if (t == 128) {
					Error("Too many arguments", p, SUPPRESS); e[t] = -1; return t;
				}
				GetCharConstChar(p, val); check8(val); e[t++] = (val + add) & 255;
			} while (*p != '"');
			++p; if (dc && t) {
				 	e[t - 1] |= 128;
				 }
			/* (begin add) */
		} else if (*p == 0x27) {
		  	p++;
			do {
				if (!*p || *p == 0x27) {
					Error("Syntax error", p, SUPPRESS); e[t] = -1; return t;
				}
				if (t == 128) {
		  			Error("Too many arguments", p, SUPPRESS); e[t] = -1; return t;
				}
		  		GetCharConstCharSingle(p, val); check8(val); e[t++] = (val + add) & 255;
			} while (*p != 0x27);
		  	++p; if (dc && t) {
				 	e[t - 1] |= 128;
				 }
		  	/* (end add) */
		} else {
			if (ParseExpression(p, val)) {
				check8(val); e[t++] = (val + add) & 255;
			} else {
				Error("Syntax error", p, SUPPRESS); break;
			}
		}
		SkipBlanks(p); if (*p != ',') {
					   	break;
					   } ++p;
	}
	e[t] = -1; return t;
}

/* modified */
char* GetFileName(char*& p) {
	int o = 0;
	int o2 = 0;
	char* fn, * np;
	fn = np = new char[LINEMAX];
	if (np == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	*fn = 0;
	SkipBlanks(p);
	if (!(*p)) {
		return fn;
	}
	if (*p == '"') {
		o = 1; ++p;
	} else if (*p == '<') {
		o = 2; ++p;
	}
	if (*p && strstr(p, ":")) {
		o2 = 1;
	} /* added */
	/* while (!White() && *p!='"' && *p!='>') { *np=*p; ++np; ++p; } */
	while (*p && *p != '"' && *p != '>' && !(o == 0 && o2 == 1 && *p == ':')) {
		*np = *p; ++np; ++p;
	}
	if (*p && o == 1) {
		if (*p == '"') {
			++p;
		} else {
			Error("No closing '\"'", 0);
		}
	} else if (*p && o == 2 && *p != '>') {
		Error("No closing '>'", 0);
	} else if (*p) {
		++p;
	}
	*np = 0; 
	for (np = fn; *np; ++np) {
#ifdef WIN32
		if (*np == '/') {
			*np = '\\';
		}
#else
		if (*np == '\\') {
			*np = '/';
		}
#endif
	}
	return fn;
}

/* added */
char* GetHobetaFileName(char*& p) {
	int o = 0;
	int o2 = 0;
	char* fn, * np;
	np = fn = new char[LINEMAX];
	if (np == NULL) {
		Error("No enough memory!", 0, FATAL);
	}
	*fn = 0;
	SkipBlanks(p);
	if (!(*p)) {
		return fn;
	}
	if (*p == '"') {
		o = 1; ++p;
	} else if (*p == '<') {
		o = 2; ++p;
	}
	if (*p && strstr(p, ":")) {
		o2 = 1;
	} /* added */
	while (*p && !White() && *p != '"' && *p != '>' && !(o == 0 && o2 == 1 && *p == ':')) {
		*np = *p; ++np; ++p;
	}
	if (*p && o == 1) {
		if (*p == '"') {
			++p;
		} else {
			Error("No closing '\"'", 0);
		}
	} else if (*p && o == 2 && *p != '>') {
		Error("No closing '>'", 0);
	} else if (*p) {
		++p;
	}
	*np = 0; 
	return fn;
}

int needcomma(char*& p) {
	SkipBlanks(p);
	if (*p != ',') {
		Error("Comma expected", 0);
	}
	return (*(p++) == ',');
}

int needbparen(char*& p) {
	SkipBlanks(p);
	if (*p != ']') {
		Error("']' expected", 0);
	}
	return (*(p++) == ']');
}

int islabchar(char p) {
	if (isalnum((unsigned char)p) || p == '_' || p == '.' || p == '?' || p == '!' || p == '#' || p == '@') {
		return 1;
	}
	return 0;
}

EStructureMembers GetStructMemberId(char*& p) {
	if (*p == '#') {
		++p; if (*p == '#') {
			 	++p; return SMEMBALIGN;
			 } return SMEMBBLOCK;
	}
	//  if (*p=='.') ++p;
	switch (*p * 2 + *(p + 1)) {
	case 'b'*2+'y':
	case 'B'*2+'Y':
		if (cmphstr(p, "byte")) {
			return SMEMBBYTE;
		} break;
	case 'w'*2+'o':
	case 'W'*2+'O':
		if (cmphstr(p, "word")) {
			return SMEMBWORD;
		} break;
	case 'b'*2+'l':
	case 'B'*2+'L':
		if (cmphstr(p, "block")) {
			return SMEMBBLOCK;
		} break;
	case 'd'*2+'b':
	case 'D'*2+'B':
		if (cmphstr(p, "db")) {
			return SMEMBBYTE;
		} break;
	case 'd'*2+'w':
	case 'D'*2+'W':
		if (cmphstr(p, "dw")) {
			return SMEMBWORD;
		}
		if (cmphstr(p, "dword")) {
			return SMEMBDWORD;
		}
		break;
	case 'd'*2+'s':
	case 'D'*2+'S':
		if (cmphstr(p, "ds")) {
			return SMEMBBLOCK;
		} break;
	case 'd'*2+'d':
	case 'D'*2+'D':
		if (cmphstr(p, "dd")) {
			return SMEMBDWORD;
		} break;
	case 'a'*2+'l':
	case 'A'*2+'L':
		if (cmphstr(p, "align")) {
			return SMEMBALIGN;
		} break;
	case 'd'*2+'e':
	case 'D'*2+'E':
		if (cmphstr(p, "defs")) {
			return SMEMBBLOCK;
		}
		if (cmphstr(p, "defb")) {
			return SMEMBBYTE;
		}
		if (cmphstr(p, "defw")) {
			return SMEMBWORD;
		}
		if (cmphstr(p, "defd")) {
			return SMEMBDWORD;
		}
		break;
	case 'd'*2+'2':
	case 'D'*2+'2':
		if (cmphstr(p, "d24")) {
			return SMEMBD24;
		}
		break;
	default:
		break;
	}
	return SMEMBUNKNOWN;
}

/* added */
int getArray(char*& p, int e[], int add, int dc) {
	aint val;
	int t = 0;
	while ('o') {
		SkipBlanks(p);
		if (!*p) {
			Error("Expression expected", 0, SUPPRESS); break;
		}
		if (t == 128) {
			Error("Too many arguments", p, SUPPRESS); break;
		}
		if (*p == '"') {
			p++;
			do {
				if (!*p || *p == '"') {
					Error("Syntax error", p, SUPPRESS); e[t] = -1; return t;
				}
				if (t == 128) {
					Error("Too many arguments", p, SUPPRESS); e[t] = -1; return t;
				}
				GetCharConstChar(p, val); check8(val); e[t++] = (val + add) & 255;
			} while (*p != '"');
			++p; if (dc && t) {
				 	e[t - 1] |= 128;
				 }
			/* (begin add) */
		} else if (*p == 0x27) {
		  	p++;
			do {
				if (!*p || *p == 0x27) {
					Error("Syntax error", p, SUPPRESS); e[t] = -1; return t;
				}
				if (t == 128) {
		  			Error("Too many arguments", p, SUPPRESS); e[t] = -1; return t;
				}
		  		GetCharConstCharSingle(p, val); check8(val); e[t++] = (val + add) & 255;
			} while (*p != 0x27);
		  	++p; if (dc && t) {
				 	e[t - 1] |= 128;
				 }
		  	/* (end add) */
		} else {
			if (ParseExpression(p, val)) {
				check8(val); e[t++] = (val + add) & 255;
			} else {
				Error("Syntax error", p, SUPPRESS); break;
			}
		}
		SkipBlanks(p); if (*p != ',') {
					   	break;
					   } ++p;
	}
	e[t] = -1; return t;
}

//eof reader.cpp
