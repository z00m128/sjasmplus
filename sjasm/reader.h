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

#pragma once

#include <array>

enum EDelimiterType { DT_NONE, DT_QUOTES, DT_APOSTROPHE, DT_ANGLE, DT_COUNT };
enum EBracketType { BT_NONE, BT_ROUND, BT_CURLY, BT_SQUARE, BT_COUNT };

bool White(const char c);
bool White();
void SkipParam(char*&);
int SkipBlanks(char*& p);
int SkipBlanks();
void SkipToEol(char*& p);
int NeedEQU();
int NeedDEFL();
bool NeedIoC();
bool isMacroNext();				// checks if ".macro" directive is ahead (but doesn't consume it)
char* GetID(char*& p);
void ResetGrowSubId();
char* GrowSubId(char* & p);
char* GrowSubIdByExtraChar(char* & p);	// force grow even by non-label char
char* getinstr(char*& p);
bool anyComma(char*& p);		// eats any comma (even one of double-commas)
bool comma(char*& p);			// eats single comma, but not if double-comma is ahead
bool doubleComma(char* & p);
bool nonMaComma(char* & p);		// eats single comma only if multi-arg is configured to non-comma
bool relaxedMaComma(char* & p);	// checks multi-arg comma (double/single), but also eats single comma
EBracketType OpenBracket(char*& p);
int CloseBracket(char*& p);
char* ParenthesesEnd(char* p);
int check8(aint val);
int check8o(aint val);
int check16(aint val);
int check16u(aint val);
int check24(aint val);
void checkLowMemory(byte lowByte, byte hiByte);
int need(char*& p, char c);
int need(char*& p, const char* c);
int needa(char*& p, const char* c1, int r1, const char* c2 = 0, int r2 = 0, const char* c3 = 0, int r3 = 0, bool allowParenthesisEnd = false);
bool GetNumericValue_ProcessLastError(const char* const srcLine);
bool GetNumericValue_TwoBased(char*& p, const char* const pend, aint& val, const int shiftBase);
bool GetNumericValue_IntBased(char*& p, const char* const pend, aint& val, const int base);
int GetConstant(char*& op, aint& val);
int GetCharConst(char*& p, aint& val);
int GetCharConstInDoubleQuotes(char*& op, aint& val);
int GetCharConstInApostrophes(char*& op, aint& val);
template <class strT> int GetCharConstAsString(char* & p, strT e[], int & ei, int max_ei = 128, int add = 0);
int GetBytes(char*& p, int e[], int add, int dc);
void GetStructText(char*& p, aint len, byte* data, const byte* initData = nullptr);	// initData indicate "{}" is required for multi-value init
int GetBits(char*& p, int e[]);
int GetBytesHexaText(char*& p, int e[]);
int cmphstr(char*& p1, const char* p2, bool allowParenthesisEnd = false);   // p2 must be lowercase to match both cases
std::pair<std::string, EDelimiterType> GetDelimitedStringEx(char*& p);      // get some string within delimiters (none, quotes, apostrophes, chevron)
std::string GetDelimitedString(char*& p);                                   // get some string within delimiters (none, quotes, apostrophes, chevron)
std::filesystem::path GetFileName(char*& p, const std::filesystem::path & pathPrefix = ""); // get string in delimiters, remember delimiter, convert slashes, prepend pathPrefix
std::filesystem::path GetOutputFileName(char*& p);                          // GetFileName with pathPrefix = OutPrefix
EDelimiterType GetDelimiterOfLastFileName();                                // DT_NONE if no GetFileName was called
bool isLabelStart(const char *p, bool modifiersAllowed = true);
int islabchar(char p);
EStructureMembers GetStructMemberId(char*& p);
EDelimiterType DelimiterBegins(char*& src, const std::array<EDelimiterType, 3> delimiters, bool advanceSrc = true);
EDelimiterType DelimiterAnyBegins(char*& src, bool advanceSrc = true);
int GetMacroArgumentValue(char* & src, char* & dst);
