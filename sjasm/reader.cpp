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

int cmphstr(char*& p1, const char* p2) {
	unsigned int i = 0;
	if (isupper(*p1)) {
		while (p2[i]) {
			if (p1[i] != toupper(p2[i])) return 0;
			++i;
		}
	} else {
		while (p2[i]) {
			if (p1[i] != p2[i]) return 0;
			++i;
		}
	}
	if (' ' < p1[i]) return 0;		// any character above space means "no match"
	// space, tab, enter, \0, ... => "match"
	p1 += i;
	return 1;
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

void SkipParam(char*& p) {
	SkipBlanks(p);
	if (!(*p)) {
		return;
	}
	while (((*p) != '\0') && ((*p) != ',')) {
		p++;
	}
}

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

int NeedDEFL() {
	char* olp = lp;
	SkipBlanks();
	if (*lp == '=') {
		++lp;
		return 1;
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
	if (*p != ',') return 0;
	++p;
	return 1;
}

static const char brackets_b[] = BRACKETS_B;
static const char brackets_e[] = BRACKETS_E;
static int expectedAddressClosingBracket = -1;

// memory-address bracket opener (only "(" and "[" types supported)
EBracketType OpenBracket(char*& p) {
	SkipBlanks(p);
	for (const EBracketType bt : {BT_ROUND, BT_SQUARE}) {
		if (brackets_b[bt] == *p) {
			expectedAddressClosingBracket = brackets_e[bt];
			++p;
			return bt;
		}
	}
	expectedAddressClosingBracket = -1;
	return BT_NONE;
}

int CloseBracket(char*& p) {
	SkipBlanks(p);
	if (*p != expectedAddressClosingBracket) return 0;
	expectedAddressClosingBracket = -1;
	++p;
	return 1;
}

int cpc = '4';

/* not modified */
int oparenOLD(char*& p, char c) {
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

int cparenOLD(char*& p) {
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

char nidtemp[LINEMAX];

char* GetID(char*& p) {
	/*char nid[LINEMAX],*/ char* np;
	np = nidtemp;
	SkipBlanks(p);
	//if (!isalpha(*p) && *p!='_') return 0;
	if (*p && !isalpha((unsigned char) * p) && *p != '_' && *p != '.') {
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

char instrtemp[LINEMAX];

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

int check8(aint val, bool error) {
	if ((val < -256 || val > 255) && error) {
		char buffer[32];
		sprintf(buffer, "Bytes lost (0x%lX)", val);
		Warning(buffer);
		return 0;
	}
	return 1;
}

int check8o(long val) {
	if (val < -128 || val > 127) {
		char buffer[32];
		sprintf(buffer,"Offset out of range (%+li)", val);
		Error(buffer);
		return 0;
	}
	return 1;
}

int check16(aint val, bool error) {
	if ((val < -65536 || val > 65535) && error) {
		char buffer[32];
		sprintf(buffer, "Bytes lost (0x%lX)", val);
		Warning(buffer);
		return 0;
	}
	return 1;
}

int check24(aint val, bool error) {
	if ((val < -16777216 || val > 16777215) && error) {
		char buffer[32];
		sprintf(buffer, "Bytes lost (0x%lX)", val);
		Warning(buffer);
		return 0;
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

int needa(char*& p, const char* c1, int r1, const char* c2, int r2, const char* c3, int r3) {
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

int need(char*& p, const char* c) {
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

	SkipBlanks(p);

	p3 = p;
	val = 0;

	switch (*p) {
	case '#':
	case '$':
		++p;
		while (isalnum((unsigned char) * p)) {
			if ((v = getval(*p)) >= 16) {
				Error("Digit not in base", op);
				return 0;
			}
			oval = val;
			val = val * 16 + v;
			++p;
			if (oval > val) {
				Error("Overflow", op, SUPPRESS);
			}
		}

		if (p - p3 < 2) {
			Error("Syntax error", op, IF_FIRST);
			return 0;
		}

		op = p;

		return 1;
	case '%':
		++p;
		while (isdigit((unsigned char) * p)) {
			if ((v = getval(*p)) >= 2) {
				Error("Digit not in base", op);
				return 0;
			}
			oval = val; val = val * 2 + v; ++p;
			if (oval > val) {
				Error("Overflow", op, SUPPRESS);
			}
		}
		if (p - p3 < 2) {
			Error("Syntax error", op, IF_FIRST);
			return 0;
		}

		op = p;

		return 1;
	case '0':
		++p;
		if (*p == 'x' || *p == 'X') {	//FIXME Ped7g simplify this function..
			++p;
			while (isalnum((unsigned char) * p)) {
				if ((v = getval(*p)) >= 16) {
					Error("Digit not in base", op);
					return 0;
				}
				oval = val; val = val * 16 + v; ++p;
				if (oval > val) {
					Error("Overflow", op, SUPPRESS);
				}
			}
			if (p - p3 < 3) {
				Error("Syntax error", op, IF_FIRST);
				return 0;
			}

			op = p;

			return 1;
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
									   	Error("Overflow", op, SUPPRESS);
									   }
			pb *= base;
		} while (p-- != p3);

		op = p2;

		return 1;
	}
}

// parse single character of double-quoted string (backslash does escape characters)
int GetCharConstInDoubleQuotes(char*& op, aint& val) {
	if ('"' == *op || !*op) return 0;		// closing quotes or no more characters, return 0
	if ((val = *op++) != '\\') return 1;	// un-escaped character, just return it
	switch (val = *op++) {
	case '\\':
	case '\'':
	case '\"':
	case '\?':
		return 1;
	case '0':
		val = 0;
		return 1;
	case 'n':
	case 'N':
		val = 10;
		return 1;
	case 't':
	case 'T':
		val = 9;
		return 1;
	case 'v':
	case 'V':
		val = 11;
		return 1;
	case 'b':
	case 'B':
		val = 8;
		return 1;
	case 'r':
	case 'R':
		val = 13;
		return 1;
	case 'f':
	case 'F':
		val = 12;
		return 1;
	case 'a':
	case 'A':
		val = 7;
		return 1;
	case 'e':
	case 'E':
		val = 27;
		return 1;
	case 'd':
	case 'D':
		val = 127;
		return 1;
	default:
		break;
	}
	// keep "val" equal to the second character
	Error("Unknown escape", op-2);
	return 1;
}

// parse single character of apostrophe-quoted string (no escaping, double '' is apostrophe itself)
int GetCharConstInApostrophes(char*& op, aint& val) {
	if ('\'' == op[0] && '\'' == op[1]) {	// '' converts to actual apostrophe as value
		val = '\'';
		op += 2;
		return 1;
	}
	if ('\'' == *op || !*op) return 0;		// closing apostrophe or no more characters, return 0
	// normal character, just return it
	val = *op++;
	return 1;
}

// parse single/double quoted string literal as single value ('012' == 0x00303132)
int GetCharConst(char*& p, aint& val) {
	// check if string starts here
	if ('"' != *p && '\'' != *p) return 0;
	const char * const op = p;		// for error reporting
	const bool quotes = '"' == *p++;
	aint singleCharVal, bytes = 0;
	val = 0;
	// read through whole string and keep calculating value (may overflow if more than 4 bytes)
	while (quotes ? GetCharConstInDoubleQuotes(p, singleCharVal) : GetCharConstInApostrophes(p, singleCharVal)) {
		val = (val << 8) + singleCharVal;
		++bytes;
	}
	if ((quotes ? '"' : '\'') != *p) {
		Error("String is not closed", op);
		return 0;
	}
	if (0 == bytes) {
		Warning("Empty string literal converted to value 0!", op);
	} else if (4 < bytes) {
		val &= (1UL<<32)-1UL;		// make sure it's 32b truncated even on 64b platforms
		*p = 0;						// shorten the string literal for warning display
		char buffer[128];
		sprintf(buffer, "String literal truncated to 0x%lX", val);
		Warning(buffer, op+1);
		*p = quotes ? '"' : '\'';	// restore it
	}
	++p;
	return 1;
}

int GetBytes(char*& p, int e[], int add, int dc) {
	aint val;
	int t = 0;
	do {
		SkipBlanks(p);
		if (!*p) {
			Error("Expression expected", NULL, SUPPRESS);
		} else if ('"' == *p || '\'' == *p) {	// string literals (both types)
			const bool quotes = '"' == *p++;
			const int oldT = t;
			while (t < 128 && (quotes ? GetCharConstInDoubleQuotes(p, val) : GetCharConstInApostrophes(p, val))) {
				e[t++] = (val + add) & 255;
			}
			if ((quotes ? '"' : '\'') != *p) {	// too many/invalid arguments or zero-terminator can lead to this
				if (!*p) Error("Syntax error", p, SUPPRESS);
				break;
			}
			++p;
			if (oldT == t)	Warning("Empty string", p-2);
			else {
				// single byte "strings" may have further part of expression, handle it *here* :/
				if (1 == t - oldT) {
					SkipBlanks(p);
					if (*p && ',' != *p) {
						ParseExpression(p, val);
						val += (e[t - 1] - add) & 255;	// restore "char" value back and add to expr.
						check8(val);
						e[t-1] = (val + add) & 255;
					}
				}
				// mark last "string" byte with |128: single char in "" *is* string
				// but single char in '' *is not* (!) (no |128 then) => a bit complex condition :)
				if (dc && ((!quotes) < (t - oldT))) e[t - 1] |= 128;
			}
		} else {
			if (ParseExpression(p, val)) {
				check8(val);
				e[t++] = (val + add) & 255;
			} else {
				Error("Syntax error", p, SUPPRESS);
				break;
			}
		}
	} while(comma(p) && t < 128);
	e[t] = -1;
	if (t == 128 && *p) Error("Too many arguments", p, SUPPRESS);
	return t;
}

#if defined(WIN32)
static const char badSlash = '/';
static const char goodSlash = '\\';
#else
static const char badSlash = '\\';
static const char goodSlash = '/';
#endif

static EDelimiterType delimiterOfLastFileName = DT_NONE;
static const char delimiters_b[] = DELIMITERS_B;
static const char delimiters_e[] = DELIMITERS_E;

char* GetFileName(char*& p, bool convertslashes) {
	char* newFn = new char[LINEMAX];
	if (NULL == newFn) ErrorInt("No enough memory!", LINEMAX, FATAL);
	char* result = newFn;
	// find first non-blank character
	SkipBlanks(p);
	// check if some and which delimiter is used for this filename
	int delI = DT_COUNT;
	while (delI-- && (delimiters_b[delI] != *p)) ;
	if (delI < 0) delI = 0;	// no delimiter found, use default "space" for end
	else ++p;				// if found, advance over it
	// remember type of detected delimiter (for GetDelimiterOfLastFileName function)
	delimiterOfLastFileName = static_cast<EDelimiterType>(delI);
	const char deliE = delimiters_e[delI];	// expected ending delimiter
	// copy all characters until zero or delimiter-end character is reached
	while (*p && deliE != *p) {
		*newFn = *p;		// copy character
		if (convertslashes && badSlash == *newFn) *newFn = goodSlash;	// convert slashes if enabled
		++newFn, ++p;
		if (LINEMAX <= newFn-result) Error("Filename too long!", NULL, FATAL);
	}
	*newFn = 0;				// add string terminator at end of file name
	// verify + skip end-delimiter (if other than space)
	if (' ' != deliE) {
		if (deliE == *p) {
			++p;
		} else {
			const char delimiterTxt[2] = { deliE, 0 };
			Error("No closing delimiter", delimiterTxt, EARLY);
		}
	}
	SkipBlanks(p);			// skip blanks any way
	return result;
}

EDelimiterType GetDelimiterOfLastFileName() {
	// DT_NONE if no GetFileName was called
	return delimiterOfLastFileName;
}

int needcomma(char*& p) {
	SkipBlanks(p);
	if (*p != ',') {
		Error("Comma expected");
	}
	return (*(p++) == ',');
}

int needbparen(char*& p) {
	SkipBlanks(p);
	if (*p != ']') {
		Error("']' expected");
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

int GetArray(char*& p, int e[], int add, int dc) {
	aint val;
	int t = 0;
	while ('o') {
		SkipBlanks(p);
		if (!*p) {
			Error("Expression expected", NULL, SUPPRESS); break;
		}
		if (t == 128) {
			Error("Too many arguments", p, SUPPRESS); break;
		}
		if (*p == '"') {	//FIXME Ped7g simplify as GetBytes is done (or merge code!)
			p++;
			do {
				if (!*p || *p == '"') {
					Error("Syntax error", p, SUPPRESS); e[t] = -1; return t;
				}
				if (t == 128) {
					Error("Too many arguments", p, SUPPRESS); e[t] = -1; return t;
				}
				GetCharConstInDoubleQuotes(p, val); check8(val); e[t++] = (val + add) & 255;
			} while (*p != '"');
			++p; if (dc && t) {
				 	e[t - 1] |= 128;
				 }
		} else if ((*p == '\'') && (!*(p+2) || *(p+2) != '\'')) {
		  	p++;
			do {
				if (!*p || *p == '\'') {
					Error("Syntax error", p, SUPPRESS); e[t] = -1; return t;
				}
				if (t == 128) {
		  			Error("Too many arguments", p, SUPPRESS); e[t] = -1; return t;
				}
		  		GetCharConstInApostrophes(p, val); check8(val); e[t++] = (val + add) & 255;
			} while (*p != '\'');
		  	++p;
			if (dc && t) {
				 e[t - 1] |= 128;
			}
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

int GetMacroArgumentValue(char* & src, char* & dst, bool lastArg) {
	SkipBlanks(src);
	if (!*src) return 0;

	int delI = DT_COUNT;
	while (--delI && (delimiters_b[delI] != *src)) ;
	if (delI) {
		if (DT_ANGLE != delI) *dst++ = *src;	// quotes are part of parsed value, angles are NOT
		++src;									// advance over delimiter
	}
	const char endCh = delI ? delimiters_e[delI] : ',';	// set expected ending delimiter

	while (*src) {
		// handle escape sequences by the type of delimiter
		switch (delI) {
		case DT_ANGLE:
			if (('!' == *src && '!' == src[1]) || ('!' == *src && '>' == src[1])) {
				*dst++ = src[1]; src += 2;				// escape sequence is converted into final char
				continue;
			}
			break;
		case DT_QUOTES:
			if ('\\' == *src && src[1]) {
				*dst++ = *src++;	*dst++ = *src++;	// copy escape + escaped char (*any* non zero char)
				continue;
			}
			break;
		case DT_APOSTROPHE:
			if ('\'' == *src && '\'' == src[1]) {
				*dst++ = *src++;	*dst++ = *src++;	// copy two apostrophes (escaped apostrophe)
				continue;
			}
			break;
		default:
			break;
		}
		if (endCh == *src) break;				// ending delimiter found
		*dst++ = *src++;						// just copy character
	}

	// ending delimiter must be identical to endCh, except last argument may end with \0 in DT_NONE
	if (endCh != *src && delI != DT_NONE && !lastArg) return 0;
	// set ending delimiter for quotes and apostrophe (angles and commas are stripped from value)
	if (DT_QUOTES == delI || DT_APOSTROPHE == delI) *dst++ = endCh;
	if (delI) ++src;							// advance over delimiter (except DT_NONE=comma)
	*dst = 0;									// zero terminator of resulting string value
	return 1;
}

//eof reader.cpp
