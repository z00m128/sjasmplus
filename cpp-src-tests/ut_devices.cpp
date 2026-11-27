/*
Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
OF THIS SOFTWARE.
*/

#ifdef ADD_UNIT_TESTS

#include "../sjasm/sjdefs.h"
#include "UnitTest++/UnitTest++.h"

class DeviceFixture {
public:
	CDevice testDev;	// test device: two 0x4000 slots, three pages

	DeviceFixture() : testDev("TESTDEV", nullptr) {
		testDev.AddSlot(0, 0x4000);
		testDev.AddSlot(0x4000, 0x4000);
		testDev.Memory = new byte[0x4000 * 3]();
		testDev.AddPage(testDev.Memory, 0x4000);
		testDev.AddPage(testDev.Memory+0x4000, 0x4000);
		testDev.AddPage(testDev.Memory+0x8000, 0x4000);
		testDev.GetSlot(0)->Page = testDev.GetPage(0);
		testDev.GetSlot(1)->Page = testDev.GetPage(1);
		testDev.SetSlot(0);
	}
};

TEST_FIXTURE(DeviceFixture, Device_GetInvalidSlot) {
	pass = 0;	// inhibit error output from GetSlot
	CHECK(testDev.GetSlot(0) != testDev.GetSlot(1));	// sanity check
	CHECK(testDev.GetSlot(0) == testDev.GetSlot(2));	// actual test
}

TEST_FIXTURE(DeviceFixture, Device_GetInvalidPage) {
	pass = 0;	// inhibit error output from GetSlot
	CHECK(testDev.GetPage(0) != testDev.GetPage(2));	// sanity check
	CHECK(testDev.GetPage(0) == testDev.GetPage(3));	// actual test
}

TEST_FIXTURE(DeviceFixture, Device_GetSlotOfA16) {
	CHECK(-1 == testDev.GetSlotOfA16(0x8000));
	CHECK(-1 == testDev.GetSlotOfA16(-1));
	CHECK(0 == testDev.GetSlotOfA16(0x0123));
	CHECK(1 == testDev.GetSlotOfA16(0x4123));
}

TEST_FIXTURE(DeviceFixture, Device_GetPageOfA16) {
	CHECK(LABEL_PAGE_OUT_OF_BOUNDS == testDev.GetPageOfA16(0x8000));
	CHECK(LABEL_PAGE_OUT_OF_BOUNDS == testDev.GetPageOfA16(-1));
	CHECK(0 == testDev.GetPageOfA16(0x0123));
	CHECK(1 == testDev.GetPageOfA16(0x4123));
}

TEST(Device_AllocateRAMOnlyForFinalPass) {
	// TODO: Give this test its own pass context instead of saving and restoring globals.
	const auto savedPass = pass;
	CDevice* const savedDevices = Devices;
	CDevice* const savedDevice = Device;
	const auto savedDeviceID = DeviceID;
	CDevicePage* const savedPage = Page;
	byte* const savedMemoryPointer = MemoryPointer;
	for (pass = 1; pass <= LASTPASS; ++pass) {
		Devices = nullptr;
		SetDevice(nullptr, 0);
		CHECK(SetDevice("ZXSPECTRUM48", 0));
		if (Device) {
			const bool hasRAM = LASTPASS == pass;
			CHECK_EQUAL(hasRAM, Device->Memory != nullptr);
			CHECK_EQUAL(4, Device->PagesCount);
			const CDevicePage* const screen = Device->GetSlot(1)->Page;
			CHECK_EQUAL(hasRAM, screen->RAM != nullptr);
			if (screen->RAM) CHECK_EQUAL(7 * 8, screen->RAM[0x1800]);
		}
		delete Devices;
	}
	MemoryPointer = savedMemoryPointer;
	Page = savedPage;
	DeviceID = savedDeviceID;
	Device = savedDevice;
	Devices = savedDevices;
	pass = savedPass;
}

#endif
