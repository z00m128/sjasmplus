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

// reader.h

int White();
void SkipParam(char*&); /* added */
int SkipBlanks();
void SkipBlanks(char*& p);
int NeedEQU();
int NeedDEFL(); /* added */
int NeedField();
char* GetID(char*& p);
char* getinstr(char*& p);
int comma(char*& p);
int oparen(char*& p, char c);
int cparen(char*& p);
char* getparen(char* p);
int check8(aint val); /* changes applied from SjASM 0.39g */
int check8o(long val); /* changes applied from SjASM 0.39g */
int check16(aint val); /* changes applied from SjASM 0.39g */
int check24(aint val); /* changes applied from SjASM 0.39g */
int need(char*& p, char c);
int need(char*& p, char* c);
int needa(char*& p, char* c1, int r1, char* c2 = 0, int r2 = 0, char* c3 = 0, int r3 = 0);
int GetConstant(char*& op, aint& val);
int GetCharConst(char*& p, aint& val);
int GetCharConstChar(char*& op, aint& val);
int GetCharConstCharSingle(char*& op, aint& val); /* added */
int GetBytes(char*& p, int e[], int add, int dc);
int cmphstr(char*& p1, char* p2);
char* GetFileName(char*& p);
char* GetHobetaFileName(char*& p); /* added */
int needcomma(char*& p);
int needbparen(char*& p);
int islabchar(char p);
EStructureMembers GetStructMemberId(char*& p);
//eof reader.h

