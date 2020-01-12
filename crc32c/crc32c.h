// Part of CRC-32C library: https://crc32c.machinezoo.com/

/*
 This is *MODIFIED* version of: https://github.com/robertvazan/crc32c-hw
 License: zlib license (CPP file contains full license and copyright)

 Modified by Peter Helcmanovsky (c) 2020
 (I believe the zlib license is compatible with the sjasmplus BSD license)
*/

#ifndef CRC32C_H
#define CRC32C_H

#include <cstddef>
#include <cstdint>

// HW variants were removed, as not important for sjasmplus

/*
	Software fallback version of CRC-32C (Castagnoli) checksum.
*/
extern "C" uint32_t crc32c_append_sw(uint32_t crc, const uint8_t *input, size_t length);

extern "C" void crc32_init();	// calculate tables if not initialized yet

#endif
