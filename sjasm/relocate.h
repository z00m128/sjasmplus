/*

  SjASMPlus Z80 Cross Compiler - modified - RELOCATE extension

  Copyright (c) 2006 Sjoerd Mastijn (original SW)
  Copyright (c) 2020 Peter Ped Helcmanovsky (RELOCATE extension)

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

// relocate.h

#ifndef __RELOCATE_H__
#define __RELOCATE_H__

namespace Relocation {
	constexpr aint ALTERNATIVE_OFFSET = -0x0201;

	extern bool isActive;			// when inside relocation block
	extern bool areLabelsOffset;	// when labels should evaluate to alternative values

	// when one of previous expression results was affected by alternative values
	extern bool isResultAffected;	// cumulative for all expression evaluation calls since last clear

	// when isResultAffected && can be relocated by simple +offset
	extern bool isRelocatable;		// valid value only for last expression evaluated

	// when some part of opcode needs relocation, add its offset to the relocation table
	void addOffsetToRelocate(const aint offset);

	//convenience method to add particular spot in incoming machine code + clear the flag
	void resolveRelocationAffected(const int opcodeRelOffset);
	void checkAndWarn();

	// directives implementation
	void dirRELOCATE_START();
	void dirRELOCATE_END();
	void dirRELOCATE_TABLE();

	void InitPass();
}

#endif

//eof relocate.h
