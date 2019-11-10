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

// devices.cpp

#include "sjdefs.h"

bool IsZXSpectrumDevice(char *name){
	if (strcmp(name, "ZXSPECTRUM48") && 
		strcmp(name, "ZXSPECTRUM128") && 
		strcmp(name, "ZXSPECTRUM256") && 
		strcmp(name, "ZXSPECTRUM512") && 
		strcmp(name, "ZXSPECTRUM1024")) {
			return false;
	}
	return true;
}

static void initRegularSlotDevice(CDevice* const device, const int32_t slotSize, const int32_t slotCount,
								  const int pageCount, const int* const initialPages) {
	for (int32_t slotAddress = 0; slotAddress < slotSize * slotCount; slotAddress += slotSize) {
		device->AddSlot(slotAddress, slotSize);
	}
	device->Memory = new byte[slotSize * pageCount]();
	for (byte* memPtr = device->Memory; memPtr < device->Memory + slotSize * pageCount; memPtr += slotSize) {
		device->AddPage(memPtr, slotSize);
	}
	for (int i = 0; i < device->SlotsCount; ++i) {
		device->GetSlot(i)->Page = device->GetPage(initialPages[i]);
	}
	device->SetSlot(device->SlotsCount - 1);
}

static void initZxLikeDevice(CDevice* const device, int32_t slotSize, int pageCount, const int* const initialPages) {
	initRegularSlotDevice(device, slotSize, 0x10000/slotSize, pageCount, initialPages);
	// set memory to "USR 0"-like state (for snapshot saving) (works also for ZXN 0x2000 slotSize)
	int vramPage = (0x2000 == slotSize) ? initialPages[2] : initialPages[1];	// default = second slot page
	byte* const vramRAM = device->GetPage(vramPage)->RAM;
	memset(vramRAM + 0x1800, 7*8, 768);
	memcpy(vramRAM + 0x1C00, BASin48Vars, sizeof(BASin48Vars));
	byte* const stackRAM = device->GetCurrentSlot()->Page->RAM;	// last slot page is default "stack"
	memcpy(stackRAM + slotSize - sizeof(BASin48SP), BASin48SP, sizeof(BASin48SP));
}

static void DeviceZXSpectrum48(CDevice **dev, CDevice *parent) {		// add new device
	*dev = new CDevice("ZXSPECTRUM48", parent);
	const int initialPages[] = {0, 1, 2, 3};
	initZxLikeDevice(*dev, 0x4000, 4, initialPages);
}

const static int initialPagesZx128[] = {7, 5, 2, 0};

static void DeviceZXSpectrum128(CDevice **dev, CDevice *parent) {		// add new device
	*dev = new CDevice("ZXSPECTRUM128", parent);
	initZxLikeDevice(*dev, 0x4000, 8, initialPagesZx128);
}

static void DeviceZXSpectrum256(CDevice **dev, CDevice *parent) {		// add new device
	*dev = new CDevice("ZXSPECTRUM256", parent);
	initZxLikeDevice(*dev, 0x4000, 16, initialPagesZx128);
}

static void DeviceZXSpectrum512(CDevice **dev, CDevice *parent) {		// add new device
	*dev = new CDevice("ZXSPECTRUM512", parent);
	initZxLikeDevice(*dev, 0x4000, 32, initialPagesZx128);
}

static void DeviceZXSpectrum1024(CDevice **dev, CDevice *parent) {		// add new device
	*dev = new CDevice("ZXSPECTRUM1024", parent);
	initZxLikeDevice(*dev, 0x4000, 64, initialPagesZx128);
}

static void DeviceZxSpectrumNext(CDevice **dev, CDevice *parent) {
	if (Options::IsI8080) Error("Can't use ZXN device while in i8080 assembling mode.", line, FATAL);
	if (Options::IsLR35902) Error("Can't use ZXN device while in Sharp LR35902 assembling mode.", line, FATAL);
	*dev = new CDevice("ZXSPECTRUMNEXT", parent);
	const int initialPages[] = {14, 15, 10, 11, 4, 5, 0, 1};	// basically same as ZX128, but 8k
	initRegularSlotDevice(*dev, 0x2000, 8, 224, initialPages);
	// auto-enable ZX Next instruction extensions
	if (0 == Options::syx.IsNextEnabled) {
		Options::syx.IsNextEnabled = 1;
		Z80::InitNextExtensions();		// add the special opcodes here (they were not added)
				// this is a bit late, but it should work as well as `--zxnext` option I believe
	}
}

int SetDevice(char *id) {
	CDevice** dev;
	CDevice* parent;

	if (!id || cmphstr(id, "none")) {
		DeviceID = 0; return true;
	}

	if (!DeviceID || strcmp(DeviceID, id)) {
		DeviceID = 0;
		dev = &Devices;
		parent = 0;
		// search for device
		while (*dev) {
			parent = *dev;
			if (!strcmp(parent->ID, id)) break;
			dev = &(parent->Next);
		}
		if (NULL == *dev) {		// device not found
			if (cmphstr(id, "zxspectrum48")) {			// must be lowercase to catch both cases
				DeviceZXSpectrum48(dev, parent);
			} else if (cmphstr(id, "zxspectrum128")) {
				DeviceZXSpectrum128(dev, parent);
			} else if (cmphstr(id, "zxspectrum256")) {
				DeviceZXSpectrum256(dev, parent);
			} else if (cmphstr(id, "zxspectrum512")) {
				DeviceZXSpectrum512(dev, parent);
			} else if (cmphstr(id, "zxspectrum1024")) {
				DeviceZXSpectrum1024(dev, parent);
			} else if (cmphstr(id, "zxspectrumnext")) {
				DeviceZxSpectrumNext(dev, parent);
			} else {
				return false;
			}
		}
		// set up the found/new device
		Device = (*dev);
		DeviceID = Device->ID;
		Device->CheckPage(CDevice::CHECK_RESET);
	}
	return true;
}

char* GetDeviceName() {
	if (!DeviceID) {
		return (char *)"NONE";
	} else {
		return DeviceID;
	}
}

CDevice::CDevice(const char *name, CDevice *parent)
	: Next(NULL), SlotsCount(0), PagesCount(0), Memory(nullptr), CurrentSlot(0) {
	ID = STRDUP(name);
	if (parent) parent->Next = this;
	for (auto & slot : Slots) slot = NULL;
	for (auto & page : Pages) page = NULL;
}

CDevice::~CDevice() {
	for (auto & slot : Slots) if (slot) delete slot;
	for (auto & page : Pages) if (page) delete page;
	if (Memory) delete[] Memory;
	if (Next) delete Next;
	free(ID);
}

void CDevice::AddSlot(int32_t adr, int32_t size) {
	Slots[SlotsCount++] = new CDeviceSlot(adr, size);
}

void CDevice::AddPage(byte* memory, int32_t size) {
	Pages[PagesCount] = new CDevicePage(memory, size, PagesCount);
	PagesCount++;
}

CDeviceSlot* CDevice::GetSlot(int num) {
	if (Slots[num]) return Slots[num];
	Error("Wrong slot number", lp);
	return Slots[0];
}

CDevicePage* CDevice::GetPage(int num) {
	if (Pages[num]) return Pages[num];
	Error("Wrong page number", lp);
	return Pages[0];
}

// returns slot belonging to the Z80-address (16bit)
int CDevice::GetSlotOfA16(int32_t address) {
	for (int i=SlotsCount; i--; ) {
		CDeviceSlot* const S = Slots[i];
		if (address < S->Address) continue;
		if (S->Address + S->Size <= address) return -1;		// outside of slot
		return i;
	}
	return -1;
}

// returns currently mapped page for the Z80-address (16bit)
int CDevice::GetPageOfA16(int32_t address) {
	int slotNum = GetSlotOfA16(address);
	if (-1 == slotNum) return -1;
	if (nullptr == Slots[slotNum]->Page) return -1;
	return Slots[slotNum]->Page->Number;
}

void CDevice::CheckPage(const ECheckPageLevel level) {
	// fake DISP address gets auto-wrapped FFFF->0 (with warning only)
	// ("no emit" to catch before labels are defined, although "emit" sounds more logical)
	if (PseudoORG && CHECK_NO_EMIT == level && 0x10000 <= CurAddress) {
		if (LASTPASS == pass) {
			char buf[64];
			SPRINTF1(buf, 64, "RAM limit exceeded 0x%X by DISP", (unsigned int)CurAddress);
			Warning(buf);
		}
		CurAddress &= 0xFFFF;
	}
	// check the emit address for bytecode
	const int realAddr = PseudoORG ? adrdisp : CurAddress;
	// quicker check to avoid scanning whole slots array every byte
	if (CHECK_RESET != level
		&& Slots[previousSlotI]->Address <= realAddr
		&& realAddr < Slots[previousSlotI]->Address + Slots[previousSlotI]->Size) return;
	for (int i=SlotsCount; i--; ) {
		CDeviceSlot* const S = Slots[i];
		if (realAddr < S->Address) continue;
		Page = S->Page;
		MemoryPointer = Page->RAM + (realAddr - S->Address);
 		if (CHECK_RESET == level) {
			previousSlotOpt = S->Option;
			previousSlotI = i;
			limitExceeded = false;
			return;
		}
		// if still in the same slot and within boundaries, we are done
		if (i == previousSlotI && realAddr < S->Address + S->Size) return;
		// crossing into other slot, check options for special functionality of old slot
		if (S->Address + S->Size <= realAddr) MemoryPointer = NULL; // you're not writing there
		switch (previousSlotOpt) {
			case CDeviceSlot::O_ERROR:
				if (LASTPASS == pass && CHECK_EMIT == level && !limitExceeded) {
					ErrorInt("Write outside of memory slot", realAddr, SUPPRESS);
					limitExceeded = true;
				}
				break;
			case CDeviceSlot::O_WARNING:
				if (LASTPASS == pass && CHECK_EMIT == level && !limitExceeded) {
					Warning("Write outside of memory slot");
					limitExceeded = true;
				}
				break;
			case CDeviceSlot::O_NEXT:
			{
				CDeviceSlot* const prevS = Slots[previousSlotI];
				const int nextPageN = prevS->Page->Number + 1;
				if (PagesCount <= nextPageN) {
					ErrorInt("No more memory pages to map next one into slot", previousSlotI, SUPPRESS);
					// disable the option on the overflowing slot
					prevS->Option = CDeviceSlot::O_NONE;
					break;		// continue into next slot, don't wrap any more
				}
				if (realAddr != (prevS->Address + prevS->Size)) {	// should be equal
					ErrorInt("Write beyond memory slot in wrap-around slot catched too late by",
								realAddr - prevS->Address - prevS->Size, FATAL);
					break;
				}
				prevS->Page = Pages[nextPageN];		// map next page into the guarded slot
				Page = prevS->Page;
				if (PseudoORG) adrdisp -= prevS->Size;
				else CurAddress -= prevS->Size;
				MemoryPointer = Page->RAM;
				return;		// preserve current option status
			}
			default:
				if (LASTPASS == pass && CHECK_EMIT == level && !limitExceeded && !MemoryPointer) {
					ErrorInt("Write outside of device memory at", realAddr, SUPPRESS);
					limitExceeded = true;
				}
				break;
		}
		// refresh check slot settings
		limitExceeded &= (previousSlotI == i);	// reset limit flag if slot changed (in non check_reset mode)
		previousSlotI = i;
		previousSlotOpt = S->Option;
		return;
	}
	Error("CheckPage(..): please, contact the author of this program.", NULL, FATAL);
}

bool CDevice::SetSlot(int slotNumber) {
	if (slotNumber < 0 || SlotsCount <= slotNumber || NULL == Slots[slotNumber]) return false;
	CurrentSlot = slotNumber;
	return true;
}

CDeviceSlot* CDevice::GetCurrentSlot() {
	return GetSlot(CurrentSlot);
}

// Calling this with (PagesCount, 0) will return total memory size
int32_t CDevice::GetMemoryOffset(int page, int32_t offset) const {
	if (!Pages[0]) return 0;
	return offset + page * Pages[0]->Size;
}

CDevicePage::CDevicePage(byte* memory, int32_t size, int number)
	: Size(size), Number(number), RAM(memory) {
	if (nullptr == RAM) Error("No memory defined", nullptr, FATAL);
}

CDeviceSlot::CDeviceSlot(int32_t adr, int32_t size)
	: Address(adr), Size(size), Page(NULL), Option(O_NONE) {
}

CDeviceSlot::~CDeviceSlot() {
}
