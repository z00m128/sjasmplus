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

int comnxtlin;
char dirDEFl[] = "def", dirDEFu[] = "DEF";

int ParseExpPrim(char*& p, aint& nval) {
	int res = 0;
	SkipBlanks(p);
	if (!*p) {
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
			Error("Address in {..} must be less than FFFEh"); return 0;
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
		if (synerr) {
			Error("Syntax error", p, IF_FIRST);
		}

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

static bool ReplaceDefineInternal(char* lp, char* const nl) {
	int definegereplaced = 0,dr;
	char* rp = nl,* nid,* kp,* ver,a;
	while ('o') {
		if (comlin || comnxtlin) {
			if (*lp == '*' && *(lp + 1) == '/') {
				*rp = ' '; ++rp;
				lp += 2; if (comnxtlin) {
						 	--comnxtlin;
						 } else {
						 	--comlin;
						 } continue;
			}
		}

		if (*lp == ';' && !comlin && !comnxtlin) {
			*rp = 0; return definegereplaced;
		}
		if (*lp == '/' && *(lp + 1) == '/' && !comlin && !comnxtlin) {
			*rp = 0; return definegereplaced;
		}
		if (*lp == '/' && *(lp + 1) == '*') {
			lp += 2; ++comnxtlin; continue;
		}

		if (*lp == '"' || *lp == '\'') {
			a = *lp;
			if (!comlin && !comnxtlin) {
				*rp = *lp; ++rp;
			}
			++lp;

			//detect "AF'"
			if (a != '\'' || ((*(lp - 2) != 'f' || *(lp - 3) != 'a') && (*(lp - 2) != 'F' || *(lp - 3) != 'A'))) {
				while ('o') {
					if (!*lp) {
						*rp = 0; return definegereplaced;
					}
					if (!comlin && !comnxtlin) {
						*rp = *lp;
					}
					if (*lp == a) {
						if (!comlin && !comnxtlin) {
							++rp;
						}
						++lp;
						break;
					}
					if (*lp == '\\') {
						++lp;
						if (!comlin && !comnxtlin) {
							++rp;
							*rp = *lp;
						}
					}
					if (!comlin && !comnxtlin) {
						++rp;
					}
					++lp;
				}
			}
			continue;
		}

		if (comlin || comnxtlin) {
			if (!*lp) {
				*rp = 0;
				break;
			}
			++lp;
			continue;
		}
		if (!isalpha((unsigned char) * lp) && *lp != '_') {
			if (!(*rp = *lp)) {
				break;
			}
			++rp;
			++lp;
			continue;
		}

		nid = GetID(lp); dr = 1;

		if (!(ver = DefineTable.Get(nid))) {
			if (!macrolabp || !(ver = MacroDefineTable.getverv(nid))) {
				dr = 0;
				ver = nid;
			}
		}

		if (DefineTable.DefArrayList) {
			CStringsList* a = DefineTable.DefArrayList;
			aint val;
			while (*(lp++) && (*lp <= ' ' || *lp == '['));
			if (!ParseExpression(lp, val)) {
				Error("[ARRAY] Expression error", lp, IF_FIRST);break;
			}
			while (*lp == ']' && *(lp++));
			if (val < 0) {
				Error("Number of cell must be positive", NULL, IF_FIRST);break;
			}
			val++;
			while (a && val) {
				STRCPY(ver, LINEMAX, a->string); // very danger!
				a = a->next;
				val--;
			}
			if (val && !a) {
				Error("Cell of array not found", NULL, IF_FIRST);break;
			}
		}

		if (dr) {
			kp = lp - strlen(nid);
			while (*(kp--) && *kp <= ' ');
			kp = kp - 4;
			if (cmphstr(kp, "ifdef")) {
				dr = 0; ver = nid;
			} else {
				--kp;
				if (cmphstr(kp, "ifndef")) {
					dr = 0; ver = nid;
				} else if (cmphstr(kp, "define")) {
					dr = 0; ver = nid;
				} else if (cmphstr(kp, "defarray")) {
					dr = 0; ver = nid;
				}
			}
		}

		if (dr) {
			definegereplaced = 1;
		}
		while ((*rp = *ver)) {
			++rp; ++ver;
		}
	}
	if (strlen(nl) > LINEMAX - 1) {
		Error("line too long after macro expansion", NULL, FATAL);
	}
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
	char* tp, temp[LINEMAX], * ttp;
	aint val, oval;
	if (White()) {
		return;
	}
	if (Options::IsPseudoOpBOF && ParseDirective(true)) return;
	tp = temp;
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
		if (NeedEQU() || NeedDEFL() || NeedField()) {
			Error("Number labels only allowed as address labels");
			return;
		}
		val = atoi(tp);
		//_COUT CurrentLine _CMDL " " _CMDL val _CMDL " " _CMDL CurAddress _ENDL;
		if (pass == 1) {
			LocalLabelTable.Insert(val, CurAddress);
		}
	} else {
		bool IsDEFL = 0;
		if (NeedEQU()) {
			if (!ParseExpression(lp, val)) {
				Error("Expression error", lp); val = 0;
			}
			if (IsLabelNotFound) {
				Error("Forward reference", NULL, EARLY);
			}
			/* begin add */
		} else if (NeedDEFL()) {
			if (!ParseExpression(lp, val)) {
				Error("Expression error", lp); val = 0;
			}
			if (IsLabelNotFound) {
				Error("Forward reference", NULL, EARLY);
			}
			IsDEFL = 1;
			/* end add */
		} else if (NeedField()) {
			aint nv;
			val = AddressOfMAP;
			synerr = 0;
			if (ParseExpression(lp, nv)) {
				AddressOfMAP += nv;
			}
			synerr = 1;
			if (IsLabelNotFound) {
				Error("Forward reference", NULL, EARLY);
			}
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
		if (!(tp = ValidateLabel(tp, 1))) {
			return;
		}
		// Copy label name to last parsed label variable
		if (!IsDEFL) {
			if (LastParsedLabel != NULL) {
				free(LastParsedLabel);
				LastParsedLabel = NULL;
			}
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
	  		/*if (val!=oval) Error("Label has different value in pass 2",temp);*/
			if (!IsDEFL && val != oval) {
				char* buf = new char[LINEMAX];

				SPRINTF2(buf, LINEMAX, "previous value %lu not equal %lu", oval, val);
	  			Warning("Label has different value in pass 3", buf);
				//_COUT "" _CMDL filename _CMDL ":" _CMDL CurrentLocalLine _CMDL ":(DEBUG)  " _CMDL "Label has different value in pass 2: ";
	  			//_COUT val _CMDL "!=" _CMDL oval _ENDL;
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

void ParseLine(bool parselabels) {
	/*++CurrentGlobalLine;*/
	comnxtlin = 0;
	if (!RepeatStack.empty()) {
		SRepeatStack& dup = RepeatStack.top();
		if (!dup.IsInWork) {
			lp = line;
			CStringsList* f = new CStringsList(lp, NULL);
			dup.Pointer->next = f;
			dup.Pointer = f;
// 			fprintf(stderr, ">%d %ld %c%ld-%d [%s]\n", pass, CurrentGlobalLine,
// 					(!RepeatStack.empty() && RepeatStack.top().IsInWork ? '!' : '.'),RepeatStack.size(),
// 					(!RepeatStack.empty() ? RepeatStack.top().Level : 0), line);
			ParseDirective_REPT();
			return;
		}
	}
// 	fprintf(stderr, "|%d %ld %c%ld-%d [%s]\n", pass, CurrentGlobalLine,
// 			(!RepeatStack.empty() && RepeatStack.top().IsInWork ? '!' : '.'), RepeatStack.size(),
// 			(!RepeatStack.empty() ? RepeatStack.top().Level : 0), line);
	lp = ReplaceDefine(line);
	if (!ConvertEncoding) {
		unsigned char* lp2 = (unsigned char*) lp;
		while (*(lp2++)) {
			if ((*lp2) >= 128) {
				*lp2 = win2dos[(*lp2) - 128];
			}
		}
	}
	if (comlin) {
		comlin += comnxtlin;
		ListFileSkip(line);
		return;
	}
	comlin += comnxtlin;
	if (!*lp) {
		ListFile();
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

	CompiledCurrentLine++;
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
	CStructureEntry2* smp;
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
		} else {
			val = 0;
		}
		check8(val);
		smp = new CStructureEntry2(st->noffset, len, val & 255, SMEMBBLOCK);
		st->AddMember(smp);
		break;
	case SMEMBBYTE:
		if (!ParseExpression(lp, val)) {
			val = 0;
		} check8(val);
		smp = new CStructureEntry2(st->noffset, 1, val, SMEMBBYTE);
		st->AddMember(smp);
		break;
	case SMEMBWORD:
		if (!ParseExpression(lp, val)) {
			val = 0;
		} check16(val);
		smp = new CStructureEntry2(st->noffset, 2, val, SMEMBWORD);
		st->AddMember(smp);
		break;
	case SMEMBD24:
		if (!ParseExpression(lp, val)) {
			val = 0;
		} check24(val);
		smp = new CStructureEntry2(st->noffset, 3, val, SMEMBD24);
		st->AddMember(smp);
		break;
	case SMEMBDWORD:
		if (!ParseExpression(lp, val)) {
			val = 0;
		}
		smp = new CStructureEntry2(st->noffset, 4, val, SMEMBDWORD);
		st->AddMember(smp);
		break;
	case SMEMBALIGN:
		if (!ParseExpression(lp, val)) {
			val = 4;
		}
		st->noffset += ((~st->noffset + 1) & (val - 1));
		break;
	default:
		char* pp = lp,* n;
		int gl = 0;
		CStructure* s;
		SkipBlanks(pp); if (*pp == '@') {
							++pp; gl = 1;
						}
		if ((n = GetID(pp)) && (s = StructureTable.zoek(n, gl))) {
			/* begin add */
			if (cmphstr(st->naam, n)) {
				Error("[STRUCT] Use structure itself", NULL, IF_FIRST);
				break;
			}
			/* end add */
			lp = pp;
			st->CopyLabels(s);
			st->CopyMembers(s, lp);
		}
		break;
	}
}

void ParseStructLine(CStructure* st) {
	comnxtlin = 0;
	lp = ReplaceDefine(line);
	if (comlin) {
		comlin += comnxtlin; return;
	}
	comlin += comnxtlin;
	if (!*lp) {
		return;
	}
	ParseStructLabel(st); if (SkipBlanks()) {
						  	return;
						  }
	ParseStructMember(st); if (SkipBlanks()) {
						   	return;
						   }
	if (*lp) {
		Error("[STRUCT] Unexpected", lp);
	}
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
