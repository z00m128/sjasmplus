# Copilot Instructions for sjasmplus

## Project Overview
- **sjasmplus** is a cross-platform Z80 assembler with advanced features for ZX Spectrum, ZX Next, Amstrad CPC, and related platforms.
- Written in C++ (see `sjasm/`), with Lua scripting support (see `lua5.5/` and `sjasm/lua_sjasm.cpp`).
- Major components: assembler core (`sjasm/`), Lua integration, and extensive test suites (`cpp-src-tests/`, `tests/`, `examples/`).

## Build & Test Workflows
- **Build (Linux/macOS):**
  - Use `make -j8` from the project root.
- **Build (Windows):**
  - Use `Makefile.win` or project files (`sjasmplus.cbp`, `sjasmplus.workspace`).
- **Run tests:**
  - Unit tests: `make tests`, filter set of tests by adding TEST=<subfolder_name> (subfolders in tests/), like `make tests TEST=misc`

## Assembler Architecture: Three-Pass Model
Understanding the pass structure is critical for feature development:
- **Pass 1 & 2**: Dry runs that define labels, compute expression values, and validate structure. NO machine code is emitted.
- **Pass 3**: Emits actual machine code. Code size must match Pass 2 for correctness; mismatches indicate label/expression evaluation errors.
- **Device (virtual memory)**: Acts as an extended memory array. In-memory assembly enables post-fact directives (e.g., `SAVEBIN`) and iterative content manipulation (reassemble over existing memory, save variants). Without a device, output is "pipe mode" (streaming) and doesn't support these features.
- **Implication**: Some features (e.g., memory-dependent directives) require virtual memory; validate test cases with both pipe mode and device mode.

## Key Conventions & Patterns
- **Directives and pseudo-ops** are registered in `sjasm/directives.cpp` (`InsertDirectives()`), supporting custom syntax and device-specific features.
- **Device emulation** is modular; new devices can be added in `sjasm/devices.cpp` and `sjasm/devices.h`. Device is mostly infrastructure; focus on correctness of assembler core.
- **Lua scripting** is user-facing automation and macros. Development on Lua integration only needed when extending API (see `sjasm/lua_sjasm.cpp` and `lua5.5/`); most features don't touch it.
- **Testing:**
  - Unit tests use custom test runners in `cpp-src-tests/`.
  - Many usage examples double as integration tests in `examples/` and `tests/`.
- **Documentation:**
  - Main docs: `docs/documentation.html` (generated from `docs/documentation.xml`), also available online.
  - Build/install: `Makefile`, `INSTALL.md`.

## Project-Specific Notes
- **Multi-platform:**
  - Code and build scripts support Linux, macOS, Windows, and CI (see `ContinuousIntegration/` and `.cirrus.yml`).
- **High test coverage, new features are almost always developed by TDD approach.**
  - most of the features are tested end-to-end via tests in `tests/`, providing both example of usage and ensuring resulting binaries and listing files
  - `tests/` tests consist of main .asm file, all related files must have identical stem name, providing listing file .lst will allow for assembling errors (as long as listing does match, ie. errors were listed), otherwise test must assemble without errors. If assembling without errors is expected, test should rather produce binary to compare end result.
  - listing files contain source files names as they are opened/closed, their line numbers, memory address and emitted machine code bytes and original source with some substitutions applied. Error and warning messages are also included on separate lines ahead of the line causing them.
  - to add new test to project just create new .asm file in appropriate subfolder of `tests/`, you can generate listing and binary files by running sjasmplus itself, then patch the result to expected content and keep implementing the feature until test passes. The new test will be automatically picked up by `ContinuousIntegration/test_folder_tests.sh` which is used also by `make tests` and Cirrus CI.
- **Examples as tests:**
  - Many `.asm` files in `examples/` and `tests/` are used for regression and feature testing.
- **Notable features:**
  - Support for advanced Z80 dialects, device-specific pseudo-ops, and custom file formats (see `sjasm/io_*.cpp`).
  - Extensive command-line options (see `docs/documentation.html`, section "Command line").

## Integration Points
- **LuaBridge** (`LuaBridge/`): C++/Lua binding for scripting.
- **crc32c/**: Used for file checksums.
- **3rd-party test frameworks:**
  - `unittest-cpp/` for C++ unit tests.
  - GoogleTest is present in some submodules, but it's used only for their development, not by sjasmplus itself.

## Quick Start
- Build: `make`, resulting binary will be copied also to root as `sjasmplus`
- Run: `./sjasmplus [options] sourcefile.asm`
- Test: `make tests`
- See `README.md` and `docs/documentation.html` for more details

## Common Development Patterns
- **Pass-aware logic**: Features may depend on multiple passes or require virtual memory. Test with both pipe mode and device mode when applicable.
- **Backward compatibility**: Multi-platform and device support matter; avoid breaking existing `.asm` files.
- **Incremental testing**: Add `.asm` test files first, generate `.lst` or binary, patch expected results, then implement feature until test passes (TDD approach).

## C++ Code Style
- this is legacy project, so style may vary between different parts of codebase, but generally:
  - new code should mostly follow existing style in the file being modified, but also lean toward modern C++20 practice
  - avoid reformatting of existing code unless it is being modified as part of functional change (no cosmetic-only changes)
  - use 4 spaces for indentation, no tabs
  - opening braces on same line
  - use `//` for single-line comments, try to avoid `/* ... */` multi-line comments as they make it harder to temporarily comment out code during development
  - use `nullptr` over `NULL` or `0` for pointers in new code
  - use `override` keyword for overridden virtual functions
  - prefer range-based for loops where applicable
  - follow existing patterns in the codebase for consistency
  - implementation code is often a bit terse, but straightforward without adding too many layers of indirection and abstractions
  - often implement in-place first, extract to functions later when same-ish code appears multiple times and practical API design emerges

---

*Update this file if you add new major features, workflows, or conventions. For detailed usage, see the documentation files referenced above.*
