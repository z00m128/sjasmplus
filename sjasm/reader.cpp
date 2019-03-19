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
	if (p1[i] && !White(p1[i])) return 0;		// any character above space means "no match"
	// space, tab, enter, \0, ... => "match"
	p1 += i;
	return 1;
}

bool White(const char c) {
	return c && (c&255) <= ' ';
}

bool White() {
	return White(*lp);
}

int SkipBlanks(char*& p) {
	while (White(*p)) ++p;
	return (*p == 0);
}

int SkipBlanks() {
	return SkipBlanks(lp);
}

void SkipParam(char*& p) {
	while (*p && (*p != ',')) ++p;
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

//enum EBracketType          { BT_NONE, BT_ROUND, BT_CURLY, BT_SQUARE, BT_COUNT };
static const char brackets_b[] = { 0,      '(',      '{',      '[',       0 };
static const char brackets_e[] = { 0,      ')',      '}',      ']',       0 };
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
		sprintf(buffer, "Bytes lost (0x%lX)", val&0xFFFFFFFFUL);
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
		sprintf(buffer, "Bytes lost (0x%lX)", val&0xFFFFFFFFUL);
		Warning(buffer);
		return 0;
	}
	return 1;
}

int check24(aint val, bool error) {
	if ((val < -16777216 || val > 16777215) && error) {
		char buffer[32];
		sprintf(buffer, "Bytes lost (0x%lX)", val&0xFFFFFFFFUL);
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

// parses number literals, forces result to be confined into 32b (even on 64b platforms,
// to have stable results in listings/tests across platforms).
int GetConstant(char*& op, aint& val) {
#ifndef NDEBUG
	// the input string has been already detected as numeric literal by ParseExpPrim (assert)
	if (!isdigit(*op) && '#' != *op && '$' != *op && '%' != *op) ExitASM(32);
#endif
	// check if the format is defined by prefix (#, $, %, 0x, 0X)
	char* p = op;
	int shiftBase = 0, base = 0;
	if ('#' == *p || '$' == *p) {
		shiftBase = 4;
		++p;
	} else if ('0' == p[0] && 'x' == (p[1]|0x20)) {
		shiftBase = 4;
		p += 2;
	} else if ('%' == *p) {
		shiftBase = 1;
		++p;
	}
	// find end of the numeric literal (pointer is beyond last alfa/digit character
	char* pend = p;
	while (isalnum(*pend)) ++pend;
	char* const hardEnd = pend;
	// if the base is still undecided, check for suffix format specifier
	if (0 == shiftBase) {
		switch (pend[-1]|0x20) {
			case 'h': --pend; shiftBase = 4;  break;
			case 'q': --pend; shiftBase = 3;  break;
			case 'o': --pend; shiftBase = 3;  break;
			case 'b': --pend; shiftBase = 1;  break;
			case 'd': --pend;      base = 10; break;
			default:
				base = 10;
				break;
		}
	}
	// parse the number into value
	val = 0;
	if (pend <= p) {		// no actual digits between format specifiers
		Error("Syntax error", op, SUPPRESS);
		return 0;
	}
	aint digit;
	if (0 < shiftBase) {
		base = 1<<shiftBase;
		const aint overflowMask = (~0UL)<<(32-shiftBase);
		while (p < pend) {
			if (base <= (digit = getval(*p))) {
				Error("Digit not in base", op, SUPPRESS);
				val &= 0xFFFFFFFFUL;
				return 0;
			}
			if (val & overflowMask) Error("Overflow", op, SUPPRESS);
			val = (val<<shiftBase) + digit;
			++p;
		}
	} else {
		while (p < pend) {
			if (base <= (digit = getval(*p))) {
				Error("Digit not in base", op, SUPPRESS);
				val &= 0xFFFFFFFFUL;
				return 0;
			}
			const unsigned long oval = static_cast<unsigned long>(val)&0xFFFFFFFFUL;
			val = (val * base) + digit;
			if (static_cast<unsigned long>(val&0xFFFFFFFFUL) < oval) Error("Overflow", op, SUPPRESS);
			++p;
		}
	}
	op = hardEnd;
	val &= 0xFFFFFFFFUL;
	return 1;
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
	const char * const op = p;		// for error reporting
	char buffer[128];
	int bytes = 0, strRes;
	if (!(strRes = GetCharConstAsString(p, buffer, bytes))) return 0;		// no string detected
	val = 0;
	if (-1 == strRes) return 0;		// some syntax/max_size error happened
	for (int ii = 0; ii < bytes; ++ii) val = (val << 8) + (255&buffer[ii]);
	if (0 == bytes) {
		Warning("Empty string literal converted to value 0!", op);
	} else if (4 < bytes) {
		val &= 0xFFFFFFFFUL;		// make sure it's 32b truncated even on 64b platforms
		const char oldCh = *p;
		*p = 0;						// shorten the string literal for warning display
		sprintf(buffer, "String literal truncated to 0x%lX", val);
		Warning(buffer, op);
		*p = oldCh;					// restore it
	}
	return 1;
}

// returns (adjusts also "p" and "ei", and fills "e"):
//  -1 = syntax error (or buffer full)
//   0 = no string literal detected at p[0]
//   1 = string literal in single quotes (apostrophe)
//   2 = string literal in double quotes (")
template <class strT> int GetCharConstAsString(char* & p, strT e[], int & ei, int max_ei, int add) {
	if ('"' != *p && '\'' != *p) return 0;
	const char* const elementP = p;
	const bool quotes = ('"' == *p++);
	aint val;
	while (ei < max_ei && (quotes ? GetCharConstInDoubleQuotes(p, val) : GetCharConstInApostrophes(p, val))) {
		e[ei++] = (val + add) & 255;
	}
	if ((quotes ? '"' : '\'') != *p) {	// too many/invalid arguments or zero-terminator can lead to this
		if (!*p) Error("Syntax error", elementP, SUPPRESS);
		return -1;
	}
	++p;
	return 1 + quotes;
}

// make sure both specialized instances for `char` and `int` are available for whole app
template int GetCharConstAsString<char>(char* & p, char e[], int & ei, int max_ei, int add);
template int GetCharConstAsString<int>(char* & p, int e[], int & ei, int max_ei, int add);

int GetBytes(char*& p, int e[], int add, int dc) {
	aint val;
	int t = 0, strRes;
	do {
		const int oldT = t;
		if (SkipBlanks(p)) {
			Error("Expression expected", NULL, SUPPRESS);
		} else if (0 != (strRes = GetCharConstAsString(p, e, t, 128, add))) {
			// string literal parsed (both types)
			if (-1 == strRes) break;
			if (oldT == t) Warning("Empty string", p-2);
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
				if (dc && ((1 == strRes) < (t - oldT))) e[t - 1] |= 128;
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
//enum EDelimiterType          { DT_NONE, DT_QUOTES, DT_APOSTROPHE, DT_ANGLE, DT_COUNT };
static const char delimiters_b[] = { ' ',    '"',       '\'',          '<',      0 };
static const char delimiters_e[] = { ' ',    '"',       '\'',          '>',      0 };

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

int GetMacroArgumentValue(char* & src, char* & dst) {
	SkipBlanks(src);
	const char* const dstOrig = dst, * const srcOrig = src;
	while (*src && ',' != *src) {
		// check if there is some kind of delimiter next (string literal or angle brackets expression)
		int delI = DT_COUNT;
		while (--delI && (delimiters_b[delI] != *src)) ;
		if (!delI) {				// no delimiter found, ordinary expression, copy char by char
			*dst++ = *src++;
			continue;
		}
		// some delimiter found - parse those properly by their type
		if (DT_ANGLE != delI) *dst++ = *src;	// quotes are part of parsed value, angles are NOT
		++src;									// advance over delimiter
		const char endCh = delimiters_e[delI];	// set expected ending delimiter
		while (*src) {
			// handle escape sequences by the type of delimiter
			switch (delI) {
			case DT_ANGLE:
				if (('!' == *src && '!' == src[1]) || ('!' == *src && '>' == src[1])) {
					*dst++ = src[1]; src += 2;	// escape sequence is converted into final char
					continue;
				}
				break;
			case DT_QUOTES:
				if ('\\' == *src && src[1]) {
					*dst++ = *src++;	*dst++ = *src++;
					continue;					// copy escape + escaped char (*any* non zero char)
				}
				break;
			case DT_APOSTROPHE:
				if ('\'' == *src && '\'' == src[1]) {
					*dst++ = *src++;	*dst++ = *src++;
					continue;					// copy two apostrophes (escaped apostrophe)
				}
				break;
			}
			if (endCh == *src) break;			// ending delimiter found
			*dst++ = *src++;					// just copy character
		}
		// ending delimiter must be identical to endCh
		if (endCh != *src) return 0;
		// set ending delimiter for quotes and apostrophe (angles are stripped from value)
		if (DT_QUOTES == delI || DT_APOSTROPHE == delI) *dst++ = endCh;
		++src;									// advance over delimiter
	}
	*dst = 0;									// zero terminator of resulting string value
	int returnValue = *dstOrig || ',' == *src;	// return 1 if value is not empty or comma follows
	if (!*dstOrig && returnValue) Warning("[Macro argument parser] empty value", srcOrig);
	return (returnValue);		// but empty value will at least display warning
}

//eof reader.cpp
