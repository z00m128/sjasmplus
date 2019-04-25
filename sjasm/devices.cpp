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

static void initZxLikeDevice(CDevice* const device, aint slotSize, int pageCount, const int* const initialPages) {
	for (aint slotAddress = 0; slotAddress < 0x10000; slotAddress += slotSize) {
		device->AddSlot(slotAddress, slotSize);
	}
	for (int i = 0; i < pageCount; ++i) {
		device->AddPage(slotSize);
	}
	for (int i = 0; i < device->SlotsCount; ++i) {
		device->GetSlot(i)->Page = device->GetPage(initialPages[i]);
	}
	device->CurrentSlot = device->SlotsCount - 1;
	// set memory to "USR 0"-like state (for snapshot saving) (works also for ZXN 0x2000 slotSize)
	int vramPage = (0x2000 == slotSize) ? initialPages[2] : initialPages[1];	// default = second slot page
	char* const vramRAM = device->GetPage(vramPage)->RAM;
	memset(vramRAM + 0x1800, 7*8, 768);
	memcpy(vramRAM + 0x1C00, BASin48Vars, sizeof(BASin48Vars));
	char* const stackRAM = device->GetSlot(device->CurrentSlot)->Page->RAM;		// last slot page is default "stack"
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
	*dev = new CDevice("ZXSPECTRUMNEXT", parent);
	const int initialPages[] = {14, 15, 10, 11, 4, 5, 0, 1};	// basically same as ZX128, but 8k
	initZxLikeDevice(*dev, 0x2000, 224, initialPages);
	// auto-enable ZX Next instruction extensions
	if (0 == Options::IsNextEnabled) {
		Options::IsNextEnabled = 1;
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
		Slot = Device->GetSlot(Device->CurrentSlot);
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
