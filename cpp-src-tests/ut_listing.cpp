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
	CurSourcePos.line = 0;
	IncludeLevel = 0;
	PrepareListLine(listBuf, 0x1234);
	CHECK_EQUAL("0     1234              ", listBuf);

	CurSourcePos.line = 1;
	IncludeLevel = 1;
	PrepareListLine(listBuf, 0x1234);
	CHECK_EQUAL("1+    1234              ", listBuf);

	CurSourcePos.line = 2;
	IncludeLevel = 10;
	PrepareListLine(listBuf, 0x1234);
	CHECK_EQUAL("2+++++1234              ", listBuf);

	reglenwidth = 7;
	CurSourcePos.line = 2;
	IncludeLevel = 0;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL("    2 FEDC              ", listBuf);

	CurSourcePos.line = 99999;
	IncludeLevel = 10;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL("99999+FEDC              ", listBuf);

	CurSourcePos.line = 100000;
	IncludeLevel = 0;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL(":0000 FEDC              ", listBuf);

	CurSourcePos.line = 119900;
	IncludeLevel = 10;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL(";9900+FEDC              ", listBuf);

	CurSourcePos.line = 179999;
	IncludeLevel = 0;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL("A9999 FEDC              ", listBuf);

	CurSourcePos.line = 779999;		// last non "~" line
	IncludeLevel = 10;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL("}9999+FEDC              ", listBuf);

	CurSourcePos.line = 789999;
	IncludeLevel = 0;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL("~9999 FEDC              ", listBuf);

	CurSourcePos.line = 99999999;
	IncludeLevel = 10;
	PrepareListLine(listBuf, 0xFEDC);
	CHECK_EQUAL("~9999+FEDC              ", listBuf);
}

#endif
