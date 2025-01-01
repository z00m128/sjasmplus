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

// io_tzx.h

#ifndef __IO_TZX
#define __IO_TZX

typedef struct STZXTurboBlock {
	word PilotPulseLen;
	word FirstSyncLen;
	word SecondSyncLen;
	word ZeroBitLen;
	word OneBitLen;
	word PilotToneLen;
	byte LastByteUsedBits;
	word PauseAfterMs;
} STZXTurboBlock;

void TZX_CreateEmpty(const std::filesystem::path & fname);
void TZX_AppendStandardBlock(const std::filesystem::path & fname, const byte* buf, const aint buflen, word pauseAfterMs, byte sync);
void TZX_AppendTurboBlock(const std::filesystem::path & fname, const byte* buf, const aint buflen, const STZXTurboBlock& turbo);
void TZX_AppendPauseBlock(const std::filesystem::path & fname, word pauseAfterMs);

#endif

//eof io_tzx.h
