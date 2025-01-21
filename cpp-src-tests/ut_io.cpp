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

TEST(SjIo_ConstructDefaultFilename) {
	// verify the global sourceFiles variable is empty for this unit testing
	CHECK_EQUAL(0UL, sourceFiles.size());
	// check the "checkIfDestIsEmpty" argument functionality, and default basename "asm"
	std::filesystem::path fname {"x"};
	ConstructDefaultFilename(fname, ".ext");
	CHECK_EQUAL("x", fname);
	ConstructDefaultFilename(fname, ".ext", true);
	CHECK_EQUAL("x", fname);
	ConstructDefaultFilename(fname, ".ext", false);
	CHECK_EQUAL("asm.ext", fname);
	fname.clear();
	ConstructDefaultFilename(fname, ".ext");
	CHECK_EQUAL("asm.ext", fname);
	// check if first explicit filename is picked
	sourceFiles.push_back(SSource(1));
	ConstructDefaultFilename(fname, ".ext", false);
	CHECK_EQUAL("asm.ext", fname);
	sourceFiles.push_back(SSource(".f1.asm"));
	ConstructDefaultFilename(fname, ".ext", false);
	CHECK_EQUAL(".f1.ext", fname);
	sourceFiles.push_back(SSource("f2.asm"));
	ConstructDefaultFilename(fname, ".ext", false);
	CHECK_EQUAL(".f1.ext", fname);
	// empty the global sourceFiles again
	sourceFiles.clear();
}

#endif
