#pragma once

#include "sjdefs.h"
#include "io_tzx.h"

namespace TZXBlockId {
    constexpr byte Standard = 0x10;
    constexpr byte Turbo = 0x11;
    constexpr byte Pause = 0x20;
}

void TZX_CreateEmpty(const char* fname) {
    FILE* ff;
    if (!FOPEN_ISOK(ff, fname, "wb")) {
        Error("[TZX] Error opening file", fname, FATAL);
    }

    constexpr byte tzx_major_version = 1;
    constexpr byte tzx_minor_version = 10;

    const char magic[10] = { 
        'Z', 'X', 'T', 'a', 'p', 'e', '!', 
        0x1A, 
        tzx_major_version,  tzx_minor_version 
    };

    fwrite(magic, 1, 10, ff);
    fclose(ff);
}

void TZX_AppendPauseBlock(const char* fname, word pauseAfterMs) {
    FILE* ff;
    if (!FOPEN_ISOK(ff, fname, "a+b")) {
        Error("[TZX] Error opening file", fname, FATAL);
    }
    fputc(TZXBlockId::Pause, ff); // block id

    fputc(pauseAfterMs & 0xFF, ff);
    fputc(pauseAfterMs >> 8, ff);
    fclose(ff);
}

void TZX_AppendStandardBlock(const char* fname, const byte* buf, const aint buflen, word pauseAfterMs, byte sync) {
    FILE* ff;
    if (!FOPEN_ISOK(ff, fname, "a+b")) {
        Error("[TZX] Error opening file", fname, FATAL);
    }

    const aint totalDataLen = buflen + 2; // + sync byte + checksum

    fputc(TZXBlockId::Standard, ff); // block id

    fputc(pauseAfterMs & 0xFF, ff); // block header
    fputc(pauseAfterMs >> 8, ff);
    fputc(totalDataLen & 0xFF, ff);
    fputc(totalDataLen >> 8, ff);

    fputc(sync, ff); // sync pattern
    // payload
    byte check = sync;
    const byte* ptr = buf;
    for (aint i = 0; i < buflen; ++i) {
        fputc(*ptr, ff);
        check ^= *ptr;
        ++ptr;
    }
    fputc(check, ff); // checksum
    fclose(ff);
}

void TZX_AppendTurboBlock(const char* fname, const byte* buf, const aint buflen, const STZXTurboBlock& turbo)
{
    FILE* ff;
    if (!FOPEN_ISOK(ff, fname, "a+b")) {
        Error("[TZX] Error opening file", fname, FATAL);
    }

    fputc(TZXBlockId::Turbo, ff); // block id

    fputc(turbo.PilotPulseLen & 0xFF, ff); // block header
    fputc(turbo.PilotPulseLen >> 8, ff);
    fputc(turbo.FirstSyncLen & 0xFF, ff);
    fputc(turbo.FirstSyncLen >> 8, ff);
    fputc(turbo.SecondSyncLen & 0xFF, ff);
    fputc(turbo.SecondSyncLen >> 8, ff);
    fputc(turbo.ZeroBitLen & 0xFF, ff);
    fputc(turbo.ZeroBitLen >> 8, ff);
    fputc(turbo.OneBitLen & 0xFF, ff);
    fputc(turbo.OneBitLen >> 8, ff);
    fputc(turbo.PilotToneLen & 0xFF, ff);
    fputc(turbo.PilotToneLen >> 8, ff);
    fputc(turbo.LastByteUsedBits & 0xFF, ff);
    fputc(turbo.PauseAfterMs & 0xFF, ff);
    fputc(turbo.PauseAfterMs >> 8, ff);
    fputc(buflen & 0xFF, ff); // total data len is a 24-bit number, LSB first
    fputc(buflen >> 8, ff);
    fputc(buflen >> 16, ff);

    // payload
    fwrite(buf, 1, buflen, ff);
    fclose(ff);
}

// eof io_tzx.cpp
