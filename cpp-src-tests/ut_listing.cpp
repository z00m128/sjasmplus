/*
Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
OF THIS SOFTWARE.
*/

#ifdef ADD_UNIT_TESTS

#include "../sjasm/sjdefs.h"
#include "UnitTest++/UnitTest++.h"

//sjio.cpp function (not in headers, but globally visible for unit testing)
void PrepareListLine(char* buffer, aint hexadd);

TEST(SjIo_PrepareListLine) {
	// PrepareListLine sets 24 chars long prologue of listing line (with empty source line)
	char listBuf[4*LINEMAX];
	// setup global state of assembler enough to make PrepareListLine work
	strcpy(line, "");
	substitutedLine = line;
	listmacro = 0;
	reglenwidth = 1;
	assert(sourcePosStack.empty());
	for (int inclevel = 11; inclevel--; ) sourcePosStack.push_back(TextFilePos());
	IncludeLevel = 0;
	PrepareListLine(listBuf, 0x1234);
	CHECK_EQUAL("0     1234              ", listBuf);

	IncludeLevel = 1;
	sourcePosStack[IncludeLevel].line = 1;
	PrepareListLine(listBuf, 0x1234);
	CHECK_EQUAL("1+    1234              ", listBuf);

	IncludeLevel = 10;
	sourcePosStack[IncludeLevel].line = 2;
	PrepareListLine(listBuf, 0x1234);
	CHECK_EQUAL("2+++++1234              ", listBuf);

	reglenwidth = 7;
	IncludeLevel = 0;
	sourcePosStack[IncludeLevel].line = 2;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL("    2 FEDC              ", listBuf);

	IncludeLevel = 10;
	sourcePosStack[IncludeLevel].line = 99999;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL("99999+FEDC              ", listBuf);

	IncludeLevel = 0;
	sourcePosStack[IncludeLevel].line = 100000;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL(":0000 FEDC              ", listBuf);

	IncludeLevel = 10;
	sourcePosStack[IncludeLevel].line = 119900;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL(";9900+FEDC              ", listBuf);

	IncludeLevel = 0;
	sourcePosStack[IncludeLevel].line = 179999;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL("A9999 FEDC              ", listBuf);

	IncludeLevel = 10;
	sourcePosStack[IncludeLevel].line = 779999;		// last non "~" line
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL("}9999+FEDC              ", listBuf);

	IncludeLevel = 0;
	sourcePosStack[IncludeLevel].line = 789999;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL("~9999 FEDC              ", listBuf);

	IncludeLevel = 10;
	sourcePosStack[IncludeLevel].line = 99999999;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL("~9999+FEDC              ", listBuf);

	// reglenwidth = 5 (maxpow10 = 100000, lines up to 99999)
	IncludeLevel = 0;
	reglenwidth = 5;
	sourcePosStack[IncludeLevel].line = 9999;
	PrepareListLine(listBuf, 0xEDCB);
	CHECK_EQUAL(" 9999 EDCB              ", listBuf);
	sourcePosStack[IncludeLevel].line = 10000;
	PrepareListLine(listBuf, 0xEDCB);
	CHECK_EQUAL("10000 EDCB              ", listBuf);
	sourcePosStack[IncludeLevel].line = 99999;
	PrepareListLine(listBuf, 0xEDCB);
	CHECK_EQUAL("99999 EDCB              ", listBuf);

	// reglenwidth = 6 (maxpow10 = 1000000, lines up to 999999) (first truncated one)
	reglenwidth = 6;
	sourcePosStack[IncludeLevel].line = 99999;
	PrepareListLine(listBuf, 0xEDCB);
	CHECK_EQUAL("99999 EDCB              ", listBuf);
	sourcePosStack[IncludeLevel].line = 100000;
	PrepareListLine(listBuf, 0xEDCB);
	CHECK_EQUAL(":0000 EDCB              ", listBuf);
	sourcePosStack.clear();
}

#endif
