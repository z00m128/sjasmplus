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

#endif
