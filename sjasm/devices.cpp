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

bool IsZXSpectrumDevice(const char *name) {
	if (nullptr == name) return false;
	if (strcmp(name, "ZXSPECTRUM48") &&
		strcmp(name, "ZXSPECTRUM128") &&
		strcmp(name, "ZXSPECTRUM256") &&
		strcmp(name, "ZXSPECTRUM512") &&
		strcmp(name, "ZXSPECTRUM1024") &&
		strcmp(name, "ZXSPECTRUM2048") &&
		strcmp(name, "ZXSPECTRUM4096") &&
		strcmp(name, "ZXSPECTRUM8192"))
	{
		return false;
	}
	return true;
}

bool IsAmstradCPCDevice(const char* name) {
	if (nullptr == name) return false;
	if (strcmp(name, "AMSTRADCPC464") &&
		strcmp(name, "AMSTRADCPC6128"))
	{
		return false;
	}
	return true;
}

bool IsAmstradPLUSDevice(const char* name) {
	if (nullptr == name) return false;
	if (strcmp(name, "AMSTRADCPCPLUS"))
	{
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
		CDeviceSlot* slot = device->GetSlot(i);
		slot->Page = device->GetPage(initialPages[i]);
		slot->InitialPage = slot->Page->Number;
	}
	device->SetSlot(device->SlotsCount - 1);
}

static void initZxLikeDevice(
	CDevice* const device, int32_t slotSize, int pageCount, const int* const initialPages, aint ramtop)
{
	initRegularSlotDevice(device, slotSize, 0x10000/slotSize, pageCount, initialPages);
	device->ZxRamTop = (0x5D00 <= ramtop && ramtop <= 0xFFFF) ? ramtop : ZX_RAMTOP_DEFAULT;

	// set memory to state like if (for snapshot saving):
		// CLEAR ZxRamTop (0x5D5B default) : LOAD "bin" CODE : ... USR start_adr
	aint adr;
	// ULA attributes: INK 0 : PAPER 7 : FLASH 0 : BRIGTH 0
	for (adr = 0x5800; adr < 0x5B00; ++adr) device->Poke(adr, 7*8);

	// set UDG data at ZX_UDG_ADR (0xFF58)
	adr = ZX_UDG_ADR;
	for (byte value : ZX_UDG_DATA) device->Poke(adr++, value);

	// ZX SYSVARS at 0x5C00
	adr = ZX_SYSVARS_ADR;
	for (byte value : ZX_SYSVARS_DATA) device->Poke(adr++, value);
	// set RAMTOP sysvar
	device->Poke(ZX_SYSVARS_ADR+0xB2, device->ZxRamTop & 0xFF);
	device->Poke(ZX_SYSVARS_ADR+0xB3, (device->ZxRamTop>>8) & 0xFF);

	// set STACK data (without the "start" address)
	adr = device->ZxRamTop + 1 - sizeof(ZX_STACK_DATA);
	// set ERRSP sysvar to beginning of the fake stack
	device->Poke(ZX_SYSVARS_ADR+0x3D, adr & 0xFF);
	device->Poke(ZX_SYSVARS_ADR+0x3E, (adr>>8) & 0xFF);
	for (byte value : ZX_STACK_DATA) device->Poke(adr++, value);
}

static void DeviceZXSpectrum48(CDevice **dev, CDevice *parent, aint ramtop) {
	*dev = new CDevice("ZXSPECTRUM48", parent);
	const int initialPages[] = {0, 1, 2, 3};
	initZxLikeDevice(*dev, 0x4000, 4, initialPages, ramtop);
}

const static int initialPagesZx128[] = {7, 5, 2, 0};

static void DeviceZXSpectrum128(CDevice **dev, CDevice *parent, aint ramtop) {
	*dev = new CDevice("ZXSPECTRUM128", parent);
	initZxLikeDevice(*dev, 0x4000, 8, initialPagesZx128, ramtop);
}

static void DeviceZXSpectrum256(CDevice **dev, CDevice *parent, aint ramtop) {
	*dev = new CDevice("ZXSPECTRUM256", parent);
	initZxLikeDevice(*dev, 0x4000, 16, initialPagesZx128, ramtop);
}

static void DeviceZXSpectrum512(CDevice **dev, CDevice *parent, aint ramtop) {
	*dev = new CDevice("ZXSPECTRUM512", parent);
	initZxLikeDevice(*dev, 0x4000, 32, initialPagesZx128, ramtop);
}

static void DeviceZXSpectrum1024(CDevice **dev, CDevice *parent, aint ramtop) {
	*dev = new CDevice("ZXSPECTRUM1024", parent);
	initZxLikeDevice(*dev, 0x4000, 64, initialPagesZx128, ramtop);
}

static void DeviceZXSpectrum2048(CDevice **dev, CDevice *parent, aint ramtop) {
	*dev = new CDevice("ZXSPECTRUM2048", parent);
	initZxLikeDevice(*dev, 0x4000, 128, initialPagesZx128, ramtop);
}

static void DeviceZXSpectrum4096(CDevice **dev, CDevice *parent, aint ramtop) {
	*dev = new CDevice("ZXSPECTRUM4096", parent);
	initZxLikeDevice(*dev, 0x4000, 256, initialPagesZx128, ramtop);
}

static void DeviceZXSpectrum8192(CDevice **dev, CDevice *parent, aint ramtop) {
	*dev = new CDevice("ZXSPECTRUM8192", parent);
	initZxLikeDevice(*dev, 0x4000, 512, initialPagesZx128, ramtop);
}

static void DeviceZxSpectrumNext(CDevice **dev, CDevice *parent, aint ramtop) {
	if (ramtop) WarningById(W_NO_RAMTOP);
	if (Options::IsI8080) Error("Can't use ZXN device while in i8080 assembling mode", line, FATAL);
	if (Options::IsLR35902) Error("Can't use ZXN device while in Sharp LR35902 assembling mode", line, FATAL);
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

static void DeviceNoSlot64k(CDevice **dev, CDevice *parent, aint ramtop) {
	if (ramtop) WarningById(W_NO_RAMTOP);
	*dev = new CDevice("NOSLOT64K", parent);
	const int initialPages[] = { 0 };
	initRegularSlotDevice(*dev, 0x10000, 1, 32, initialPages);	// 32*64kiB = 2MiB
}

static void DeviceAmstradCPC464(CDevice** dev, CDevice* parent, aint ramtop) {
	if (ramtop) WarningById(W_NO_RAMTOP);
	*dev = new CDevice("AMSTRADCPC464", parent);
	const int initialPages[] = { 0, 1, 2, 3 };
	initRegularSlotDevice(*dev, 0x4000, 4, 4, initialPages);
}

static void DeviceAmstradCPC6128(CDevice** dev, CDevice* parent, aint ramtop) {
	if (ramtop) WarningById(W_NO_RAMTOP);
	*dev = new CDevice("AMSTRADCPC6128", parent);
	const int initialPages[] = { 0, 1, 2, 3 };
	initRegularSlotDevice(*dev, 0x4000, 4, 8, initialPages);
}

static void DeviceAmstradCPCPLUS(CDevice** dev, CDevice* parent, aint ramtop) {
	if (ramtop) WarningById(W_NO_RAMTOP);
	*dev = new CDevice("AMSTRADCPCPLUS", parent);
	const int initialPages[] = { 0, 1, 2, 3 };
	initRegularSlotDevice(*dev, 0x4000, 4, 32, initialPages);	// 32*16kiB = 512MiB (maximum cartridge size)
}

static bool SetUserDefinedDevice(const char* id, CDevice** dev, CDevice* parent, aint ramtop) {
	auto findIt = std::find_if(
		DefDevices.begin(), DefDevices.end(),
		[&](const CDeviceDef* el) { return 0 == strcasecmp(id, el->getID()); }
	);
	if (DefDevices.end() == findIt) return false;	// not found
	const CDeviceDef & def = **findIt;
	if (ramtop) WarningById(W_NO_RAMTOP);
	*dev = new CDevice(def.getID(), parent);
	initRegularSlotDevice(*dev, def.SlotSize, def.SlotsCount, def.PagesCount, def.initialPages);
	return true;
}

bool SetDevice(const char *const_id, const aint ramtop) {
	CDevice** dev;
	CDevice* parent = nullptr;
	char* id = const_cast<char*>(const_id);		//TODO cmphstr for both const/nonconst variants?
		// ^ argument is const because of lua bindings

	if (!id || cmphstr(id, "none")) {
		DeviceID = nullptr;
		Device = nullptr;
		return true;
	}

	if (!DeviceID || strcmp(DeviceID, id)) {	// different device than current, change to it
		DeviceID = nullptr;
		dev = &Devices;
		// search for device
		while (*dev) {
			parent = *dev;
			if (!strcmp(parent->ID, id)) break;
			dev = &(parent->Next);
		}
		if (nullptr == (*dev)) {	// device not found
			if (cmphstr(id, "zxspectrum48")) {			// must be lowercase to catch both cases
				DeviceZXSpectrum48(dev, parent, ramtop);
			} else if (cmphstr(id, "zxspectrum128")) {
				DeviceZXSpectrum128(dev, parent, ramtop);
			} else if (cmphstr(id, "zxspectrum256")) {
				DeviceZXSpectrum256(dev, parent, ramtop);
			} else if (cmphstr(id, "zxspectrum512")) {
				DeviceZXSpectrum512(dev, parent, ramtop);
			} else if (cmphstr(id, "zxspectrum1024")) {
				DeviceZXSpectrum1024(dev, parent, ramtop);
			} else if (cmphstr(id, "zxspectrum2048")) {
				DeviceZXSpectrum2048(dev, parent, ramtop);
			} else if (cmphstr(id, "zxspectrum4096")) {
				DeviceZXSpectrum4096(dev, parent, ramtop);
			} else if (cmphstr(id, "zxspectrum8192")) {
				DeviceZXSpectrum8192(dev, parent, ramtop);
			} else if (cmphstr(id, "zxspectrumnext")) {
				DeviceZxSpectrumNext(dev, parent, ramtop);
			} else if (cmphstr(id, "noslot64k")) {
				DeviceNoSlot64k(dev, parent, ramtop);
			} else if (cmphstr(id, "amstradcpc464")) {
				DeviceAmstradCPC464(dev, parent, ramtop);
			} else if (cmphstr(id, "amstradcpc6128")) {
				DeviceAmstradCPC6128(dev, parent, ramtop);
			} else if (cmphstr(id, "amstradcpcplus")) {
				DeviceAmstradCPCPLUS(dev, parent, ramtop);
			} else if (!SetUserDefinedDevice(id, dev, parent, ramtop)) {
				return false;
			}
		}
		// set up the found/new device
		Device = (*dev);
		DeviceID = Device->ID;
		Device->CheckPage(CDevice::CHECK_RESET);
	}
	if (ramtop && Device->ZxRamTop && ramtop != Device->ZxRamTop) {
		WarningById(W_DEV_RAMTOP);
	}
	if (IsSldExportActive()) {
		// SLD tracing data are being exported, export the device data
		int pageSize = Device->GetCurrentSlot()->Size;
		int pageCount = Device->PagesCount;
		int slotsCount = Device->SlotsCount;
		char buf[LINEMAX];
		snprintf(buf, LINEMAX, "pages.size:%d,pages.count:%d,slots.count:%d",
			pageSize, pageCount, slotsCount
		);
		for (int slotI = 0; slotI < slotsCount; ++slotI) {
			size_t bufLen = strlen(buf);
			char* bufAppend = buf + bufLen;
			snprintf(bufAppend, LINEMAX-bufLen,
						(0 == slotI) ? ",slots.adr:%d" : ",%d",
						Device->GetSlot(slotI)->Address);
		}
		// pagesize
		WriteToSldFile(-1,-1,'Z',buf);
	}
	return true;
}

const char* DEVICE_NONE_ID = "NONE";

const char* GetDeviceName() {
	return DeviceID ? DeviceID : DEVICE_NONE_ID;
}

std::vector<CDeviceDef*> DefDevices;

CDeviceDef::CDeviceDef(const char* name, aint slot_size, aint page_count)
	: SlotSize(slot_size), SlotsCount((0x10000 + slot_size - 1) / slot_size), PagesCount(page_count) {
	assert(name);
	ID = STRDUP(name);
}

CDeviceDef::~CDeviceDef() {
	free(ID);
}

CDevice::CDevice(const char *name, CDevice *parent)
	: Next(nullptr), SlotsCount(0), PagesCount(0), Memory(nullptr), ZxRamTop(0), CurrentSlot(0),
	previousSlotI(0), previousSlotOpt(CDeviceSlot::ESlotOptions::O_NONE), limitExceeded(false) {
	ID = STRDUP(name);
	if (parent) parent->Next = this;
	for (auto & slot : Slots) slot = nullptr;
	for (auto & page : Pages) page = nullptr;
}

CDevice::~CDevice() {
	for (auto & slot : Slots) if (slot) delete slot;
	for (auto & page : Pages) if (page) delete page;
	if (Memory) delete[] Memory;
	if (Next) delete Next;
	free(ID);
}

void CDevice::AddSlot(int32_t adr, int32_t size) {
	if (CDeviceDef::MAX_SLOT_N == SlotsCount) ErrorInt("Can't add more slots, already at max", CDeviceDef::MAX_SLOT_N, FATAL);
	Slots[SlotsCount++] = new CDeviceSlot(adr, size);
}

void CDevice::AddPage(byte* memory, int32_t size) {
	if (CDeviceDef::MAX_PAGE_N == PagesCount) ErrorInt("Can't add more pages, already at max", CDeviceDef::MAX_PAGE_N, FATAL);
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
	// only with "emit" mode, labels may get the value 0x10000 before the address gets truncated
	if (DISP_NONE != PseudoORG && CHECK_NO_EMIT != level && 0x10000 <= CurAddress) {
		if (LASTPASS == pass) {
			char buf[64];
			SPRINTF1(buf, 64, "RAM limit exceeded 0x%X by DISP", (unsigned int)CurAddress);
			Warning(buf);
		}
		CurAddress &= 0xFFFF;
	}
	// check the emit address for bytecode
	const int realAddr = DISP_NONE != PseudoORG ? adrdisp : CurAddress;
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
		if (S->Address + S->Size <= realAddr) MemoryPointer = nullptr; // you're not writing there
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
					// reset error reporting even when level is CHECK_NO_EMIT, one error is enough
					limitExceeded = false;
					previousSlotI = i;
					previousSlotOpt = S->Option;
					break;		// continue into next slot, don't wrap any more
				}
				if (realAddr != (prevS->Address + prevS->Size)) {	// should be equal
					ErrorInt("Write beyond memory slot in wrap-around slot catched too late by",
								realAddr - prevS->Address - prevS->Size, FATAL);
					break;
				}
				prevS->Page = Pages[nextPageN];		// map next page into the guarded slot
				Page = prevS->Page;
				if (DISP_NONE != PseudoORG) adrdisp -= prevS->Size;
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
		// refresh check slot settings (only in CHECK_EMIT case, otherwise ParseLine will reset it with CHECK_NO_EMIT at BoL!)
		if (CHECK_EMIT == level) {
			limitExceeded &= (previousSlotI == i);	// reset limit flag if slot changed (in non check_reset mode)
			previousSlotI = i;
			previousSlotOpt = S->Option;
		}
		return;
	}
	Error("CheckPage(..): please, contact the author of this program.", nullptr, FATAL);
}

bool CDevice::SetSlot(int slotNumber) {
	if (slotNumber < 0 || SlotsCount <= slotNumber || nullptr == Slots[slotNumber]) return false;
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

void CDevice::Poke(aint z80adr, byte value) {
	// write byte into device memory with current page-mapping
	const int adrPage = GetPageOfA16(z80adr);
	if (-1 == adrPage) return;		// silently ignore invalid address
	CDevicePage* page = GetPage(adrPage);
	page->RAM[z80adr & (page->Size-1)] = value;
}

aint CDevice::SlotNumberFromPreciseAddress(aint address) {
	if (address < SlotsCount) return address;		// seems to be slot number, not address
	// check if the address (input value) does exactly match start-address of some slot
	int slotNum = GetSlotOfA16(address);
	if (-1 == slotNum) return address;				// does not belong to any slot
	if (address != GetSlot(slotNum)->Address) return address;		// not exact match
	return slotNum;									// return address converted into slot number
}

CDevicePage::CDevicePage(byte* memory, int32_t size, int number)
	: Size(size), Number(number), RAM(memory) {
	if (nullptr == RAM) Error("No memory defined", nullptr, FATAL);
}

CDeviceSlot::CDeviceSlot(int32_t adr, int32_t size)
	: Address(adr), Size(size), Page(nullptr), InitialPage(-1), Option(O_NONE) {
}

CDeviceSlot::~CDeviceSlot() {
}

const unsigned char ZX_SYSVARS_DATA[] = {
	0xff, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0x00, 0x14, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x01, 0x00, 0x06, 0x00, 0x0b, 0x00, 0x01, 0x00, 0x01, 0x00, 0x06, 0x00, 0x10, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3c, 0x40, 0x00, 0xff, 0xcc, 0x01, 0x54, 0xff, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x38, 0x00, 0x00, 0xcb, 0x5c, 0x00, 0x00, 0xb6,
	0x5c, 0xb6, 0x5c, 0xcb, 0x5c, 0x00, 0x00, 0xca, 0x5c, 0xcc, 0x5c, 0xcc, 0x5c, 0xcc, 0x5c, 0x00,
	0x00, 0xce, 0x5c, 0xce, 0x5c, 0xce, 0x5c, 0x00, 0x92, 0x5c, 0x10, 0x02, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x58, 0xff, 0x00, 0x00, 0x21,
	0x5b, 0x00, 0x21, 0x17, 0x00, 0x40, 0xe0, 0x50, 0x21, 0x18, 0x21, 0x17, 0x01, 0x38, 0x00, 0x38,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x57, 0xff, 0xff, 0xff, 0xf4, 0x09, 0xa8, 0x10, 0x4b, 0xf4, 0x09, 0xc4, 0x15, 0x53,
	0x81, 0x0f, 0xc4, 0x15, 0x52, 0xf4, 0x09, 0xc4, 0x15, 0x50, 0x80, 0x80, 0x0d, 0x80, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

const unsigned char ZX_STACK_DATA[] = {
	0x03, 0x13, 0x00, 0x3e
};

const unsigned char ZX_UDG_DATA[168] = {
	0x00, 0x3c, 0x42, 0x42, 0x7e, 0x42, 0x42, 0x00, 0x00, 0x7c, 0x42, 0x7c, 0x42, 0x42, 0x7c, 0x00,
	0x00, 0x3c, 0x42, 0x40, 0x40, 0x42, 0x3c, 0x00, 0x00, 0x78, 0x44, 0x42, 0x42, 0x44, 0x78, 0x00,
	0x00, 0x7e, 0x40, 0x7c, 0x40, 0x40, 0x7e, 0x00, 0x00, 0x7e, 0x40, 0x7c, 0x40, 0x40, 0x40, 0x00,
	0x00, 0x3c, 0x42, 0x40, 0x4e, 0x42, 0x3c, 0x00, 0x00, 0x42, 0x42, 0x7e, 0x42, 0x42, 0x42, 0x00,
	0x00, 0x3e, 0x08, 0x08, 0x08, 0x08, 0x3e, 0x00, 0x00, 0x02, 0x02, 0x02, 0x42, 0x42, 0x3c, 0x00,
	0x00, 0x44, 0x48, 0x70, 0x48, 0x44, 0x42, 0x00, 0x00, 0x40, 0x40, 0x40, 0x40, 0x40, 0x7e, 0x00,
	0x00, 0x42, 0x66, 0x5a, 0x42, 0x42, 0x42, 0x00, 0x00, 0x42, 0x62, 0x52, 0x4a, 0x46, 0x42, 0x00,
	0x00, 0x3c, 0x42, 0x42, 0x42, 0x42, 0x3c, 0x00, 0x00, 0x7c, 0x42, 0x42, 0x7c, 0x40, 0x40, 0x00,
	0x00, 0x3c, 0x42, 0x42, 0x52, 0x4a, 0x3c, 0x00, 0x00, 0x7c, 0x42, 0x42, 0x7c, 0x44, 0x42, 0x00,
	0x00, 0x3c, 0x40, 0x3c, 0x02, 0x42, 0x3c, 0x00, 0x00, 0xfe, 0x10, 0x10, 0x10, 0x10, 0x10, 0x00,
	0x00, 0x42, 0x42, 0x42, 0x42, 0x42, 0x3c, 0x00
};
