/* 

  SjASMPlus Z80 Cross Compiler

  Copyright (c) 2004-2006 Aprisobal

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

// devices.h

bool IsZXSpectrumDevice(const char *name);
bool IsAmstradCPCDevice(const char* name);
bool SetDevice(const char *const_id, const aint ramtop = 0);
const char* GetDeviceName();

class CDevicePage {
public:
	CDevicePage(byte* memory, int32_t size, int number);
	int32_t Size;
	int Number;
	byte* RAM;
private:
};

class CDeviceSlot {
public:
	enum ESlotOptions { O_NONE, O_ERROR, O_WARNING, O_NEXT };

	CDeviceSlot(int32_t adr, int32_t size);
	~CDeviceSlot();
	int32_t Address;
	int32_t Size;
	CDevicePage* Page;
	int16_t InitialPage;
	ESlotOptions Option;
private:
};

class CDeviceDef {
public:

	constexpr static size_t MAX_SLOT_N = 256;	// minimum possible slot size is 256 bytes
	constexpr static size_t MAX_PAGE_N = 1024;	// maximum possible total memory is 64MB with 64ki slot size

	CDeviceDef(const CDeviceDef&) = delete;
	CDeviceDef(const char* name, aint slot_size, aint page_count);
	~CDeviceDef();

	const char* getID() const { return ID; }
	const aint SlotSize;
	const aint SlotsCount;
	const aint PagesCount;
	int initialPages[MAX_SLOT_N] = {};

private:
	char* ID;
};

class CDevice {
public:
	// reset will reinitialize checks, "no emit" will do wrap-only (no machine byte emitted)
	// "emit" will also report error/warning upon boundary, as the machine byte emit is expected
	enum ECheckPageLevel{ CHECK_RESET, CHECK_NO_EMIT, CHECK_EMIT };

	CDevice(const CDevice&) = delete;
	CDevice(const char* name, CDevice* parent);
	~CDevice();
	void AddSlot(int32_t adr, int32_t size);
	void AddPage(byte* memory, int32_t size);
	CDevicePage* GetPage(int);
	CDeviceSlot* GetSlot(int);
	int GetSlotOfA16(int32_t address);
	int GetPageOfA16(int32_t address);
	void CheckPage(const ECheckPageLevel level);
	bool SetSlot(int slotNumber);		// sets "current/active" slot
	CDeviceSlot* GetCurrentSlot();		// returns "current/active" slot
	int GetCurrentSlotNum() const { return CurrentSlot; }	// returns "current/active" slot
	int32_t GetMemoryOffset(int page, int32_t offset) const;
	void Poke(aint z80adr, byte value);	// write byte into device memory with current page-mapping
	aint SlotNumberFromPreciseAddress(aint address);
	char* ID;
	CDevice* Next;
	int SlotsCount;
	int PagesCount;
	byte* Memory;
	aint ZxRamTop;		// for ZX-like machines, the RAMTOP system variable
private:
	int CurrentSlot;
	CDeviceSlot* Slots[CDeviceDef::MAX_SLOT_N];
	CDevicePage* Pages[CDeviceDef::MAX_PAGE_N];

	// variables for CheckPage logic
	int previousSlotI;				// previous machine code write happened into this slot
	CDeviceSlot::ESlotOptions previousSlotOpt;	// its option was
	bool limitExceeded;				// true if limit exceeded was already reported
};

constexpr aint ZX_RAMTOP_DEFAULT = 0x5D5B;	// 0xFF57 is regular ROM default
	// but 0x5D5B is minimum to keep "CLEAR 54321" still working if you return to BASIC (snapshot)
constexpr aint ZX_SYSVARS_ADR = 0x5C00;
constexpr aint ZX_UDG_ADR = 0xFF58;

extern const unsigned char ZX_SYSVARS_DATA[256];
extern const unsigned char ZX_STACK_DATA[4];
extern const unsigned char ZX_UDG_DATA[168];
