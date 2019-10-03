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
#include <cassert>

//enum EDelimiterType          { DT_NONE, DT_QUOTES, DT_APOSTROPHE, DT_ANGLE, DT_COUNT };
static const char delimiters_b[] = { ' ',    '"',       '\'',          '<',      0 };
static const char delimiters_e[] = { ' ',    '"',       '\'',          '>',      0 };
static const std::array<EDelimiterType, 3> delimiters_all = {DT_QUOTES, DT_APOSTROPHE, DT_ANGLE};
static const std::array<EDelimiterType, 3> delimiters_noAngle = {DT_QUOTES, DT_APOSTROPHE, DT_COUNT};

int cmphstr(char*& p1, const char* p2) {
	unsigned int i = 0;
	if (isupper((byte)*p1)) {
		while (p2[i]) {
			if (p1[i] != toupper((byte)p2[i])) return 0;
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

void SkipToEol(char*& p) {
	while (*p) ++p;
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

bool NeedIoC() {
	SkipBlanks();
	if ('(' != lp[0] || 'c' != tolower((byte)lp[1]) || ')' != lp[2]) return false;
	lp += 3;
	return true;
}

bool isMacroNext() {	// checks if ".macro" directive is ahead (but doesn't consume it)
	if (SkipBlanks()) return false;
	char* p = lp;
	if ('.' == *p) ++p;
	return cmphstr(p, "macro");
}

bool anyComma(char*& p) {
	SkipBlanks(p);
	if (*p != ',') return false;
	++p;
	return true;
}

bool comma(char*& p) {
	SkipBlanks(p);
	if (',' != p[0] || ',' == p[1]) return false;	// detect double-comma as FALSE state
	++p;
	return true;
}

bool doubleComma(char* & p) {
	SkipBlanks(p);
	if (',' != p[0] || ',' != p[1]) return false;
	p += 2;
	return true;
}

bool nonMaComma(char* & p) {
	if (Options::syx.isMultiArgPlainComma()) return false;	// comma is also multi-arg => FALSE here
	return comma(p);
}

//enum EBracketType          { BT_NONE, BT_ROUND, BT_CURLY, BT_SQUARE, BT_COUNT };
static const char brackets_b[] = { 0,      '(',      '{',      '[',       0 };
static const char brackets_e[] = { 0,      ')',      '}',      ']',       0 };
static int expectedAddressClosingBracket = -1;

// memory-address bracket opener (only "(" and "[" types supported)
EBracketType OpenBracket(char*& p) {
	SkipBlanks(p);
	if (2 == Options::syx.MemoryBrackets && brackets_b[BT_ROUND] == *p) return BT_NONE;		// disabled "()"
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

char* ParenthesesEnd(char* p) {
	int depth = 0;	char pc;
	if (SkipBlanks(p) || '(' != *p) return nullptr;
	while (0 != (pc = *p++)) {
		if ('(' == pc) ++depth;
		else if (')' == pc && 0 == --depth) {
			SkipBlanks(p);
			return p;
		}
	}
	return nullptr;
}

char nidtemp[LINEMAX], *nidsubp = nidtemp;

//TODO v2.x: review GetID usage and make it more clear where are which characters legal
// add GetLabel where appropriate, handle "@" + "." modifiers more consistently and transparently)
char* GetID(char*& p) {
	char* np = nidtemp;
	if (SkipBlanks(p) || (!isLabelStart(p, false) && *p != '.')) return NULL;
	while (islabchar((byte)*p)) *np++ = *p++;
	*np = 0;
	return nidtemp;
}

void ResetGrowSubId() {
	nidsubp = nidtemp;			// reset temporary ID, starting new one
	*nidsubp = 0;
}

char* GrowSubId(char* & p) {	// appends next part of ID
	// The caller function ReplaceDefineInternal already assures the first char of ID is (isalpha() || '_')
	// so there are no extra tests here to verify validity of first character (like GetID(..) must do)
	if ('_' == *p) {
		// add sub-parts delimiter in separate step (i.e. new ID grows like: "a", "a_", "a_b", ...
		while ('_' == *p) *nidsubp++ = *p++;
	} else while (*p && (isalnum((byte)*p) || '.' == *p || '?' == *p || '!' == *p || '#' == *p || '@' == *p)) {
		// add sub-part of id till next underscore
		*nidsubp++ = *p++;
	}
	if (nidtemp+LINEMAX <= nidsubp) Error("ID too long, buffer overflow detected.", NULL, FATAL);
	*nidsubp = 0;
	if (!nidtemp[0]) return NULL;	// result is empty string, return NULL rather
	return nidtemp;
}

char* GrowSubIdByExtraChar(char* & p) {	// append the next char even if not a legal label/ID char
	// the caller function is responsible for all the validation, this just adds single char
	*nidsubp++ = *p++;
	if (nidtemp+LINEMAX <= nidsubp) Error("ID too long, buffer overflow detected.", NULL, FATAL);
	*nidsubp = 0;
	if (!nidtemp[0]) return NULL;	// result is empty string, return NULL rather
	return nidtemp;
}

char instrtemp[LINEMAX];

char* getinstr(char*& p) {
	char* np = instrtemp;
	SkipBlanks(p);
	if (!isalpha((byte)*p) && *p != '.') {
		return 0;
	} else {
		*np = *p; ++p; ++np;
	}
	while (*p) {
		if (!isalnum((byte)*p) && *p != '_') {
			break;
		} /////////////////////////////////////
		*np = *p; ++p; ++np;
	}
	*np = 0;
	if (!Options::syx.CaseInsensitiveInstructions) return instrtemp;
	// lowercase the retrieved "instruction" string when option "--syntax=i" is used
	while (instrtemp <= --np) {
		*np = tolower((byte)*np);
	}
	return instrtemp;
}

int check8(aint val) {
	if (val < -256 || val > 255) {
		char buffer[64];
		sprintf(buffer, "value 0x%X is truncated to 8bit value: 0x%02X", val, val&0xFF);
		Warning(buffer);
		return 0;
	}
	return 1;
}

int check8o(aint val)
{
	if (val < -128 || val > 127) {
		char buffer[32];
		sprintf(buffer,"Offset out of range (%+i)", val);
		Error(buffer, nullptr, IF_FIRST);
		return 0;
	}
	return 1;
}

int check16(aint val) {
	if (val < -65536 || val > 65535) {
		char buffer[64];
		sprintf(buffer, "value 0x%X is truncated to 16bit value: 0x%04X", val, val&0xFFFF);
		Warning(buffer);
		return 0;
	}
	return 1;
}

int check24(aint val) {
	if (val < -16777216 || val > 16777215) {
		char buffer[64];
		sprintf(buffer, "value 0x%X is truncated to 24bit value: 0x%06X", val, val&0xFFFFFF);
		Warning(buffer);
		return 0;
	}
	return 1;
}

void checkLowMemory(byte hiByte, byte lowByte) {
	if (hiByte || !warningNotSuppressed() || !Options::syx.IsLowMemWarningEnabled) {
		return;			// address is >= 256 or warning is suppressed
	}
	// for addresses 0..255 issue warning
	char buf[64];
	SPRINTF1(buf, 64, "Accessing low memory address 0x%04X, is it ok?", lowByte);
	Warning(buf, bp);
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
	if (!isalpha((byte)*p)) {
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
	assert(('0' <= p && p <= '9') || ('A' <= p && p <= 'Z') || ('a' <= p && p <= 'z'));
	if (p <= '9') return p - '0';
	return (p|0x20) - 'a' + 10;
}

const char* getNumericValueLastErr = NULL;
const char* const getNumericValueErr_syntax = "Syntax error";
const char* const getNumericValueErr_digit = "Digit not in base";
const char* const getNumericValueErr_no_digit = "Missing next digit";
const char* const getNumericValueErr_overflow = "Overflow";

bool GetNumericValue_ProcessLastError(const char* const srcLine) {
	if (NULL == getNumericValueLastErr) return false;
	Error(getNumericValueLastErr, srcLine, SUPPRESS);
	// Overflow type error lets assembler to emit truncated machine code (return "false" here)
	return (getNumericValueErr_overflow != getNumericValueLastErr);
}

bool GetNumericValue_TwoBased(char*& p, const char* const pend, aint& val, const int shiftBase) {
	if (shiftBase < 1 || 5 < shiftBase) Error("Internal error, wrong base", NULL, FATAL);
	getNumericValueLastErr = NULL;
	val = 0;
	if (pend <= p) {		// no actual digits between format specifiers
		getNumericValueLastErr = getNumericValueErr_syntax;
		return false;
	}
	aint digit;
	const int base = 1<<shiftBase;
	const aint overflowMask = (~0L)<<(32-shiftBase);
	while (p < pend) {
		const byte charDigit = *p++;
		if ('\'' == charDigit && isalnum((byte)*p)) continue;
		if (0 == charDigit || !isalnum(charDigit)) {
			getNumericValueLastErr = getNumericValueErr_no_digit;
			break;
		}
		if (base <= (digit = getval(charDigit))) {
			getNumericValueLastErr = getNumericValueErr_digit;
			break;
		}
		if (val & overflowMask) getNumericValueLastErr = getNumericValueErr_overflow;
		val = (val<<shiftBase) + digit;
	}
	return (NULL == getNumericValueLastErr);
}

bool GetNumericValue_IntBased(char*& p, const char* const pend, aint& val, const int base) {
	if (base < 2 || 36 < base) Error("Internal error, wrong base", NULL, FATAL);
	getNumericValueLastErr = NULL;
	val = 0;
	if (pend <= p) {		// no actual digits between format specifiers
		getNumericValueLastErr = getNumericValueErr_syntax;
		return false;
	}
	aint digit;
	while (p < pend) {
		const byte charDigit = *p++;
		if ('\'' == charDigit && isalnum((byte)*p)) continue;
		if (0 == charDigit || !isalnum(charDigit)) {
			getNumericValueLastErr = getNumericValueErr_no_digit;
			break;
		}
		if (base <= (digit = getval(charDigit))) {
			getNumericValueLastErr = getNumericValueErr_digit;
			break;
		}
		const uint32_t oval = static_cast<uint32_t>(val);
		val = (val * base) + digit;
		if (static_cast<uint32_t>(val) < oval) getNumericValueLastErr = getNumericValueErr_overflow;
	}
	return (NULL == getNumericValueLastErr);
}

// parses number literals, forces result to be confined into 32b (even on 64b platforms,
// to have stable results in listings/tests across platforms).
int GetConstant(char*& op, aint& val) {
	// the input string has been already detected as numeric literal by ParseExpPrim
	assert(isdigit((byte)*op) || '#' == *op || '$' == *op || '%' == *op);
	// find end of the numeric literal (pointer is beyond last alfa/digit character
	char* pend = op;
	if ('#' == *pend || '$' == *pend || '%' == *pend) ++pend;
	while (isalnum((byte)*pend) || ('\'' == *pend && isalnum((byte)pend[1]))) ++pend;
	char* const hardEnd = pend;
	// check if the format is defined by prefix (#, $, %, 0x, 0X, 0b, 0B, 0q, 0Q)
	char* p = op;
	int shiftBase = 0, base = 0;
	if ('#' == *p || '$' == *p) {
		shiftBase = 4;
		++p;
	} else if ('0' == p[0] && 'x' == (p[1]|0x20)) {
		shiftBase = 4;
		p += 2;
	} else if ('0' == p[0] && 'b' == (p[1]|0x20) && 'h' != (pend[-1]|0x20) ) {
		shiftBase = 1;		// string 0b800h is hexadecimal, not binary (legacy compatibility)
		p += 2;
	} else if ('0' == p[0] && 'q' == (p[1]|0x20)) {
		shiftBase = 3;
		p += 2;
	} else if ('%' == *p) {
		shiftBase = 1;
		++p;
	}
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
	if ('\'' == *p || '\'' == pend[-1]) {	// digit-group tick can't be first/last digit
		Error(getNumericValueErr_no_digit, op, SUPPRESS);
		return 0;
	}
	// parse the number into value
	if (0 < shiftBase) {
		if (!GetNumericValue_TwoBased(p, pend, val, shiftBase) && GetNumericValue_ProcessLastError(op))
			return 0;
	} else {
		if (!GetNumericValue_IntBased(p, pend, val, base) && GetNumericValue_ProcessLastError(op))
			return 0;
	}
	op = hardEnd;
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
	// return backslash as char value in case of unknown escape sequence
	// (to mimick older versions of sjasmplus like 1.07-1.10 behaviour)
	--op;
	val = '\\';
	Warning("Unknown escape", op-1);
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
		const char oldCh = *p;
		*p = 0;						// shorten the string literal for warning display
		sprintf(buffer, "String literal truncated to 0x%X", val);
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
		char* const oldP = p;
		if (SkipBlanks(p)) {
			Error("Expression expected", NULL, SUPPRESS);
			break;
		}
		if (0 != (strRes = GetCharConstAsString(p, e, t, 128, add))) {
			// string literal parsed (both types)
			if (-1 == strRes) break;		// syntax error happened
			// single byte "strings" may have further part of expression, detect it here
			if (1 == t - oldT && !SkipBlanks(p) && ',' != *p) {
				// expression with single char detected (like 'a'|128), revert the string parsing
				t = oldT;
				p = oldP;		// and continue with the last code-path trying to parse expression
			} else {	// string literal (not expression), handle the extra string literal logic
				if (oldT == t) {
					Warning("Empty string", p-2);
				} else if (dc) {
					// mark last "string" byte with |128: single char in quotes *is* string
					// but single char in apostrophes *is not* (!) (no |128 then)
					int maxLengthNotString = (1 == strRes);		// 0 for quotes, 1 for apostrophes
					if (maxLengthNotString < (t - oldT)) e[t - 1] |= 128;
				}
				continue;
			}
		}
		if (ParseExpressionNoSyntaxError(p, val)) {
			check8(val);
			e[t++] = (val + add) & 255;
		} else {
			Error("Syntax error", p, SUPPRESS);
			break;
		}
	} while(comma(p) && t < 128);
	e[t] = -1;
	if (t == 128 && *p) Error("Over 128 bytes defined in single DB/DC/... Values over", p, SUPPRESS);
	return t;
}

int GetBits(char*& p, int e[]) {
	EDelimiterType dt = DelimiterBegins(p, delimiters_noAngle);	//also skip blanks
	static int one = 0;		// the warning about multi-chars should be emitted only once per pass
	static bool zeroInDgWarning = false;
	int bytes = 0;
	while (*p && (dt == DT_NONE || delimiters_e[dt] != *p)) {
		if (128 <= bytes) {
			Error("Over 128 bytes defined in DG. Bits over", p, SUPPRESS);
			break;
		}
		// collect whole byte (eight bits)
		int value = 1, pch;
		while (value < 256 && *p && (pch = 255 & (*p++))) {
			if (White(pch)) continue;		// skip spaces
			value <<= 1;
			if ('-' == pch || '.' == pch || '_' == pch) continue;
			value |= 1;
			if (LASTPASS != pass) continue;
			if (0 < one && one != pch) {
				Warning("[DG] multiple characters used for 'ones'");
				one = -1;					// emit this warning only once
			} else if (!one) one = pch;		// remember char used first time for "ones"
			if ('0' == pch && !zeroInDgWarning) {
				zeroInDgWarning = true;
				Warning("[DG] character '0' in DG works as value 1");
			}
		}
		if (value < 256) {		// there was not eight characters, ended prematurely
			Error("[DG] byte needs eight characters", substitutedLine, SUPPRESS);
		} else {
			e[bytes++] = value & 255;
		}
		SkipBlanks(p);
	}
	if (0 < one) one = 0;		// reset "ones" type if everything was OK this time
	e[bytes] = -1;
	if (dt == DT_NONE) return bytes;
	if (delimiters_e[dt] != *p)	Error("No closing delimiter", NULL, SUPPRESS);
	else 						++p;
	return bytes;
}

int GetBytesHexaText(char*& p, int e[]) {
	const char* const op_full = p;
	int bytes = 0;
	do {
		EDelimiterType dt = DelimiterBegins(p, delimiters_noAngle);	//also skip blanks
		if (!*p) Error("no arguments");
		while (*p && (dt == DT_NONE || delimiters_e[dt] != *p)) {
			const char* const op = p;
			// collect whole byte = two hexa digits
			aint val;
			if (!GetNumericValue_TwoBased(p, p+2, val, 4) && GetNumericValue_ProcessLastError(op)) {
				return 0;		// total failure, don't emit anything
			}
			if (128 <= bytes) {
				Error("Over 128 bytes defined in DH/DEFH/HEX. Values over", op, SUPPRESS);
				break;
			}
			e[bytes++] = val & 255;
			SkipBlanks(p);			// skip spaces
			if (dt == DT_NONE && ',' == *p) break;	// loop through multi arguments in outer do-while loop
		}
		if (dt != DT_NONE) {
			if (delimiters_e[dt] == *p)	{
				++p;
				SkipBlanks(p);
			} else Error("No closing delimiter", op_full, SUPPRESS);
		}
	} while (comma(p));
	e[bytes] = -1;
	return bytes;
}

static EDelimiterType delimiterOfLastFileName = DT_NONE;

char* GetFileName(char*& p, bool convertslashes) {
	char* newFn = new char[LINEMAX+1], * result = newFn;
	if (NULL == newFn) ErrorOOM();
	// check if some and which delimiter is used for this filename (does advance over white chars)
	// and remember type of detected delimiter (for GetDelimiterOfLastFileName function)
	delimiterOfLastFileName = DelimiterAnyBegins(p);
	const char deliE = delimiters_e[delimiterOfLastFileName];	// expected ending delimiter
	// copy all characters until zero or delimiter-end character is reached
	while (*p && deliE != *p) {
		*newFn = *p;		// copy character
		if (convertslashes && pathBadSlash == *newFn) *newFn = pathGoodSlash;	// convert slashes if enabled
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
			Error("No closing delimiter", delimiterTxt, SUPPRESS);
			result[0] = 0;	// return "empty" string filename
		}
	}
	SkipBlanks(p);			// skip blanks any way
	return result;
}

EDelimiterType GetDelimiterOfLastFileName() {
	// DT_NONE if no GetFileName was called
	return delimiterOfLastFileName;
}

bool isLabelStart(const char *p, bool modifiersAllowed) {
	if (modifiersAllowed) {
		if ('.' == *p || '@' == *p) return isLabelStart(p + 1, false);
	}
	return *p && (isalpha((byte)*p) || '_' == *p);
}

int islabchar(char p) {
	if (isalnum((byte)p) || p == '_' || p == '.' || p == '?' || p == '!' || p == '#' || p == '@') {
		return 1;
	}
	return 0;
}

EStructureMembers GetStructMemberId(char*& p) {
	if (*p == '#') {
		++p;
		if (*p == '#') {
			++p;
			return SMEMBALIGN;
		}
		return SMEMBBLOCK;
	}
	//  if (*p=='.') ++p;
	switch (*p * 2 + *(p + 1)) {
	case 'b'*2+'y':
	case 'B'*2+'Y':
		if (cmphstr(p, "byte")) return SMEMBBYTE;
		break;
	case 'w'*2+'o':
	case 'W'*2+'O':
		if (cmphstr(p, "word")) return SMEMBWORD;
		break;
	case 'b'*2+'l':
	case 'B'*2+'L':
		if (cmphstr(p, "block")) return SMEMBBLOCK;
		break;
	case 'd'*2+'b':
	case 'D'*2+'B':
		if (cmphstr(p, "db")) return SMEMBBYTE;
		break;
	case 'd'*2+'w':
	case 'D'*2+'W':
		if (cmphstr(p, "dw")) return SMEMBWORD;
		if (cmphstr(p, "dword")) return SMEMBDWORD;
		break;
	case 'd'*2+'s':
	case 'D'*2+'S':
		if (cmphstr(p, "ds")) return SMEMBBLOCK;
		break;
	case 'd'*2+'d':
	case 'D'*2+'D':
		if (cmphstr(p, "dd")) return SMEMBDWORD;
		break;
	case 'a'*2+'l':
	case 'A'*2+'L':
		if (cmphstr(p, "align")) return SMEMBALIGN;
		break;
	case 'd'*2+'e':
	case 'D'*2+'E':
		if (cmphstr(p, "defs")) return SMEMBBLOCK;
		if (cmphstr(p, "defb")) return SMEMBBYTE;
		if (cmphstr(p, "defw")) return SMEMBWORD;
		if (cmphstr(p, "defd")) return SMEMBDWORD;
		break;
	case 'd'*2+'2':
	case 'D'*2+'2':
		if (cmphstr(p, "d24")) return SMEMBD24;
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
		// the angle-bracket can only be used around whole argument (i.e. '<' must be first char)
		EDelimiterType delI = DelimiterBegins(src, srcOrig==src ? delimiters_all : delimiters_noAngle, false);
		if (DT_NONE == delI) {		// no delimiter found, ordinary expression, copy char by char
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
			default:	Error("Internal error. GetMacroArgumentValue()", NULL, FATAL);
			}
			if (endCh == *src) break;			// ending delimiter found
			*dst++ = *src++;					// just copy character
		}
		// ending delimiter must be identical to endCh
		if (endCh != *src) {
			*dst = 0;							// zero terminator of resulting string value
			return 0;
		}
		// set ending delimiter for quotes and apostrophe (angles are stripped from value)
		if (DT_QUOTES == delI || DT_APOSTROPHE == delI) *dst++ = endCh;
		++src;									// advance over delimiter
	}
	*dst = 0;									// zero terminator of resulting string value
	if (! *dstOrig) Warning("[Macro argument parser] empty value", srcOrig);
	return 1;
}

EDelimiterType DelimiterBegins(char*& src, const std::array<EDelimiterType, 3> delimiters, bool advanceSrc) {
	if ((0 == *src) || (advanceSrc && SkipBlanks(src))) return DT_NONE;
	for (const auto dt : delimiters) {
		if (delimiters_b[dt] != *src) continue;
		if (advanceSrc) ++src;
		return dt;
	}
	return DT_NONE;
}

EDelimiterType DelimiterAnyBegins(char*& src, bool advanceSrc) {
	return DelimiterBegins(src, delimiters_all, advanceSrc);
}

// checks for "ok" (or also "fake") in EOL comment
// "ok" must follow the comment start, "fake" can be anywhere inside
bool warningNotSuppressed(bool alsoFake) {
	if (nullptr == eolComment) return true;
	char* comment = eolComment;
	while (';' == *comment || '/' == *comment) ++comment;
	while (' ' == *comment || '\t' == *comment) ++comment;
	// check if "ok" is first word
	if ('o' == comment[0] && 'k' == comment[1] && !isalnum((byte)comment[2])) return false;
	return alsoFake ? (nullptr == strstr(eolComment, "fake")) : true;
}

//eof reader.cpp
