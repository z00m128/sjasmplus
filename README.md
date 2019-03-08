# sjasmplus
[![Build Status](https://api.cirrus-ci.com/github/z00m128/sjasmplus.svg)](https://cirrus-ci.com/github/z00m128/sjasmplus)
![GitHub repo size in bytes](https://img.shields.io/github/repo-size/z00m128/sjasmplus.svg)
![GitHub](https://img.shields.io/github/license/z00m128/sjasmplus.svg)

Command-line cross-compiler of assembly language for Z80 CPU. 

Supports many ZX-Spectrum specific directives, has built-in Lua scripting engine and 3-pass design.

For Linux/BSD/Windows/Dos. Make/Make Install or CMake installation methods for your convenience.

Main Features
=============

- Z80/R800 documented and undocumented opcodes support
- Very fast compilation: 1 million lines by 2-3 seconds on modern computer
- Code inlining through colon (LD A,C:INC A:PUSH AF:IFDEF FX:LD A,D:ENDIF…)
- Structures to define data structures in memory more easily (STRUCT pseudo-op)
- Conditional assembly
- Macro definitions
- Local labels
- User messages
- Temporary labels
- Defines and array of defines
- Fake instructions as LD HL,DE (LD H,D:LD L,E) and more
- Source and binary file inclusion
- Multiline block comments
- Multi file output and file updating
- ZX Spectrum device emulation mode (pseudo op DEVICE)
- ZX Spectrum specific directives and pseudo ops (SAVESNA, SAVETAP, SAVEHOB, INCHOB, INCTRD...)
- Suport for the Z80n found in the ZX Spectrum Next

This repository was created by import from original Aprisobal's repository @ https://sourceforge.net/projects/sjasmplus/.
