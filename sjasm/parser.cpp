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
#include <cassert>

static bool synerr = true;	// flag whether ParseExpression should report syntax error with Error()

static int ParseExpressionEntry(char*& p, aint& nval);

static int ParseExpPrim(char*& p, aint& nval) {
	int res = 0;
	if (SkipBlanks(p)) {
		return 0;
	}
	if (*p == '(') {
		++p;
		res = ParseExpressionEntry(p, nval);
		if (!need(p, ')')) {
			Error("')' expected");
			return 0;
		}
	} else if (DeviceID && *p == '{') {		// read WORD/BYTE from virtual device memory
		char* const readMemP = p;
		const int byteOnly = cmphstr(++p, "b");
		// switch off alternative relocation evaluation for the address value
		const bool oldAreLabelsOffset = Relocation::areLabelsOffset;
		Relocation::areLabelsOffset = false;
		int addressParseRes = ParseExpressionEntry(p, nval);
		Relocation::areLabelsOffset = oldAreLabelsOffset;	// restore alternative evaluation
		if (!addressParseRes) return 0;	// some syntax error inside the address expression
		if (!need(p, '}')) {
			Error("'}' expected", readMemP, SUPPRESS);
			return 0;
		}
		if (nval < 0 || (0xFFFE + byteOnly) < nval) {
			Error("Address in {..} must fetch bytes from 0x0000..0xFFFF range", readMemP);
			nval = 0;
			return 1;						// and return zero value as result (avoid "syntax error")
		}
		res = int(MemGetByte(nval));
		if (!byteOnly) res += int(MemGetByte(nval + 1)) << 8;
		nval = res;
		return 1;
	} else if (isdigit((byte)*p) && GetLocalLabelValue(p, nval, true)) {	// temporary label with underscore suffix
		return 1;
	} else if (isdigit((byte)*p) || (*p == '#' && isalnum((byte)*(p + 1))) || (*p == '$' && isalnum((byte)*(p + 1))) || *p == '%') {
		return GetConstant(p, nval);
	} else if (isLabelStart(p)) {
		return GetLabelValue(p, nval);
	} else if (*p == '?' && isLabelStart(p+1)) {
		// this is undocumented "?<symbol>" operator, seems as workaround for labels like "not"
		// This is deprecated and will be removed in v2.x of sjasmplus
		// (where keywords will be reserved and such label would be invalid any way)
		Warning("?<symbol> operator is deprecated and will be removed in v2.x", p);
		++p;
		return GetLabelValue(p, nval);
	} else if (DISP_NONE != PseudoORG && '$' == p[0] && '$' == p[1] && '$' == p[2]) {
		if ('$' == p[3]) {		// "$$$$" operator to get physical memory page inside DISP block
			p += 4;
			nval = DeviceID ? Page->Number : LABEL_PAGE_UNDEFINED;
			return 1;
		}
		// "$$$" operator to get physical address inside DISP block
		p += 3;
		nval = adrdisp;		// this is never affected by relocation
		return 1;
	} else if (DeviceID && *p == '$' && *(p + 1) == '$') {
		p += 2;
		if (isLabelStart(p)) return GetLabelPage(p, nval);
		if (DISP_NONE != PseudoORG && LABEL_PAGE_UNDEFINED != dispPageNum) {
			// enforce explicit request of fake DISP page
			nval = dispPageNum;
		} else {
			// current page
			nval = Page->Number;
		}
		return 1;
	} else if (*p == '$') {
		++p;
		nval = CurAddress;
		if (Relocation::isActive && Relocation::areLabelsOffset && DISP_INSIDE_RELOCATE != PseudoORG) {
			nval += Relocation::ALTERNATIVE_OFFSET;
		}
		return 1;
	} else if (!(res = GetCharConst(p, nval))) {
		if (synerr) Error("Syntax error", p, IF_FIRST);
		return 0;
	}
	return res;
}

static int ParseExpUnair(char*& p, aint& nval) {
	SkipBlanks(p);
	char* oldP = p;
	if (cmphstr(p, "norel", true)) {
		// switch off alternative relocation evaluation for the following part of expression
		const bool oldAreLabelsOffset = Relocation::areLabelsOffset;
		Relocation::areLabelsOffset = false;
		int norelParseRes = ParseExpPrim(p, nval);			// higher priority than other unary
		Relocation::areLabelsOffset = oldAreLabelsOffset;	// restore alternative evaluation
		if (norelParseRes) return 1;
		// "norel" operator didn't parse successfully, try to ignore it (will treat it as label)
		p = oldP;
	}
	if (cmphstr(p, "exist", true)) {
		int existEval = 0, hasParentheses = need(p, '(');
		if (hasParentheses || isLabelStart(p)) {
			existEval = LabelExist(p, nval);
		}
		if (existEval && hasParentheses) {
			existEval = need(p, ')');						// check closing parenthesis
		}
		if (existEval) return 1;
		p = oldP;
	}
	aint right;
	int oper;
	if ((oper = need(p, "! ~ + - ")) || \
		(oper = needa(p, "not", '!', "low", 'l', "high", 'h', true)) || \
		(oper = needa(p, "abs", 'a', nullptr, 0, nullptr, 0, true)) ) {
		switch (oper) {
		case '!':
			if (!ParseExpUnair(p, right)) return 0;
			nval = -!right;
			break;
		case '~':
			if (!ParseExpUnair(p, right)) return 0;
			nval = ~right;
			break;
		case '+':
			if (!ParseExpUnair(p, right)) return 0;
			nval = right;
			break;
		case '-':
			if (!ParseExpUnair(p, right)) return 0;
			nval = ~right + 1;
			break;
		case 'l':
			if (!ParseExpUnair(p, right)) return 0;
			nval = right & 255;
			break;
		case 'h':
			if (!ParseExpUnair(p, right)) return 0;
			nval = (right >> 8) & 255;
			break;
		case 'a':
			if (!ParseExpUnair(p, right)) return 0;
			nval = abs(right);
			break;
		default: Error("internal error", nullptr, FATAL); break;	// unreachable
		}
		return 1;
	} else {
		return ParseExpPrim(p, nval);
	}
}

static int ParseExpMul(char*& p, aint& nval) {
	aint left, right;
	int oper;
	if (!ParseExpUnair(p, left)) return 0;
	while ((oper = need(p, "* / % ")) || (oper = needa(p, "mod", '%'))) {
		if (!ParseExpUnair(p, right)) return 0;
		switch (oper) {
		case '*':
			left *= right; break;
		case '/':
			left = right ? left / right : 0;
			if (!right) Error("Division by zero");
			break;
		case '%':
			left = right ? left % right : 0;
			if (!right) Error("Division by zero");
			break;
		default: Error("internal error", nullptr, FATAL); break;	// unreachable
		}
	}
	nval = left;
	return 1;
}

static int ParseExpAdd(char*& p, aint& nval) {
	aint left, right;
	int oper;
	if (!ParseExpMul(p, left)) return 0;
	while ((oper = need(p, "+ - "))) {
		if (!ParseExpMul(p, right)) return 0;
		if ('-' == oper) right = -right;
		left += right;
	}
	nval = left;
	return 1;
}

static int ParseExpShift(char*& p, aint& nval) {
	aint left, right;
	uint32_t l;
	int oper;
	if (!ParseExpAdd(p, left)) return 0;
	while ((oper = need(p, "<<>>")) || (oper = needa(p, "shl", '<' + '<', "shr", '>' + '>'))) {
		if (oper == '>' + '>' && *p == '>') {
			++p;
			oper += '>';
		}
		if (!ParseExpAdd(p, right)) return 0;
		switch (oper) {
		case '<'+'<':
			left <<= right; break;
		case '>'+'>':
			left >>= right; break;
		case '>'+'>'+'>':
			l = left; l >>= right; left = l; break;
		default: Error("internal error", nullptr, FATAL); break;	// unreachable
		}
	}
	nval = left;
	return 1;
}

static int ParseExpMinMax(char*& p, aint& nval) {
	aint left, right;
	int oper;
	if (!ParseExpShift(p, left)) return 0;
	while ((oper = need(p, "<?>?"))) {
		if (!ParseExpShift(p, right)) return 0;
		switch (oper) {
		case '<'+'?':
			left = left < right ? left : right; break;
		case '>'+'?':
			left = left > right ? left : right; break;
		default: Error("internal error", nullptr, FATAL); break;	// unreachable
		}
	}
	nval = left;
	return 1;
}

static int ParseExpCmp(char*& p, aint& nval) {
	aint left, right;
	int oper;
	if (!ParseExpMinMax(p, left)) return 0;
	while ((oper = need(p, "<=>=< > "))) {
		if (!ParseExpMinMax(p, right)) return 0;
		switch (oper) {
		case '<':
			left = -(left < right); break;
		case '>':
			left = -(left > right); break;
		case '<'+'=':
			left = -(left <= right); break;
		case '>'+'=':
			left = -(left >= right); break;
		default: Error("internal error", nullptr, FATAL); break;	// unreachable
		}
	}
	nval = left;
	return 1;
}

static int ParseExpEqu(char*& p, aint& nval) {
	aint left, right;
	int oper;
	if (!ParseExpCmp(p, left)) return 0;
	while ((oper = need(p, "=_==!="))) {
		if (!ParseExpCmp(p, right)) return 0;
		left = (('!'+'=') == oper) ? -(left != right) : -(left == right);
	}
	nval = left;
	return 1;
}

static int ParseExpBitAnd(char*& p, aint& nval) {
	aint left, right;
	if (!ParseExpEqu(p, left)) return 0;
	while (need(p, "&_") || needa(p, "and", '&')) {
		if (!ParseExpEqu(p, right)) return 0;
		left &= right;
	}
	nval = left;
	return 1;
}

static int ParseExpBitXor(char*& p, aint& nval) {
	aint left, right;
	if (!ParseExpBitAnd(p, left)) return 0;
	while (need(p, "^ ") || needa(p, "xor", '^')) {
		if (!ParseExpBitAnd(p, right)) return 0;
		left ^= right;
	}
	nval = left;
	return 1;
}

static int ParseExpBitOr(char*& p, aint& nval) {
	aint left, right;
	if (!ParseExpBitXor(p, left)) return 0;
	while (need(p, "|_") || needa(p, "or", '|')) {
		if (!ParseExpBitXor(p, right)) return 0;
		left |= right;
	}
	nval = left;
	return 1;
}

static int ParseExpLogAnd(char*& p, aint& nval) {
	aint left, right;
	if (!ParseExpBitOr(p, left)) return 0;
	while (need(p, "&&")) {
		if (!ParseExpBitOr(p, right)) return 0;
		left = -(left && right);
	}
	nval = left;
	return 1;
}

static int ParseExpLogOr(char*& p, aint& nval) {
	aint left, right;
	if (!ParseExpLogAnd(p, left)) return 0;
	while (need(p, "||")) {
		if (!ParseExpLogAnd(p, right)) return 0;
		left = -(left || right);
	}
	nval = left;
	return 1;
}

static int ParseExpressionEntry(char*& p, aint& nval) {
	if (ParseExpLogOr(p, nval)) return 1;
	nval = 0;
	return 0;
}

int ParseExpression(char*& p, aint& nval) {
	// if relocation is active, do the full evaluation in syntax-error-OFF mode with alternative
	// label values, and remember the result (to compare it with regular evaluation afterward)
	aint relocationVal = 0;
	int relocationRes = 0;
	if (Relocation::isActive) {
		char* altP = p;
		bool osynerr = synerr;
		synerr = false;
		Relocation::areLabelsOffset = true;
		relocationRes = ParseExpressionEntry(altP, relocationVal);
		Relocation::areLabelsOffset = false;
		synerr = osynerr;
	}
	// if relocation is off, or the alternative run did finish already, do regular evaluation
	int res = ParseExpressionEntry(p, nval);
	// set the Relocation::isResultAffected if the two alternative results are different
	if (res && relocationRes) {
		const bool isAffected = (relocationVal != nval);
		Relocation::isResultAffected |= isAffected;
		Relocation::isRelocatable = isAffected && (Relocation::ALTERNATIVE_OFFSET == (relocationVal - nval));
	}
	return res;
}

int ParseExpressionNoSyntaxError(char*& lp, aint& val) {
	bool osynerr = synerr;
	synerr = false;
	int ret_val = ParseExpression(lp, val);
	synerr = osynerr;
	return ret_val;
}

// returns 0 on syntax error, 1 on expression which is not enclosed in parentheses
// 2 when whole expression is in [] or () (--syntax=b/B affects when "2" is reported)
int ParseExpressionMemAccess(char*& p, aint& nval) {
	const EBracketType bt = OpenBracket(p);
	// if round parenthesis starts the expression, calculate pointer where it ends (and move "p" back on "(")
	char* const expectedEndBracket = (BT_ROUND == bt) ? ParenthesesEnd(--p) : nullptr;
	if (!ParseExpression(p, nval)) return 0;	// evaluate expression
	if (BT_NONE == bt) return 1;				// no parentheses are always "value"
	if (BT_ROUND == bt) return (expectedEndBracket == p) ? 2 : 1;	// round parentheses are "memory" when end is as expected
	if (CloseBracket(p)) return 2;				// square brackets must be closed properly, then it is "memory"
	return 0;	// curly brackets are not detect by OpenBracket, but if they would, it would work same as square here
}

void ParseAlignArguments(char* & src, aint & alignment, aint & fill) {
	SkipBlanks(src);
	const char * const oldSrc = src;
	fill = -1;
	if (!ParseExpression(src, alignment)) {
		alignment = -1;
		return;
	}
	if (Relocation::isActive) {
		WarningById(W_RELOCATABLE_ALIGN);
	}
	// check if alignment value is power of two (0..15-th power only)
	if (alignment < 1 || (1<<15) < alignment || (alignment & (alignment-1))) {
		Error("[ALIGN] Illegal align", oldSrc, SUPPRESS);
		alignment = 0;
		return;
	}
	if (!comma(src)) return;
	if (!ParseExpressionEntry(lp, fill)) {
		Error("[ALIGN] fill-byte expected after comma", bp, IF_FIRST);
		fill = -1;
	} else if (fill < 0 || 255 < fill) {
		Error("[ALIGN] Illegal align fill-byte", oldSrc, SUPPRESS);
		fill = -1;
	}
}

static bool ReplaceDefineInternal(char* lp, char* const nl) {
	int definegereplaced = 0,dr;
	char* rp = nl,* nid,* ver;
	bool isDefDir = false;	// to remember if one of DEFINE-related directives was used
	bool afterNonAlphaNum, afterNonAlphaNumNext = true;
	char defarrayCountTxt[16] = { 0 };
	while (*lp && ((rp - nl) < LINEMAX)) {
		const char c1 = lp[0], c2 = lp[1];
		afterNonAlphaNum = afterNonAlphaNumNext;
		afterNonAlphaNumNext = !isalnum((byte)c1);
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
		if (c1 == ';' || (c1 == '/' && c2 == '/')) {
			// set empty eol line comment, if the source of data is still the original "line" buffer
			if (!eolComment && line <= lp && lp < line+LINEMAX) eolComment = lp;
			break;
		}

		// strings parsing
		if (afterNonAlphaNum && (c1 == '"' || c1 == '\'')) {
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

		if (!isLabelStart(lp, false)) {
			*rp++ = *lp++;
			continue;
		}

		// update "is define-related directive" for remainder of the line
		char* kp = lp;
		isDefDir |= afterNonAlphaNum && (cmphstr(kp, "define+") || cmphstr(kp, "define")
			|| cmphstr(kp, "undefine") || cmphstr(kp, "defarray+") || cmphstr(kp, "defarray")
			|| cmphstr(kp, "ifdef") || cmphstr(kp, "ifndef"));
		// if DEFINE-related directive was used, only macro-arguments are substituted
		// in the remaining part of the line, the define-based substitution is inhibited till EOL

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
			} else if (!isDefDir && canSubstituteInside && (ver = DefineTable.Get(nid))) {
				dr = 1;			// DEFINE substitution is possible
				//handle DEFARRAY case
				if (DefineTable.DefArrayList) {
					ver = nid;	// in case of some error, just copy the array id "as is"
					CStringsList* a = DefineTable.DefArrayList;
					while (White(*lp)) GrowSubIdByExtraChar(lp);
					aint val;
					if ('[' != *lp) Error("[ARRAY] Expression error", nextSubIdLp, SUPPRESS);
					if ('[' == *lp && '#' == lp[1] && ']' == lp[2]) {	// calculate size of defarray
						lp += 3;
						val = 0;
						while (a) {
							++val;
							a = a->next;
						}
						sprintf(defarrayCountTxt, "%d", val);
						ver = defarrayCountTxt;
					} else if ('[' == *lp && GrowSubIdByExtraChar(lp) && ParseExpressionNoSyntaxError(lp, val) && ']' == *lp) {
						++lp;
						while (0 < val && a) {
							a = a->next;
							--val;
						}
						if (val < 0 || NULL == a) {
							*ver = 0;			// substitute with empty string
							Error("[ARRAY] index not in 0..<Size-1> range", nextSubIdLp, SUPPRESS);
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
				while (*ver && ((rp - nl) < LINEMAX)) *rp++ = *ver++;		// replace the string into target buffer
				// reset subId parser to catch second+ subId in current Id
				ResetGrowSubId();
				nextSubIdLp = lp;
			}
			// continue with extending the subId, if there's still something to parse
		} while(islabchar(*lp));
	} // while(*lp)
	// add line terminator to the output buffer
	*rp++ = 0;
	if (LINEMAX <= (rp - nl)) {
		Error("line too long after macro expansion", nl, SUPPRESS);
	}
	// check if whole line is just blanks, then return just empty one
	rp = nl;
	if (SkipBlanks(rp)) *nl = 0;
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
	Error("Unable to finish substitions, line after 20th iteration", sline, SUPPRESS);
	return sline;
}

void SetLastParsedLabel(const char* label) {
	if (LastParsedLabel) free(LastParsedLabel);
	if (nullptr != label) {
		LastParsedLabel = STRDUP(label);
		if (nullptr == LastParsedLabel) ErrorOOM();
		LastParsedLabelLine = CompiledCurrentLine;
	} else {
		LastParsedLabel = nullptr;
		LastParsedLabelLine = 0;
	}
}

void ParseLabel() {
	if (White()) return;
	if (Options::syx.IsPseudoOpBOF && ParseDirective(true)) {
		if (!SkipBlanks()) Error("Unexpected", lp);
		return;
	}
	char temp[LINEMAX], * tp = temp, * ttp;
	aint val, equPageNum = LABEL_PAGE_UNDEFINED, smcOffset = 0;
	// copy the label name into `temp` array
	while (*lp && !White() && *lp != ':' && *lp != '=' && *lp != '+') {
		*tp = *lp; ++tp; ++lp;
	}
	*tp = 0;
	// handle the special SMC_offset syntax "<label>+<single_digit>"
	if ('+' == lp[0] && isdigit(byte(lp[1])) && !isdigit(byte(lp[2]))) {
		smcOffset = lp[1] - '0';
		lp += 2;
	}
	if (*lp == ':') ++lp;	// eat the optional colon after label
	tp = temp;
	SkipBlanks();
	IsLabelNotFound = false;
	if (isdigit((byte)*tp)) {
		if (smcOffset) {
			Error("Temporary label can't use SMC-offset");
			return;
		}
		ttp = tp;
		while (*ttp && isdigit((byte)*ttp)) ++ttp;
		if (*ttp) {
			Error("Invalid temporary label (not a number)", temp);
			return;
		}
		if (NeedEQU() || NeedDEFL()) {
			Error("Number labels are allowed as address labels only, not for DEFL/=/EQU", temp, SUPPRESS);
			return;
		}
		val = atoi(tp);
		if (!LocalLabelTable.InsertRefresh(val)) {
			Error("Temporary labels flow differs in this pass (missing/new temporary label or final pass source difference)");
		}
	} else {
		if (isMacroNext()) {
			if (smcOffset) Error("Macro name can't use SMC-offset");
			else SetLastParsedLabel(tp);	// store raw label into "last parsed" without adding module/etc
			return;					// and don't add it to labels table at all
		}
		bool IsDEFL = NeedDEFL(), IsEQU = NeedEQU();
		if (IsDEFL || IsEQU) {
			Relocation::isResultAffected = false;
			if (!ParseExpressionNoSyntaxError(lp, val)) {
				Error("Expression error", lp);
				val = 0;
			}
			if (IsLabelNotFound && IsDEFL) Error("Forward reference", NULL, EARLY);
			// check for explicit page defined by EQU
			if (IsEQU && comma(lp)) {
				if (!ParseExpressionNoSyntaxError(lp, equPageNum)) {
					Error("Expression error", lp);
					equPageNum = LABEL_PAGE_UNDEFINED;
				}
			}

			// after EQU/DEFL expressions there must be <EOL>, anything else is syntax error
			// this was added in v1.17.1 after realizing the line `label=$+1 and 7`
			// does evaluate whole "$+1 and 7" as expression, not as instruction `and`
			// (same problem exists with and/or/xor and if you have macro named after operator)
			if (!SkipBlanks(lp)) {
				Error("Unexpected", lp);
				SkipToEol(lp);
			}

		} else {
			int gl = 0;
			char* p = lp,* n;
			SkipBlanks(p);
			if (*p == '@') {
				++p; gl = 1;
			}
			if ((n = GetID(p)) && StructureTable.Emit(n, tp, p, gl)) {
				if (smcOffset) Error("Structure instance can't use SMC-offset");
				lp = p;
				// this was instancing STRUCT, make it also define "main" label for future "local" ones
				tp = ValidateLabel(tp, true);
				if (tp) delete[] tp;
				return;
			}
			val = CurAddress;
		}
		val += smcOffset;
		ttp = tp;
		if (!(tp = ValidateLabel(tp, true))) {
			return;
		}
		// Copy label name to last parsed label variable
		if (!IsDEFL) SetLastParsedLabel(tp);
		unsigned traits = (IsEQU ? LABEL_IS_EQU : 0) | (IsDEFL ? LABEL_IS_DEFL : 0) | (smcOffset ? LABEL_IS_SMC : 0);
		if (pass == LASTPASS) {

			SLabelTableEntry* label = LabelTable.Find(tp, true);
			if (nullptr == label && IsDEFL) {	// DEFL labels can be defined as late as needed (including pass3)
				if (LabelTable.Insert(tp, val, traits)) label = LabelTable.Find(tp, true);
			}
			if (nullptr == label) {		// should have been already defined before last pass
				Error("Label not found", tp);
				delete[] tp;
				return;
			}
			if (IsDEFL) {		//re-set DEFL value
				LabelTable.Insert(tp, val, traits);
			} else if (IsSldExportActive()) {
				// SLD (Source Level Debugging) tracing-data logging
				WriteToSldFile(IsEQU ? -1 : label->page, val, IsEQU ? 'D' : 'F', tp);	//version 0
				WriteToSldFile(IsEQU ? -1 : label->page, val, 'L', ExportLabelToSld(ttp, label));	//version 1
			}

			if (val != label->value) {
				char* buf = new char[LINEMAX];

				SPRINTF2(buf, LINEMAX, "previous value %u not equal %u", label->value, val);
				Warning("Label has different value in pass 3", buf);
				LabelTable.Update(tp, val);

				delete[] buf;
			}
		} else if (pass == 2 && !LabelTable.Insert(tp, val, traits, equPageNum)) {
			if (!LabelTable.Update(tp, val)) assert(false); // unreachable, update will always work after insert failed
		} else if (pass == 1 && !LabelTable.Insert(tp, val, traits, equPageNum)) {
			Error("Duplicate label", tp, EARLY);
		}

// TODO v2.x: this is too complicated in current version: Unreal/Cspect already expect
// EQU/DEFL to be current page or "ROM" = not a big deal as they did change in v1.x course already.
// But also struct labels are set as EQU ones, so this has to split, and many other details.
// (will also need more than LABEL_PAGE_UNDEFINED value to deal with more states)
// 		if (IsEQU && comma(lp)) {	// Device extension: "<label> EQU <address>,<page number>"
// 			if (!DeviceID) {
// 				Error("EQU can set page to label only in device mode", line);
// 				SkipToEol(lp);
// 			} else if (!ParseExpression(lp, oval)) {	// try to read page number into "oval"
// 				Error("Expression error", lp);
// 				oval = -1;
// 			} else if (oval < 0 || Device->PagesCount <= oval) {
// 				ErrorInt("Invalid page number", oval);
// 				oval = -1;
// 			} else {
// 				if (val < 0 || 0xFFFF < val) Warning("The EQU address is outside of 16bit range", line);
// 				CLabelTableEntry* equLabel = LabelTable.Find(tp, true);	// must be already defined + found
// 				equLabel->page = oval;			// set it's page number
// 			}
// 		}

		delete[] tp;
	}
}

int ParseMacro() {
	int gl = 0, r = 0;
	char* p = lp, *n;
	SkipBlanks(p);
	if (*p == '@') {
		gl = 1; ++p;
	}
	if (!(n = GetID(p))) {
		return 0;
	}

	if (!gl) r = MacroTable.Emit(n, p);		// global '@' operator inhibits macros
	if (r == 2) return 1;	// successfully emitted
	if (r == 1) {			// error reported
		lp = p;
		return 0;
	}

	// not a macro, see if it's structure
	if (StructureTable.Emit(n, nullptr, p, gl)) {
		lp = p;
		return 1;
	}

	return 0;
}

void ParseInstruction() {
	if ('@' == *lp) ++lp;		// skip single '@', if it was used to inhibit macro expansion
	if (ParseDirective()) return;
	Z80::GetOpCode();
}

static const byte win2dos[] = //taken from HorrorWord %)))
{
	0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF,
	0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF,
	0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xF0, 0xD8, 0xD9, 0xDA, 0xDB, 0xDC, 0xDD, 0xDE,
	0xDF, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF1, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0x20,
	0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F,
	0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F,
	0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF,
	0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEE, 0xEF
};

//#define DEBUG_COUT_PARSE_LINE

// returns 1 when already fully processed (part of DUP/etc)
int PrepareLine() {
	ListSilentOrExternalEmits();

	++CompiledCurrentLine;
	if (!RepeatStack.empty()) {
		SRepeatStack& dup = RepeatStack.top();
		if (!dup.IsInWork) {
			lp = line;
			CStringsList* f = new CStringsList(lp);
			dup.Pointer->next = f;
			dup.Pointer = f;
#ifdef DEBUG_COUT_PARSE_LINE
			fprintf(stderr, ">%d %d %c%ld-%d [%s]\n", pass, CurSourcePos.line,
					(!RepeatStack.empty() && RepeatStack.top().IsInWork ? '!' : '.'),RepeatStack.size(),
					(!RepeatStack.empty() ? RepeatStack.top().Level : 0), line);
#endif
			ParseDirective_REPT();
			return 1;
		}
	}
#ifdef DEBUG_COUT_PARSE_LINE
	fprintf(stderr, "|%d %d %c%ld-%d [%s]\n", pass, CurSourcePos.line,
			(!RepeatStack.empty() && RepeatStack.top().IsInWork ? '!' : '.'), RepeatStack.size(),
			(!RepeatStack.empty() ? RepeatStack.top().Level : 0), line);
#endif
	lp = ReplaceDefine(line);

#ifdef DEBUG_COUT_PARSE_LINE
	fprintf(stderr,"rdOut [%s]->[%s] %d\n", line, lp, comlin);
#endif

	// update current address by memory wrapping, current page, etc... (before the label is defined)
	if (DeviceID)	Device->CheckPage(CDevice::CHECK_NO_EMIT);
	ListAddress = CurAddress;

	if (!ConvertEncoding) {
		byte* lp2 = (byte*) lp;
		while (*lp2) {
			if (128 <= *lp2) {
				*lp2 = win2dos[(*lp2) - 128];
			}
			++lp2;
		}
	}
	return 0;
}

bool PrepareNonBlankMultiLine(char*& p) {
	// loop while the current line is blank-only (read further lines until EOF or non-blank char)
	while (SkipBlanks(p)) {
		// if inside macro system, but without any more macro-lines in buffer, act as if "EOF"
		// (to not leak into reading actual file while the macro is executing)
		if (listmacro && nullptr == lijstp) return false;
		// list the current (old) line
		ListFile();
		// read the next line
		if (!ReadLine()) return false;
		PrepareLine();
		p = lp;
	}
	return true;
}

void ParseLine(bool parselabels) {

	if (PrepareLine()) return;

	if (eolComment && IsSldExportActive()) SldTrackComments();

	if (!*lp) {
		char *srcNonWhiteChar = line;
		SkipBlanks(srcNonWhiteChar);
		// check if only "end-line" comment remained, treat that one as "empty" line too
		if (';' == srcNonWhiteChar[0] || ('/' == srcNonWhiteChar[0] && '/' == srcNonWhiteChar[1]))
			srcNonWhiteChar = lp;			// force srcNonWhiteChar to point to 0
		if (*srcNonWhiteChar || comlin) {	// non-empty source line turned into nothing
			ListFile(true);					// or empty source inside comment-block -> "skipped"
		} else {
			ListFile();						// empty source line outside of block-comment -> "normal"
		}
		return;
	}

	if (parselabels) ParseLabel();
	if (!SkipBlanks()) ParseMacro();
	if (!SkipBlanks()) ParseInstruction();
	if (!SkipBlanks()) Error("Unexpected", lp);
	ListFile();
}

void ParseLineSafe(bool parselabels) {
	char* tmp = NULL, * tmp2 = NULL;
	char* rp = lp;
	if (sline[0] > 0) {
		tmp = STRDUP(sline);
		if (tmp == NULL) ErrorOOM();
	}
	if (sline2[0] > 0) {
		tmp2 = STRDUP(sline2);
		if (tmp2 == NULL) ErrorOOM();
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

void ParseStructLabel(CStructure* st) {
	char* tp, temp[LINEMAX];
	if (PreviousIsLabel) {
		free(PreviousIsLabel);
		PreviousIsLabel = nullptr;
	}
	if (White()) {
		return;
	}
	tp = temp;
	if (*lp == '.') {
		++lp;
	}
	while (*lp && islabchar(*lp)) {
		*tp = *lp; ++tp; ++lp;
	}
	*tp = 0;
	if (*lp == ':') {
		++lp;
	}
	tp = temp; SkipBlanks();
	if (isdigit((byte)*tp)) {
		Error("[STRUCT] Number labels not allowed within structs"); return;
	}
	PreviousIsLabel = STRDUP(tp);
	if (PreviousIsLabel == NULL) ErrorOOM();
	st->AddLabel(tp);
}

void ParseStructMember(CStructure* st) {
	aint val, len;
	bp = lp;
	Relocation::isResultAffected = false;
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
		st->AddMember(new CStructureEntry2(st->noffset, len, val, false, SMEMBBLOCK));
		break;
	case SMEMBBYTE:
		if (!ParseExpression(lp, val)) {
			val = 0;
		} check8(val);
		st->AddMember(new CStructureEntry2(st->noffset, 1, val, false, SMEMBBYTE));
		break;
	case SMEMBWORD:
		{
			if (!ParseExpression(lp, val)) {
				val = 0;
			}
			check16(val);
			const bool isRelocatable = (Relocation::isResultAffected && Relocation::isRelocatable);
			st->AddMember(new CStructureEntry2(st->noffset, 2, val, isRelocatable, SMEMBWORD));
			Relocation::resolveRelocationAffected(INT_MAX);	// clear flags + warn when can't be relocated
		}
		break;
	case SMEMBD24:
		if (!ParseExpression(lp, val)) {
			val = 0;
		} check24(val);
		st->AddMember(new CStructureEntry2(st->noffset, 3, val, false, SMEMBD24));
		break;
	case SMEMBDWORD:
		if (!ParseExpression(lp, val)) {
			val = 0;
		}
		st->AddMember(new CStructureEntry2(st->noffset, 4, val, false, SMEMBDWORD));
		break;
	case SMEMBTEXT:
		{
			if (!ParseExpression(lp, len) || len < 1 || CStructureEntry2::TEXT_MAX_SIZE < len) {
				Error("[STRUCT] Expression for length of text expected (1..8192)");
				SkipToEol(lp);
				break;
			}
			byte* textData = new byte[len]();	// zero-initialized for stable binary results
			if (nullptr == textData) ErrorOOM();
			if (comma(lp)) {		// if comma then init data array explicitly
				GetStructText(lp, len, textData);
			} else if (SkipBlanks(lp)) {
				// if empty without comma, init with the zeroed values
			} else {
				Error("[STRUCT] Comma expected", lp, SUPPRESS);	// syntax error
			}
			st->AddMember(new CStructureEntry2(st->noffset, len, textData));
		}
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
		st->AddMember(new CStructureEntry2(st->noffset, bytesToAdvance, fill, false, SMEMBBLOCK));
		break;
	}
	default:
		char* pp = lp,* n;
		int gl = 0;
		CStructure* s;
		SkipBlanks(pp);
		if (*pp == '@') {
			++pp; gl = 1;
		}
		if ((n = GetID(pp)) && (s = StructureTable.zoek(n, gl))) {
			char* structName = st->naam;	// need copy of pointer so cmphstr can advance it in case of match
			if (cmphstr(structName, n)) {
				Error("[STRUCT] Can't include itself", NULL);
				SkipToEol(pp);
				lp = pp;
				break;
			}
			if (s->maxAlignment && ((~st->noffset + 1) & (s->maxAlignment - 1))) {
				// Inserted structure did use ALIGN in definition and it is misaligned here
				char warnTxt[LINEMAX];
				SPRINTF3(warnTxt, LINEMAX,
						 "Struct %s did use ALIGN %d in definition, but here it is misaligned by %d bytes",
						 s->naam, s->maxAlignment, ((~st->noffset + 1) & (s->maxAlignment - 1)));
				Warning(warnTxt);
			}
			lp = pp;
			st->CopyLabels(s);
			st->CopyMembers(s, lp);
		}
		break;
	}
	Relocation::checkAndWarn();
}

void ParseStructLine(CStructure* st) {
	++CompiledCurrentLine;
	lp = ReplaceDefine(line);
	if (!*lp) return;
	ParseStructLabel(st);
	if (SkipBlanks()) return;
	ParseStructMember(st);
	if (SkipBlanks()) return;
	if (*lp) Error("[STRUCT] Unexpected", lp);
}

//eof parser.cpp
