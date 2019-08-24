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
