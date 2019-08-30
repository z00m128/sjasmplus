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

TEST(Sanity) {			// just to verify the UnitTest++ test runner works
	CHECK_EQUAL(1, 1);
}

TEST(Reader_GetNumericValue_IntBased_1) {
	// for 100% coverage (this error state can't be currently reached through ASM file)
	aint val = 0xBADF00D;
	char p[1] = "";
	char* lp = p;
	CHECK_EQUAL(false, GetNumericValue_IntBased(lp, p, val, 10));
	CHECK_EQUAL(0, val);
}

TEST(Reader_GetNumericValue_IntBased_2) {
	// for 100% coverage (this error state can't be currently reached through ASM file)
	aint val = 0xBADF00D;
	char p[] = "42";
	char* lp = p;
	CHECK_EQUAL(false, GetNumericValue_IntBased(lp, p+3, val, 10));	// hit zero-terminator as digit
	CHECK_EQUAL(42, val);
}

TEST(Reader_GetNumericValue_IntBased_3) {
	// for 100% coverage (this error state can't be currently reached through ASM file)
	aint val = 0xBADF00D;
	char p[] = "41+";
	char* lp = p;
	CHECK_EQUAL(false, GetNumericValue_IntBased(lp, p+3, val, 10));	// hit non alpha-num char as digit
	CHECK_EQUAL(41, val);
}

#endif
