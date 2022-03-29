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

// relocate.cpp

#include "sjdefs.h"

// local implementation stuff (shouldn't be visible through the header)
namespace Relocation {
	// when some part of opcode needs relocation, add its offset to the relocation table
	static void addOffsetToRelocate(const aint offset);

	static void refreshMaxTableCount();

	// local implementation specific data
	static TextFilePos startPos;				// sourcefile position of last correct RELOCATE_START
	static size_t maxTableCount = 0;			// maximum count of relocation data
	static std::vector<word> offsets;			// offsets collected during current pass
	static std::vector<word> offsetsPrevious;	// offsets from pass2 (to be exported if pass3 is incomplete)
	static bool warnAboutContentChange = false;	// if any change in content between passes should be reported

	// public API variables
	bool isActive = false;			// when inside relocation block
	bool areLabelsOffset = false;	// when the Labels should return the alternative value
	bool isResultAffected = false;	// when one of previous expression results was affected by it
	bool isRelocatable = false;		// when isResultAffected && difference was precisely "+offset"
}

// when some part of opcode needs relocation, add its offset to the relocation table
static void Relocation::addOffsetToRelocate(const aint offset) {
	// if table was already emitted from previous pass copy, warn about value discrepancies
	if (warnAboutContentChange) {
		const size_t newIndex = offsets.size();
		if (offsetsPrevious.size() <= newIndex || offsetsPrevious[newIndex] != offset) {
			Warning("Relocation table seems internally inconsistent", "table content differs in last pass");
			warnAboutContentChange = false;
		}
	}
	// add new offset to the relocation table
	offsets.push_back(offset);
}

void Relocation::resolveRelocationAffected(const aint opcodeRelOffset) {
	if (!isResultAffected) return;
	isResultAffected = false;				// mark as processed
	// the machine code is affected by relocation, check if the difference is relocatable, add to table
	if (isRelocatable) {
		if (INT_MAX != opcodeRelOffset) {
			const aint address = (DISP_INSIDE_RELOCATE == PseudoORG) ? adrdisp : CurAddress;
			addOffsetToRelocate(address + opcodeRelOffset);
		}
		return;
	}
	// difference is not fixable by simple "+offset" relocator, report it as warning
	WarningById(W_REL_DIVERTS);
}

bool Relocation::checkAndWarn(bool doError) {
	// if nothing is affected by relocation, do nothing here
	if (!Relocation::isResultAffected) return false;
	// some result did set the "affected" flag, warn about it
	Relocation::isResultAffected = false;
	if (doError) {
		Error("Relocation makes one of the expressions unstable, use non-relocatable values only");
	} else {
		WarningById(W_REL_UNSTABLE);
	}
	return true;
}

// directives implementation

static void Relocation::refreshMaxTableCount() {
	if (maxTableCount < offsets.size()) {
		maxTableCount = offsets.size();
	}
	// add the relocate_count and relocate_size symbols only when RELOCATE feature was used
	if (Relocation::isActive || maxTableCount) {
		LabelTable.Insert("relocate_count", maxTableCount, LABEL_IS_DEFL);
		LabelTable.Insert("relocate_size", maxTableCount * 2, LABEL_IS_DEFL);
	}
}

void Relocation::dirRELOCATE_START() {
	if (isActive) {
		char errTxt[LINEMAX];
		SPRINTF2(errTxt, LINEMAX, "Relocation block already started at: %s(%d)",
				 startPos.filename, startPos.line);
		Error(errTxt);
		return;
	}
	isActive = true;
	startPos = CurSourcePos;
	refreshMaxTableCount();
}

void Relocation::dirRELOCATE_END() {
	if (!isActive) {
		Error("Relocation block start for this end is missing");
		return;
	}
	if (DISP_INSIDE_RELOCATE == PseudoORG) {
		Error("End the current DISP block first");
		return;
	}
	isActive = false;
	refreshMaxTableCount();
}

void Relocation::dirRELOCATE_TABLE() {
	aint subtract_offset = 0;
	if (!SkipBlanks(lp)) {	// should be either empty remaining of line, or <subtract_offset>
		if (!ParseExpressionNoSyntaxError(lp, subtract_offset)) {
			Error("[RELOCATE_TABLE] Syntax error in <subtract_offset>", bp, SUPPRESS);
			return;
		}
	}
	refreshMaxTableCount();
	// dump the table into machine code output
	for (size_t offsetIndex = 0; offsetIndex < maxTableCount; ++offsetIndex) {
		// select offset from current pass table if possible, but use "offsetsPrevious" as backup
		const auto offset = (offsetIndex < offsets.size()) ? offsets[offsetIndex] : offsetsPrevious[offsetIndex];
		EmitWord(offset - subtract_offset);
	}
	warnAboutContentChange = (LASTPASS == pass);	// set in last pass to check consistency
}

void Relocation::InitPass() {
	// check if the relocation block is still open (missing RELOCATION_END in source)
	if (isActive) {
		TextFilePos oldCurSourcePos = CurSourcePos;
		CurSourcePos = startPos;
		Error("Missing end of relocation block started here");
		CurSourcePos = oldCurSourcePos;
	}
	// keep copy of final offsets table from previous pass
	offsetsPrevious = offsets;
	// set the final count as the new maximum count (doesn't matter if it is smaller/bigger than old)
	maxTableCount = offsets.size();
	// clear the table for next pass and init the state
	offsets.clear();
	isActive = false;
}

//eof relocate.cpp
