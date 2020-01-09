// Part of CRC-32C library: https://crc32c.machinezoo.com/
/*
  Copyright (c) 2013 - 2014, 2016 Mark Adler, Robert Vazan, Max Vysokikh

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the author be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
  claim that you wrote the original software. If you use this software
  in a product, an acknowledgment in the product documentation would be
  appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
  misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

/*
 This is *MODIFIED* version of: https://github.com/robertvazan/crc32c-hw
 License: zlib license

 Modified by Peter Helcmanovsky (c) 2020
 (I believe the zlib license is compatible with the sjasmplus BSD license)
*/

#include "crc32c.h"

#define NOMINMAX

#include <algorithm>

#define POLY 0x82f63b78

typedef const uint8_t *buffer;

static uint32_t table[16][256];

static bool _tableInitialized = false;

extern "C" void crc32_init()
{
	if (_tableInitialized) return;

	for(int i = 0; i < 256; i++) 
	{
		uint32_t res = (uint32_t)i;
		for(int t = 0; t < 16; t++) {
			for (int k = 0; k < 8; k++) res = (res & 1) == 1 ? POLY ^ (res >> 1) : (res >> 1);
			table[t][i] = res;
		}
	}

	_tableInitialized = true;
}

/* Table-driven software version as a fall-back.  This is about 15 times slower
   than using the hardware instructions.  This assumes little-endian integers,
   as is the case on Intel processors that the assembler code here is for. */
extern "C" uint32_t crc32c_append_sw(uint32_t crci, buffer input, size_t length)
{
    buffer next = input;
    uint32_t crc;

    crc = crci ^ 0xffffffff;
    while (length && ((uintptr_t)next & 3) != 0)
    {
        crc = table[0][(crc ^ *next++) & 0xff] ^ (crc >> 8);
        --length;
    }
    while (length >= 12)
    {
        crc ^= *(uint32_t *)next;
        uint32_t high = *(uint32_t *)(next + 4);
        uint32_t high2 = *(uint32_t *)(next + 8);
        crc = table[11][crc & 0xff]
            ^ table[10][(crc >> 8) & 0xff]
            ^ table[9][(crc >> 16) & 0xff]
            ^ table[8][crc >> 24]
            ^ table[7][high & 0xff]
            ^ table[6][(high >> 8) & 0xff]
            ^ table[5][(high >> 16) & 0xff]
            ^ table[4][high >> 24]
            ^ table[3][high2 & 0xff]
            ^ table[2][(high2 >> 8) & 0xff]
            ^ table[1][(high2 >> 16) & 0xff]
            ^ table[0][high2 >> 24];
        next += 12;
        length -= 12;
    }
    while (length)
    {
        crc = table[0][(crc ^ *next++) & 0xff] ^ (crc >> 8);
        --length;
    }
    return (uint32_t)crc ^ 0xffffffff;
}
