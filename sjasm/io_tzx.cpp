/*

  SjASMPlus Z80 Cross Compiler - modified - TZX extension

  Copyright (c) 2006 Sjoerd Mastijn (original SW)

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

#include "sjdefs.h"

namespace TZXBlockId {
	constexpr byte Standard = 0x10;
	constexpr byte Turbo = 0x11;
	constexpr byte Pause = 0x20;
}

void TZX_CreateEmpty(const char* fname) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "wb")) {
		Error("[TZX] Error opening file for write", fname, FATAL);
	}

	constexpr byte tzx_major_version = 1;
	constexpr byte tzx_minor_version = 10;
	const char magic[10] = {
		'Z', 'X', 'T', 'a', 'p', 'e', '!',
		0x1A,
		tzx_major_version,  tzx_minor_version
	};

	fwrite(magic, 1, 10, ff);
	fclose(ff);
}

void TZX_AppendPauseBlock(const char* fname, word pauseAfterMs) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "a+b")) {
		Error("[TZX] Error opening file for append", fname, FATAL);
	}
	fputc(TZXBlockId::Pause, ff); // block id

	fputc(pauseAfterMs & 0xFF, ff);
	fputc(pauseAfterMs >> 8, ff);
	fclose(ff);
}

void TZX_AppendStandardBlock(const char* fname, const byte* buf, const aint buflen, word pauseAfterMs, byte sync) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "a+b")) {
		Error("[TZX] Error opening file for append", fname, FATAL);
	}

	const aint totalDataLen = buflen + 2; // + sync byte + checksum

	fputc(TZXBlockId::Standard, ff); // block id

	fputc(pauseAfterMs & 0xFF, ff); // block header
	fputc(pauseAfterMs >> 8, ff);
	fputc(totalDataLen & 0xFF, ff);
	fputc(totalDataLen >> 8, ff);

	fputc(sync, ff); // sync pattern
	fwrite(buf, 1, buflen, ff); // payload
	byte check = sync;
	for (aint i = 0; i < buflen; ++i) check ^= buf[i];
	fputc(check, ff); // checksum
	fclose(ff);
}

void TZX_AppendTurboBlock(const char* fname, const byte* buf, const aint buflen, const STZXTurboBlock& turbo) {
	FILE* ff;
	if (!FOPEN_ISOK(ff, fname, "a+b")) {
		Error("[TZX] Error opening file for append", fname, FATAL);
	}

	fputc(TZXBlockId::Turbo, ff); // block id

	fputc(turbo.PilotPulseLen & 0xFF, ff); // block header
	fputc(turbo.PilotPulseLen >> 8, ff);
	fputc(turbo.FirstSyncLen & 0xFF, ff);
	fputc(turbo.FirstSyncLen >> 8, ff);
	fputc(turbo.SecondSyncLen & 0xFF, ff);
	fputc(turbo.SecondSyncLen >> 8, ff);
	fputc(turbo.ZeroBitLen & 0xFF, ff);
	fputc(turbo.ZeroBitLen >> 8, ff);
	fputc(turbo.OneBitLen & 0xFF, ff);
	fputc(turbo.OneBitLen >> 8, ff);
	fputc(turbo.PilotToneLen & 0xFF, ff);
	fputc(turbo.PilotToneLen >> 8, ff);
	fputc(turbo.LastByteUsedBits & 0xFF, ff);
	fputc(turbo.PauseAfterMs & 0xFF, ff);
	fputc(turbo.PauseAfterMs >> 8, ff);
	fputc(buflen & 0xFF, ff); // total data len is a 24-bit number, LSB first
	fputc(buflen >> 8, ff);
	fputc(buflen >> 16, ff);

	// payload
	fwrite(buf, 1, buflen, ff);
	fclose(ff);
}

// eof io_tzx.cpp
