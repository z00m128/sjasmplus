/*

  SjASMPlus Z80 Cross Compiler

  This is modified sources of SjASM by Aprisobal - aprisobal@tut.by

  Copyright (c) 2005 Sjoerd Mastijn

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

// parser.h

int ParseExpression(char*& lp, aint& val);
int ParseExpressionNoSyntaxError(char*& lp, aint& val);

// returns 0 on syntax error, 1 on expression which is not enclosed in parentheses
// 2 when whole expression is in [] or () (--syntax=b/B affects when "2" is reported)
int ParseExpressionMemAccess(char*& p, aint& nval);

void ParseAlignArguments(char* & src, aint & alignment, aint & fill);
int ParseDirective(bool beginningOfLine = 0);
int ParseDirective_REPT();
void ParseInstruction();
char* ReplaceDefine(char* lp);
void SetLastParsedLabel(const char* label);
int PrepareLine();		// initial part of ParseLine, before the actual content parsing logic starts

/**
 * @brief Reads and prepares for parsing new lines until non-blank char is encountered (producing
 * listing file along).
 *
 * WARNING - this is pushing slightly beyond the original architecture of SjASMPlus, affecting
 * global state like `lp, line, ...`, so it's *NOT* possible to "roll-back" from this step, this
 * is one-way ticket in terms of lines parsing.
 *
 * @param p parsing pointer (will be adjusted for new line read)
 * @return bool false when no more lines available, true when non-blank char is ready
 */
bool PrepareNonBlankMultiLine(char*& p);

void ParseLine(bool = true);
void ParseLineSafe(bool = true);
void ParseStructLine(CStructure* st);
uint32_t LuaCalculate(const char *str);
void LuaParseLine(const char *str);
void LuaParseCode(const char *str);

template <int argsN> bool getIntArguments(char*& lp, aint (&args)[argsN], const bool (&argOptional)[argsN]) {
	for (int i = 0; i < argsN; ++i) {
		if (0 < i && !comma(lp)) return argOptional[i];
		aint val;				// temporary variable to preserve original value in case of error
		if (!ParseExpression(lp, val)) return (0 == i) && argOptional[i];
		args[i] = val;
	}
	return !comma(lp);
}

//eof parser.h
