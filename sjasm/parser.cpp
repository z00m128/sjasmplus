/*

  SjASMPlus Z80 Cross Compiler

  This is modified sources of SjASM by Aprisobal - aprisobal@tut.by

  Copyright (c) 2005 Sjoerd Mastijn

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

// parser.cpp

#include "sjdefs.h"

char dirDEFl[] = "def", dirDEFu[] = "DEF";

static bool synerr = true;	// flag whether ParseExpression should report syntax error with Error()

int ParseExpPrim(char*& p, aint& nval) {
	int res = 0;
	if (SkipBlanks(p)) {
		return 0;
	}
	if (*p == '(') {
		++p;
		res = ParseExpression(p, nval);
		if (!need(p, ')')) {
				Error("')' expected");
				return 0;
		 }
	} else if (DeviceID && *p == '{') {
	  	++p; res = ParseExpression(p, nval);
		/*if (nval < 0x4000) {
			Error("Address in {..} must be more than 4000h"); return 0;
		} */
		if (nval > 0xFFFE) {
			Error("Address in {..} must be less than FFFFh"); return 0;
		}
		if (!need(p, '}')) {
			Error("'}' expected"); return 0;
		}

	  	nval = (aint) (MemGetByte(nval) + (MemGetByte(nval + 1) << 8));

	  	return 1;
	} else if (isdigit((unsigned char) * p) || (*p == '#' && isalnum((unsigned char) * (p + 1))) || (*p == '$' && isalnum((unsigned char) * (p + 1))) || *p == '%') {
	  	res = GetConstant(p, nval);
	} else if (isalpha((unsigned char) * p) || *p == '_' || *p == '.' || *p == '@') {
	  	res = GetLabelValue(p, nval);
	} else if (*p == '?' && (isalpha((unsigned char) * (p + 1)) || *(p + 1) == '_' || *(p + 1) == '.' || *(p + 1) == '@')) {
	  	++p;
		res = GetLabelValue(p, nval);
	} else if (DeviceID && *p == '$' && *(p + 1) == '$') {
		++p;
		++p;
		nval = Page->Number;

		return 1;
	} else if (*p == '$') {
		++p;
		nval = CurAddress;

		return 1;
	} else if (!(res = GetCharConst(p, nval))) {
		if (synerr) Error("Syntax error", p, IF_FIRST);
		return 0;
	}
	return res;
}

int ParseExpUnair(char*& p, aint& nval) {
	aint right;
	int oper;
	if ((oper = need(p, "! ~ + - ")) || (oper = needa(p, "not", '!', "low", 'l', "high", 'h'))) {
		switch (oper) {
		case '!':
			if (!ParseExpUnair(p, right)) {
				return 0;
			} nval = -!right; break;
		case '~':
			if (!ParseExpUnair(p, right)) {
				return 0;
			} nval = ~right; break;
		case '+':
			if (!ParseExpUnair(p, right)) {
				return 0;
			} nval = right; break;
		case '-':
			if (!ParseExpUnair(p, right)) {
				return 0;
			} nval = ~right + 1; break;
		case 'l':
			if (!ParseExpUnair(p, right)) {
				return 0;
			} nval = right & 255; break;
		case 'h':
			if (!ParseExpUnair(p, right)) {
				return 0;
			} nval = (right >> 8) & 255; break;
		default:
			Error("Parser error"); break;
		}
		return 1;
	} else {
		return ParseExpPrim(p, nval);
	}
}

int ParseExpMul(char*& p, aint& nval) {
	aint left, right;
	int oper;
	if (!ParseExpUnair(p, left)) {
		return 0;
	}
	while ((oper = need(p, "* / % ")) || (oper = needa(p, "mod", '%'))) {
		if (!ParseExpUnair(p, right)) {
			return 0;
		}
		switch (oper) {
		case '*':
			left *= right; break;
		case '/':
			if (right) {
				left /= right;
			} else {
				Error("Division by zero"); left = 0;
			} break;
		case '%':
			if (right) {
				left %= right;
			} else {
				Error("Division by zero"); left = 0;
			} break;
		default:
			Error("Parser error"); break;
		}
	}
	nval = left; return 1;
}

int ParseExpAdd(char*& p, aint& nval) {
	aint left, right;
	int oper;
	if (!ParseExpMul(p, left)) {
		return 0;
	}
	while ((oper = need(p, "+ - "))) {
		if (!ParseExpMul(p, right)) {
			return 0;
		}
		switch (oper) {
		case '+':
			left += right; break;
		case '-':
			left -= right; break;
		default:
			Error("Parser error"); break;
		}
	}
	nval = left; return 1;
}

int ParseExpShift(char*& p, aint& nval) {
	aint left, right;
	unsigned long l;
	int oper;
	if (!ParseExpAdd(p, left)) {
		return 0;
	}
	while ((oper = need(p, "<<>>")) || (oper = needa(p, "shl", '<' + '<', "shr", '>'))) {
		if (oper == '>' + '>' && *p == '>') {
			++p; oper = '>' + '@';
		}
		if (!ParseExpAdd(p, right)) {
			return 0;
		}
		switch (oper) {
		case '<'+'<':
			left <<= right; break;
		case '>':
		case '>'+'>':
			left >>= right; break;
		case '>'+'@':
			l = left; l >>= right; left = l; break;
		default:
			Error("Parser error"); break;
		}
	}
	nval = left; return 1;
}

int ParseExpMinMax(char*& p, aint& nval) {
	aint left, right;
	int oper;
	if (!ParseExpShift(p, left)) {
		return 0;
	}
	while ((oper = need(p, "<?>?"))) {
		if (!ParseExpShift(p, right)) {
			return 0;
		}
		switch (oper) {
		case '<'+'?':
			left = left < right ? left : right; break;
		case '>'+'?':
			left = left > right ? left : right; break;
		default:
			Error("Parser error"); break;
		}
	}
	nval = left; return 1;
}

int ParseExpCmp(char*& p, aint& nval) {
	aint left, right;
	int oper;
	if (!ParseExpMinMax(p, left)) {
		return 0;
	}
	while ((oper = need(p, "<=>=< > "))) {
		if (!ParseExpMinMax(p, right)) {
			return 0;
		}
		switch (oper) {
		case '<':
			left = -(left < right); break;
		case '>':
			left = -(left > right); break;
		case '<'+'=':
			left = -(left <= right); break;
		case '>'+'=':
			left = -(left >= right); break;
		default:
			Error("Parser error"); break;
		}
	}
	nval = left; return 1;
}

int ParseExpEqu(char*& p, aint& nval) {
	aint left, right;
	int oper;
	if (!ParseExpCmp(p, left)) {
		return 0;
	}
	while ((oper = need(p, "=_==!="))) {
		if (!ParseExpCmp(p, right)) {
			return 0;
		}
		switch (oper) {
		case '=':
		case '='+'=':
			left = -(left == right); break;
		case '!'+'=':
			left = -(left != right); break;
		default:
			Error("Parser error"); break;
		}
	}
	nval = left; return 1;
}

int ParseExpBitAnd(char*& p, aint& nval) {
	aint left, right;
	if (!ParseExpEqu(p, left)) {
		return 0;
	}
	while (need(p, "&_") || needa(p, "and", '&')) {
		if (!ParseExpEqu(p, right)) {
			return 0;
		}
		left &= right;
	}
	nval = left; return 1;
}

int ParseExpBitXor(char*& p, aint& nval) {
	aint left, right;
	if (!ParseExpBitAnd(p, left)) {
		return 0;
	}
	while (need(p, "^ ") || needa(p, "xor", '^')) {
		if (!ParseExpBitAnd(p, right)) {
			return 0;
		}
		left ^= right;
	}
	nval = left; return 1;
}

int ParseExpBitOr(char*& p, aint& nval) {
	aint left, right;
	if (!ParseExpBitXor(p, left)) {
		return 0;
	}
	while (need(p, "|_") || needa(p, "or", '|')) {
		if (!ParseExpBitXor(p, right)) {
			return 0;
		}
		left |= right;
	}
	nval = left; return 1;
}

int ParseExpLogAnd(char*& p, aint& nval) {
	aint left, right;
	if (!ParseExpBitOr(p, left)) {
		return 0;
	}
	while (need(p, "&&")) {
		if (!ParseExpBitOr(p, right)) {
			return 0;
		}
		left = -(left && right);
	}
	nval = left; return 1;
}

int ParseExpLogOr(char*& p, aint& nval) {
	aint left, right;
	if (!ParseExpLogAnd(p, left)) {
		return 0;
	}
	while (need(p, "||")) {
		if (!ParseExpLogAnd(p, right)) {
			return 0;
		}
		left = -(left || right);
	}
	nval = left; return 1;
}

int ParseExpression(char*& p, aint& nval) {
	if (ParseExpLogOr(p, nval)) {
		return 1;
	}
	nval = 0;
	return 0;
}

int ParseExpressionNoSyntaxError(char*& lp, aint& val) {
	bool osynerr = synerr;
	synerr = false;
	int ret_val = ParseExpression(lp, val);
	synerr = osynerr;
	return ret_val;
}

void ParseAlignArguments(char* & src, aint & alignment, aint & fill) {
	SkipBlanks(src);
	const char * const oldSrc = src;
	fill = -1;
	if (!ParseExpression(src, alignment)) {
		alignment = -1;
		return;
	}
	// check if alignment value is power of two (0..15-th power only)
	if (alignment < 1 || (1<<15) < alignment || (alignment & (alignment-1))) {
		Error("[ALIGN] Illegal align", oldSrc, SUPPRESS);
		alignment = 0;
		return;
	}
	if (!comma(src)) return;
	if (!ParseExpression(lp, fill)) {
		fill = -1;
	} else if (fill < 0 || 255 < fill) {
		Error("[ALIGN] Illegal align fill-byte", oldSrc, SUPPRESS);
		fill = -1;
	}
}

static bool ReplaceDefineInternal(char* lp, char* const nl) {
	int definegereplaced = 0,dr;
	char* rp = nl,* nid,* kp,* ver;
	bool isPrevDefDir, isCurrDefDir = false;	// to remember if one of DEFINE-related directives was previous word
	bool afterNonAlphaNum, afterNonAlphaNumNext = true;
	while (*lp) {
		const char c1 = lp[0], c2 = lp[1];
		afterNonAlphaNum = afterNonAlphaNumNext;
		afterNonAlphaNumNext = !isalnum(c1);
		if (c1 == '/' && c2 == '*') {	// block-comment local beginning (++block_nesting)
			lp += 2;
			++comlin;
			continue;
		}
		if (comlin) {
			if (c1 == '*' && c2 == '/') {
				lp += 2;
				// insert space into line, if the block ending may have affected parsing of line
				if (1 == comlin) {
					*rp++ = ' ';		// ^^ otherwise this line is completely commented out
				}
				--comlin;	// decrement block comment counter
			} else {
				++lp;		// just skip all characters inside comment block
			}
			continue;
		}
		// for following code (0 == comlin) (unless it has its own parse loop)

		// single line comments -> finish
		if (c1 == ';' || (c1 == '/' && c2 == '/')) break;

		// strings parsing
		if (afterNonAlphaNum && (c1 == '"' || c1 == '\'')) {
			isPrevDefDir = isCurrDefDir;
			isCurrDefDir = false;
			*rp++ = *lp++;				// copy the string delimiter (" or ')
			// apostrophe inside apostrophes ('') will parse as end + start of another string
			// which sort of "accidentally" leads to correct final results
			while (*lp && c1 != *lp) {	// until end of current string is reached (or line ends)
				// inside double quotes the backslash should escape (anything after it)
				if ('"' == c1 && '\\' == *lp && lp[1]) *rp++ = *lp++;	// copy escaping backslash extra
				*rp++ = *lp++;			// copy string character
			}
			if (*lp) *rp++ = *lp++;		// copy the ending string delimiter (" or ')
			continue;
		}

		if (!isalpha((unsigned char) * lp) && *lp != '_') {
			*rp++ = *lp++;
			continue;
		}

		// update previous/current word is define-related directive
		isPrevDefDir = isCurrDefDir;
		kp = lp;
		isCurrDefDir = afterNonAlphaNum && (cmphstr(kp, "define") || cmphstr(kp, "undefine")
			|| cmphstr(kp, "defarray") || cmphstr(kp, "ifdef") || cmphstr(kp, "ifndef"));

		// The following loop is recursive-like macro/define substitution, the `*lp` here points
		// at alphabet/underscore char, marking start of "id" string, and it will be parsed by
		// sub-id parts, delimited by underscores, each combination of consecutive sub-ids may
		// be substituted by some macro argument or define.

		//TODO - maybe consider the substitution search to go downward, from longest term to shortest subterm
		ResetGrowSubId();
		char* nextSubIdLp = lp, * wholeIdLp = lp;
		do { //while(islabchar(*lp));
			nid = GrowSubId(lp);		// grow the current sub-id part by part, checking each combination for substitution
			// defines/macro arguments can substitute in the middle of ID only if they don't start with underscore
			const bool canSubstituteInside = '_' != nid[0] || nextSubIdLp == wholeIdLp;
			if (macrolabp && canSubstituteInside && (ver = MacroDefineTable.getverv(nid))) {
				dr = 2;			// macro argument substitution is possible
			} else if (!isPrevDefDir && canSubstituteInside && (ver = DefineTable.Get(nid))) {
				dr = 1;			// DEFINE substitution is possible
				//handle DEFARRAY case
				if (DefineTable.DefArrayList) {
					ver = nid;	// in case of some error, just copy the array id "as is"
					CStringsList* a = DefineTable.DefArrayList;
					while (White(*lp)) GrowSubIdByExtraChar(lp);
					aint val;
					if ('[' != *lp) Error("[ARRAY] Expression error", nextSubIdLp, SUPPRESS);
					if ('[' == *lp && GrowSubIdByExtraChar(lp) && ParseExpressionNoSyntaxError(lp, val) && ']' == *lp) {
						++lp;
						while (0 < val && a) {
							a = a->next;
							--val;
						}
						if (val < 0 || NULL == a) {
							*ver = 0;			// substitute with empty string
							Error("[ARRAY] index not in 0..<Size-1> range");
						} else {
							ver = a->string;	// substitute with array value
						}
					} else {	// no substition of array possible at this time (index eval / syntax error)
						dr = -1;// write into output, but don't count as replacement
					}
				}
			} else {
				dr = 0;			// no possible substitution found
				ver = nid;
			}
			// check if no substition was found, and there's no more chars to extend SubId
			if (0 == dr && !islabchar(*lp)) {
				lp = nextSubIdLp;		// was fully extended, no match, "eat" first subId
				ResetGrowSubId();
				ver = GrowSubId(lp);	// find the first SubId again, for the copy
				dr = -1;				// write into output, but don't count as replacement
			}
			if (0 < dr) definegereplaced = 1;		// above zero => count as replacement
			if (0 != dr) {				// any non-zero dr => write to the output
				while (*ver) *rp++ = *ver++;		// replace the string into target buffer
				// reset subId parser to catch second+ subId in current Id
				ResetGrowSubId();
				nextSubIdLp = lp;
			}
			// continue with extending the subId, if there's still something to parse
		} while(islabchar(*lp));
	} // while(*lp)
	// add line terminator to the output buffer
	*rp = 0;
	if (strlen(nl) > LINEMAX - 1) {
		Error("line too long after macro expansion", NULL, FATAL);
	}
	// check if whole line is just blanks, then return just empty one
	rp = nl;
	SkipBlanks(rp);
	if (!*rp) *nl = 0;
	substitutedLine = nl;		// set global pointer to the latest substituted version
	return definegereplaced;
}

char* ReplaceDefine(char* lp) {
	// do first replacement into sline buffer (and if no define replace done, just return it)
	if (!ReplaceDefineInternal(lp, sline)) return sline;
	// Some define were replaced, line is in "sline", now ping-pong it between sline and sline2
	int defineReplaceRecursion = 0;
	while (defineReplaceRecursion++ < 10) {
		if (!ReplaceDefineInternal(sline, sline2)) return sline2;
		if (!ReplaceDefineInternal(sline2, sline)) return sline;
	}
	Error("Over 20 defines nested", NULL, FATAL);
	return NULL;
}

void ParseLabel() {
	if (White()) return;
	if (Options::IsPseudoOpBOF && ParseDirective(true)) return;
	char temp[LINEMAX], * tp = temp, * ttp;
	aint val, oval;
	while (*lp && !White() && *lp != ':' && *lp != '=') {
		*tp = *lp; ++tp; ++lp;
	}
	*tp = 0;
	if (*lp == ':') {
		++lp;
	}
	tp = temp;
	SkipBlanks();
	IsLabelNotFound = 0;
	if (isdigit((unsigned char) * tp)) {
		if (NeedEQU() || NeedDEFL()) {
			Error("Number labels only allowed as address labels");
			return;
		}
		val = atoi(tp);
		if (!LocalLabelTable.InsertRefresh(val)) {
			Error("Local-labels flow differs in this pass (missing/new local label or final pass source difference)");
		}
	} else {
		bool IsDEFL = false;
		if ((IsDEFL = NeedDEFL()) || NeedEQU()) {
			if (!ParseExpression(lp, val)) {
				Error("Expression error", lp);
				val = 0;
			}
			if (IsLabelNotFound) Error("Forward reference", NULL, EARLY);
		} else {
			int gl = 0;
			char* p = lp,* n;
			SkipBlanks(p);
			if (*p == '@') {
				++p; gl = 1;
			}
			if ((n = GetID(p)) && StructureTable.Emit(n, tp, p, gl)) {
				lp = p;
				return;
			}
			val = CurAddress;
		}
		ttp = tp;
		if (!(tp = ValidateLabel(tp, VALIDATE_LABEL_SET_NAMESPACE))) {
			return;
		}
		// Copy label name to last parsed label variable
		if (!IsDEFL) {
			if (LastParsedLabel != NULL) free(LastParsedLabel);
			LastParsedLabel = STRDUP(tp);
			if (LastParsedLabel == NULL) {
				Error("No enough memory!", NULL, FATAL);
			}
		}
		if (pass == LASTPASS) {
			if (IsDEFL && !LabelTable.Insert(tp, val, false, IsDEFL)) {
				Error("Duplicate label", tp, PASS3);
			}
			if (!GetLabelValue(ttp, oval)) {
				Error("Internal error. ParseLabel()", NULL, FATAL);
			}
			if (!IsDEFL && val != oval) {
				char* buf = new char[LINEMAX];

				SPRINTF2(buf, LINEMAX, "previous value %lu not equal %lu", oval, val);
				Warning("Label has different value in pass 3", buf);
				LabelTable.Update(tp, val);

				delete[] buf;
			}
		} else if (pass == 2 && !LabelTable.Insert(tp, val, false, IsDEFL) && !LabelTable.Update(tp, val)) {
			Error("Duplicate label", tp, EARLY);
		} else if (pass == 1 && !LabelTable.Insert(tp, val, false, IsDEFL)) {
			Error("Duplicate label", tp, EARLY);
		}
		delete[] tp;
	}
}

int ParseMacro() {
	int gl = 0, r;
	char* p = lp, *n;
	SkipBlanks(p);
	if (*p == '@') {
		gl = 1; ++p;
	}
	if (!(n = GetID(p))) {
		return 0;
	}

	r = MacroTable.Emit(n, p);
	if (r == 2) return 1;
	if (r == 1) return 0;
	if (StructureTable.Emit(n, 0, p, gl)) { lp = p; return 1; }

	return 0;
}

void ParseInstruction() {
	if (ParseDirective()) {
		return;
	}
	Z80::GetOpCode();
}

unsigned char win2dos[] = //taken from HorrorWord %)))
{
	0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF, 0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xF0, 0xD8, 0xD9, 0xDA, 0xDB, 0xDC, 0xDD, 0xDE, 0xDF, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF1, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0x20, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F, 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F, 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF, 0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEE, 0xEF
};

//#define DEBUG_COUT_PARSE_LINE

void ParseLine(bool parselabels) {
	if (!RepeatStack.empty()) {
		SRepeatStack& dup = RepeatStack.top();
		if (!dup.IsInWork) {
			lp = line;
			CStringsList* f = new CStringsList(lp);
			dup.Pointer->next = f;
			dup.Pointer = f;
#ifdef DEBUG_COUT_PARSE_LINE
			fprintf(stderr, ">%d %ld %c%ld-%d [%s]\n", pass, CurrentSourceLine,
					(!RepeatStack.empty() && RepeatStack.top().IsInWork ? '!' : '.'),RepeatStack.size(),
					(!RepeatStack.empty() ? RepeatStack.top().Level : 0), line);
#endif
			++CompiledCurrentLine;
			ParseDirective_REPT();
			return;
		}
	}
#ifdef DEBUG_COUT_PARSE_LINE
	fprintf(stderr, "|%d %ld %c%ld-%d [%s]\n", pass, CurrentSourceLine,
			(!RepeatStack.empty() && RepeatStack.top().IsInWork ? '!' : '.'), RepeatStack.size(),
			(!RepeatStack.empty() ? RepeatStack.top().Level : 0), line);
#endif
	++CompiledCurrentLine;
	lp = ReplaceDefine(line);

#ifdef DEBUG_COUT_PARSE_LINE
	fprintf(stderr,"rdOut [%s]->[%s] %ld\n", line, lp, comlin);
#endif

	// update current address by memory wrapping, current page, etc... (before the label is defined)
	if (DeviceID)	Device->CheckPage(CDevice::CHECK_NO_EMIT);
	else			CheckRamLimitExceeded();
	ListAddress = CurAddress;

	if (!ConvertEncoding) {
		unsigned char* lp2 = (unsigned char*) lp;
		while (*(lp2++)) {
			if ((*lp2) >= 128) {
				*lp2 = win2dos[(*lp2) - 128];
			}
		}
	}
	if (!*lp) {
		char *srcNonWhiteChar = line;
		SkipBlanks(srcNonWhiteChar);
		// check if only "end-line" comment remained, treat that one as "empty" line too
		if (';' == *srcNonWhiteChar || ('/' == srcNonWhiteChar[0] && '/' == srcNonWhiteChar[1]))
			srcNonWhiteChar = lp;			// force srcNonWhiteChar to point to 0
		if (*srcNonWhiteChar || comlin) {	// non-empty source line turned into nothing
			ListFile(true);					// or empty source inside comment-block -> "skipped"
		} else {
			ListFile();						// empty source line outside of block-comment -> "normal"
		}
		return;
	}
	if (parselabels) {
		ParseLabel();
	}
	if (SkipBlanks()) {
		ListFile();
		return;
	}
	ParseMacro();
	if (SkipBlanks()) {
		ListFile(); return;
	}
	ParseInstruction();
	if (SkipBlanks()) {
		ListFile(); return;
	}
	if (*lp) Error("Unexpected", lp);
	ListFile();
}

void ParseLineSafe(bool parselabels) {
	char* tmp = NULL, * tmp2 = NULL;
	char* rp = lp;
	if (sline[0] > 0) {
		tmp = STRDUP(sline);
		if (tmp == NULL) {
			Error("No enough memory!", NULL, FATAL);
		}
	}
	if (sline2[0] > 0) {
		tmp2 = STRDUP(sline2);
		if (tmp2 == NULL) {
			Error("No enough memory!", NULL, FATAL);
		}
	}

	ParseLine(parselabels);

	*sline = 0;
	*sline2 = 0;

	if (tmp2 != NULL) {
		STRCPY(sline2, LINEMAX2, tmp2);
		free(tmp2);
	}
	if (tmp != NULL) {
		STRCPY(sline, LINEMAX2, tmp);
		free(tmp);
	}
	lp = rp;
}

void ParseStructLabel(CStructure* st) {	//FIXME Ped7g why not to reuse ParseLabel()?
	char* tp, temp[LINEMAX];
	PreviousIsLabel = 0;
	if (White()) {
		return;
	}
	tp = temp; if (*lp == '.') {
			   	++lp;
			   }
	while (*lp && islabchar(*lp)) {
		*tp = *lp; ++tp; ++lp;
	}
	*tp = 0; if (*lp == ':') {
			 	++lp;
			 }
	tp = temp; SkipBlanks();
	if (isdigit((unsigned char) * tp)) {
		Error("[STRUCT] Number labels not allowed within structs"); return;
	}
	PreviousIsLabel = STRDUP(tp);
	if (PreviousIsLabel == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}
	st->AddLabel(tp);
}

void ParseStructMember(CStructure* st) {
	aint val, len;
	bp = lp;
	switch (GetStructMemberId(lp)) {
	case SMEMBBLOCK:
		if (!ParseExpression(lp, len)) {
			len = 1; Error("[STRUCT] Expression expected");
		}
		if (comma(lp)) {
			if (!ParseExpression(lp, val)) {
				val = 0; Error("[STRUCT] Expression expected");
			}
			check8(val);
			val &= 255;
		} else {
			val = -1;
		}
		st->AddMember(new CStructureEntry2(st->noffset, len, val, SMEMBBLOCK));
		break;
	case SMEMBBYTE:
		if (!ParseExpression(lp, val)) {
			val = 0;
		} check8(val);
		st->AddMember(new CStructureEntry2(st->noffset, 1, val, SMEMBBYTE));
		break;
	case SMEMBWORD:
		if (!ParseExpression(lp, val)) {
			val = 0;
		} check16(val);
		st->AddMember(new CStructureEntry2(st->noffset, 2, val, SMEMBWORD));
		break;
	case SMEMBD24:
		if (!ParseExpression(lp, val)) {
			val = 0;
		} check24(val);
		st->AddMember(new CStructureEntry2(st->noffset, 3, val, SMEMBD24));
		break;
	case SMEMBDWORD:
		if (!ParseExpression(lp, val)) {
			val = 0;
		}
		st->AddMember(new CStructureEntry2(st->noffset, 4, val, SMEMBDWORD));
		break;
	case SMEMBALIGN:
	{
		aint val, fill;
		ParseAlignArguments(lp, val, fill);
		if (-1 == val) val = 4;
		if (st->maxAlignment < val) st->maxAlignment = val;	// update structure "max alignment"
		aint bytesToAdvance = (~st->noffset + 1) & (val - 1);
		if (bytesToAdvance < 1) break;		// already aligned, nothing to do
		// create alignment block
		st->AddMember(new CStructureEntry2(st->noffset, bytesToAdvance, fill, SMEMBBLOCK));
		break;
	}
	default:
		char* pp = lp,* n;
		int gl = 0;
		CStructure* s;
		SkipBlanks(pp); if (*pp == '@') {
							++pp; gl = 1;
						}
		if ((n = GetID(pp)) && (s = StructureTable.zoek(n, gl))) {
			if (cmphstr(st->naam, n)) {
				Error("[STRUCT] Use structure itself", NULL, IF_FIRST);
				break;
			}
			if (s->maxAlignment && ((~st->noffset + 1) & (s->maxAlignment - 1))) {
				// Inserted structure did use ALIGN in definition and it is misaligned here
				char warnTxt[LINEMAX];
				SPRINTF3(warnTxt, LINEMAX,
						 "Struct %s did use ALIGN %d in definition, but here it is misaligned by %ld bytes",
						 s->naam, s->maxAlignment, ((~st->noffset + 1) & (s->maxAlignment - 1)));
				Warning(warnTxt);
			}
			lp = pp;
			st->CopyLabels(s);
			st->CopyMembers(s, lp);
		}
		break;
	}
}

void ParseStructLine(CStructure* st) {
	lp = ReplaceDefine(line);
	if (!*lp) return;
	ParseStructLabel(st);
	if (SkipBlanks()) return;
	ParseStructMember(st);
	if (SkipBlanks()) return;
	if (*lp) Error("[STRUCT] Unexpected", lp);
}

unsigned long LuaCalculate(char *str) {
	aint val;
	if (!ParseExpression(str, val)) {
		return 0;
	} else {
		return val;
	}
}

void LuaParseLine(char *str) {
	char *ml;

	ml = STRDUP(line);
	if (ml == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}

	STRCPY(line, LINEMAX, str);
	ParseLineSafe();

	STRCPY(line, LINEMAX, ml);
}

void LuaParseCode(char *str) {
	char *ml;

	ml = STRDUP(line);
	if (ml == NULL) {
		Error("No enough memory!", NULL, FATAL);
	}

	STRCPY(line, LINEMAX, str);
	ParseLineSafe(false);

	STRCPY(line, LINEMAX, ml);
}

//eof parser.cpp
