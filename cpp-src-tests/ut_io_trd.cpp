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

TEST(SjIoTrd_FilenameToBytes) {
	// the ones with (?) are ad-hoc and maybe not the best possible choice
	{	//(?) empty input string -> all spaces name
		const char fname[LINEMAX] = { 0 };
		const byte expected[12] = { "         " };
		byte binName[12] = { 0 };
		int length = 1234;
		CHECK_EQUAL(INVALID_EXTENSION, TRD_FileNameToBytes(fname, binName, length));
		CHECK_EQUAL(9, length);
		CHECK_ARRAY_EQUAL(expected, binName, 12);
	}

	{	// short name without extension
		const char fname[LINEMAX] = { "a" };
		const byte expected[12] = { "a        " };
		byte binName[12] = { 0 };
		int length = 1234;
		CHECK_EQUAL(INVALID_EXTENSION, TRD_FileNameToBytes(fname, binName, length));
		CHECK_EQUAL(9, length);
		CHECK_ARRAY_EQUAL(expected, binName, 12);
	}

	{	// short name with extension
		const char fname[LINEMAX] = { "a.a" };
		const byte expected[12] = { "a       a" };
		byte binName[12] = { 0 };
		int length = 1234;
		CHECK_EQUAL(INVALID_EXTENSION, TRD_FileNameToBytes(fname, binName, length));
		CHECK_EQUAL(9, length);
		CHECK_ARRAY_EQUAL(expected, binName, 12);
	}

	{	// short name with valid extension "B"
		const char fname[LINEMAX] = { "a.B" };
		const byte expected[12] = { "a       B" };
		byte binName[12] = { 0 };
		int length = 1234;
		CHECK_EQUAL(OK, TRD_FileNameToBytes(fname, binName, length));
		CHECK_EQUAL(9, length);
		CHECK_ARRAY_EQUAL(expected, binName, 12);
	}

	{	// short name with long extension (but only two letters)
		const char fname[LINEMAX] = { "a.CI" };
		const byte expected[12] = { "a       CI " };
		byte binName[12] = { 0 };
		int length = 1234;
		CHECK_EQUAL(THREE_LETTER_EXTENSION, TRD_FileNameToBytes(fname, binName, length));
		CHECK_EQUAL(11, length);
		CHECK_ARRAY_EQUAL(expected, binName, 12);
	}

	{	// short name with long extension
		const char fname[LINEMAX] = { "a.mp3" };
		const byte expected[12] = { "a       mp3" };
		byte binName[12] = { 0 };
		int length = 1234;
		CHECK_EQUAL(THREE_LETTER_EXTENSION, TRD_FileNameToBytes(fname, binName, length));
		CHECK_EQUAL(11, length);
		CHECK_ARRAY_EQUAL(expected, binName, 12);
	}

	{	// short name with too long extension
		const char fname[LINEMAX] = { "img.jpeg" };
		const byte expected[12] = { "img     jpe" };
		byte binName[12] = { 0 };
		int length = 1234;
		CHECK_EQUAL(THREE_LETTER_EXTENSION, TRD_FileNameToBytes(fname, binName, length));
		CHECK_EQUAL(11, length);
		CHECK_ARRAY_EQUAL(expected, binName, 12);
	}

	{	// too long name with valid extension "C"
		const char fname[LINEMAX] = { "longername.C" };
		const byte expected[12] = { "longernaC" };
		byte binName[12] = { 0 };
		int length = 1234;
		CHECK_EQUAL(OK, TRD_FileNameToBytes(fname, binName, length));
		CHECK_EQUAL(9, length);
		CHECK_ARRAY_EQUAL(expected, binName, 12);
	}

	{	// 8 letters name with valid ext. "D"
		const char fname[LINEMAX] = { "12345678.D" };
		const byte expected[12] = { "12345678D" };
		byte binName[12] = { 0 };
		int length = 1234;
		CHECK_EQUAL(OK, TRD_FileNameToBytes(fname, binName, length));
		CHECK_EQUAL(9, length);
		CHECK_ARRAY_EQUAL(expected, binName, 12);
	}

	{	// 8 letters name with valid ext. "#"
		const char fname[LINEMAX] = { "_!@#$%^&.#" };
		const byte expected[12] = { "_!@#$%^&#" };
		byte binName[12] = { 0 };
		int length = 1234;
		CHECK_EQUAL(OK, TRD_FileNameToBytes(fname, binName, length));
		CHECK_EQUAL(9, length);
		CHECK_ARRAY_EQUAL(expected, binName, 12);
	}

	{	//(?) name with dots inside is shortened to only first word
		const char fname[LINEMAX] = { "a.b.c.d.C" };
		const byte expected[12] = { "a       C" };
		byte binName[12] = { 0 };
		int length = 1234;
		CHECK_EQUAL(OK, TRD_FileNameToBytes(fname, binName, length));
		CHECK_EQUAL(9, length);
		CHECK_ARRAY_EQUAL(expected, binName, 12);
	}
}

#endif
