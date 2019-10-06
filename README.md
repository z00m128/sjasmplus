# sjasmplus

Added Tracefile output to support NDS remote debugging system

https://github.com/Ckirby101/NDS-NextDevSystem

[![Build Status](https://api.cirrus-ci.com/github/z00m128/sjasmplus.svg)](https://cirrus-ci.com/github/z00m128/sjasmplus/master)
[![GitHub repo size in bytes](https://img.shields.io/github/repo-size/z00m128/sjasmplus.svg)](https://github.com/z00m128/sjasmplus/)
[![BSD 3-Clause License](https://img.shields.io/github/license/z00m128/sjasmplus.svg)](https://github.com/z00m128/sjasmplus/blob/master/LICENSE.md)
[![Coverage Status](https://coveralls.io/repos/github/z00m128/sjasmplus/badge.svg?branch=master)](https://coveralls.io/github/z00m128/sjasmplus?branch=master)
[![Language grade: C/C++](https://img.shields.io/lgtm/grade/cpp/g/z00m128/sjasmplus.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/z00m128/sjasmplus/context:cpp)
[![GNU/Linux](docs/img/linux-logo-24px.png)](https://www.linux.org/)
[![FreeBSD](docs/img/freeBSD-logo-24px.png)](https://www.freebsd.org/)
[![NetBSD](docs/img/NetBSD-logo-24px.png)](https://www.netbsd.org/)
[![Raspberry Pi](docs/img/raspberry-pi-logo-24px.png)](https://www.raspberrypi.org/)
[![macOS](docs/img/apple-logo-24px.png)](https://www.apple.com/lae/macos/)
[![Windows](docs/img/microsoft-windows-logo-24px.png)](https://www.microsoft.com/en-us/windows)

Command-line cross-compiler of assembly language for [Z80 CPU](https://en.wikipedia.org/wiki/Zilog_Z80).

Supports many [ZX-Spectrum](https://en.wikipedia.org/wiki/ZX_Spectrum) specific directives, has built-in Lua scripting engine and 3-pass design.

For GNU/Linux, BSD, Raspberry Pi, macOS and [Windows (click for exe)](https://github.com/z00m128/sjasmplus/releases/latest).

GNU make or CMake [installation methods](INSTALL.md) for your convenience.

Online [documentation](http://z00m128.github.io/sjasmplus/documentation.html) (it is also included in the binary-release zip for offline viewing).

Post issues, feedback, feature requests, etc on [github](https://github.com/z00m128/sjasmplus/issues).

Main Features
=============

* Full source of assembler available under BSD license, modify and extend as you wish
* Z80/R800/Z80N/i8080/LR35902 documented and undocumented opcodes support
* Macro language, defines, array of defines
* Built-in Lua scripting engine
* Conditional assembly, block repeating
* Modules (namespaces), local and temporary labels
* Source and binary file inclusion, include paths
* Multi file output, file updating, various types of exports
* Structures to work easily with structured data in memory (`STRUCT` pseudo-op)
* Virtual device mode for common machines: ZX 128, ZX Next, … (pseudo op `DEVICE`)
* ZX Spectrum specific directives and pseudo ops (SAVESNA, SAVETAP, SAVEHOB, INCHOB, INCTRD…)
* ZX Spectrum Next specific features and directives (Z80N, 8ki memory paging, `SAVENEX`)
* Correctness is assured by Cirrus-CI with 256+ automated tests (that's also 256+ examples of usage!)
* Fake instructions as `LD HL,DE` (`LD H,D:LD L,E`) and more
* Code inlining through colon (`LD A,C:INC A:PUSH AF:IFDEF FX:LD A,D:ENDIF`…)
* Very fast compilation: 1 million lines by 2-3 seconds on modern computer
* Multiline block comments and user’s messages

This repository was created by import from original Aprisobal's repository @ https://sourceforge.net/projects/sjasmplus/.
