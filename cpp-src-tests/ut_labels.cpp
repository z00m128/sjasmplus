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

TEST(Reader_isLabelCharacter) {
	for (const char testch : "_.?!#@") {
		if (!testch) break;
		CHECK_EQUAL(1, islabchar(testch));
	}
	for (char testch = 'A'; testch <= 'Z'; ++testch) {
		CHECK_EQUAL(1, islabchar(testch));
		CHECK_EQUAL(1, islabchar(testch+0x20));	//lowercase
	}
	for (char testch = '0'; testch <= '9'; ++testch) {
		CHECK_EQUAL(1, islabchar(testch));
	}
	for (const char testch : "`~$%^&*()-=+\\|[]{}\"';:/,<>") {	// will test also zero value
		CHECK_EQUAL(0, islabchar(testch));
	}
}

TEST(Reader_isLabelStart) {
	for (const char testch : "_") {
		if (!testch) break;
		CHECK_EQUAL(1, isLabelStart(&testch, false));
	}
	for (char testch = 'A'; testch <= 'Z'; ++testch) {
		CHECK_EQUAL(1, isLabelStart(&testch, false));
	}
	for (char testch = 'a'; testch <= 'z'; ++testch) {
		CHECK_EQUAL(1, isLabelStart(&testch, false));
	}
	for (char testch = '0'; testch <= '9'; ++testch) {
		CHECK_EQUAL(0, isLabelStart(&testch, false));
	}
	for (const char testch : ".?!#@`~$%^&*()-=+\\|[]{}\"';:/,<>") {	// will test also zero value
		CHECK_EQUAL(0, isLabelStart(&testch, false));
	}
	char m1 = -1;
	CHECK_EQUAL(0, isLabelStart(&m1, false));
	// with modifiers ("." for local, "@" for global label) enabled:
	CHECK_EQUAL(0, isLabelStart("", true));
	CHECK_EQUAL(0, isLabelStart(".", true));
	CHECK_EQUAL(0, isLabelStart("..", true));
	CHECK_EQUAL(0, isLabelStart(".@", true));
	CHECK_EQUAL(0, isLabelStart(".0", true));
	CHECK_EQUAL(0, isLabelStart(".?", true));
	CHECK_EQUAL(0, isLabelStart(".!", true));
	CHECK_EQUAL(0, isLabelStart(".#", true));
	CHECK_EQUAL(0, isLabelStart("@", true));
	CHECK_EQUAL(0, isLabelStart("@.", true));
	CHECK_EQUAL(0, isLabelStart("@@", true));
	CHECK_EQUAL(0, isLabelStart("@0", true));
	CHECK_EQUAL(0, isLabelStart("@?", true));
	CHECK_EQUAL(0, isLabelStart("@!", true));
	CHECK_EQUAL(0, isLabelStart("@#", true));
	// valid starts of label
	CHECK_EQUAL(1, isLabelStart("._", true));
	CHECK_EQUAL(1, isLabelStart(".A", true));
	CHECK_EQUAL(1, isLabelStart(".a", true));
	CHECK_EQUAL(1, isLabelStart("@_", true));
	CHECK_EQUAL(1, isLabelStart("@A", true));
	CHECK_EQUAL(1, isLabelStart("@a", true));
}

#endif
