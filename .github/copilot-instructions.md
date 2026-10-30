# Copilot Instructions for sjasmplus

## Project Overview
- **sjasmplus** is a cross-platform Z80 assembler with advanced features for ZX Spectrum, ZX Next, Amstrad CPC, and related platforms.
- Written in C++ (see `sjasm/`), with Lua scripting support (see `lua5.5/` and `sjasm/lua_sjasm.cpp`).
- Major components: assembler core (`sjasm/`), Lua integration, and extensive test suites (`cpp-src-tests/`, `tests/`, `examples/`).

## Build & Test Workflows
- **Build (Linux/macOS):**
  - Use `make -j8` from the project root.
- **After header edits (required for Makefile builds):**
  - Header dependency tracking is incomplete, especially for the `+ut` objects used by `make test`. Run `make clean` before building or testing after changing headers; a passing test run with reused objects does not validate the header changes.
  - Clean and rebuild with matching configuration options: for example, `make clean && make -j8 test TEST=misc`, or `make DEBUG=1 clean && make -j8 DEBUG=1 test TEST=misc` for debug. Clean each configuration that will be reused.
  - Run clean and build/test as separate sequential commands, not as parallel goals such as `make -j8 clean test`. This workaround is for the handwritten Makefile, not CMake builds.
- **Build (Windows):**
  - Use `Makefile.win` or project files (`sjasmplus.cbp`, `sjasmplus.workspace`).
- **Run tests:**
  - Full suite: `make test` runs the C++ unit tests, feature-focused assembler tests in `tests/`, and examples.
  - Focused feature tests: `make test TEST=<folder-prefix>` runs matching tests through `ContinuousIntegration/test_folder_tests.sh` (for example, `make test TEST=misc`). This skips the C++ unit tests and examples.
- **CI/CD:**
  - **GitHub Actions** (`.github/workflows/`): Linux GCC toolchain matrix, FreeBSD/macOS Clang, Windows MinGW, Windows CMake/MSVC, and coverage reporting.
  - **GitHub Actions** (`.github/workflows/`): CodeQL security analysis builds, and reproducibility testing (see below).
  - Cirrus CI: Cirrus was primary CI platform, but it's gone since 2026-06-01, so Cirrus jobs were migrated to GitHub Actions. Any mentions of Cirrus should describe the migration only.
- **Binary Reproducibility Testing** (see issue #235):
  - **Workflow**: `.github/workflows/reproducibility.yml` runs weekly (Friday 8 AM UTC) or on manual trigger (`workflow_dispatch`).
  - **Tools**: `reprotest` (Debian Reproducible Builds toolkit) verifies that builds with environmental variations (users, timezones, locales, etc.) produce identical binaries.
  - **Docker setup**: `ContinuousIntegration/Dockerfile.reprotest` contains the reprotest environment; also usable locally with `docker run` for testing before release.
  - **Running locally**: `docker build -f ContinuousIntegration/Dockerfile.reprotest -t reprotest-env . && docker run --rm --privileged -v $(pwd):/workspace -w /workspace reprotest-env bash -c "reprotest --vary=+all 'make clean && make -j4' sjasmplus"`

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
  - **Architecture & design**: The "Assembling Process" chapter covers core mechanics (three-pass model, per-line substitution rules, macro expansion). Reference this when understanding how features interact across passes.
  - Long-standing documentation gaps (e.g., #37 on substitution rules, #182 on pass mechanics) are best addressed via integrated explanatory chapters, not scattered feature notes.

## Project-Specific Notes
- **Multi-platform:**
  - Code and build scripts support Linux, macOS, Windows, and CI (see `ContinuousIntegration/` and `.github/workflows/ci.yml`).
- **Broad feature-regression coverage; new features are almost always developed using TDD.**
  - The C++ `UnitTest++` suite in `cpp-src-tests/` is small (roughly 1% source coverage) and supplements the assembler-level feature tests; it is not the primary feature test suite.
  - Tests in `tests/` run the actual assembler end-to-end and compare outputs. In common terminology these are integration tests, but within this project they are the feature/unit tests used to develop and regress individual assembler behaviors.
  - `make test TEST=<folder-prefix>` is the normal way to run a focused subset of these feature tests during development.
  - Broader assembly projects live in `tests/integration/` and `examples/`; these exercise complete usage scenarios rather than targeting one implementation feature.
  - `tests/` tests consist of main .asm file, all related files must have identical stem name, providing listing file .lst will allow for assembling errors (as long as listing does match, ie. errors were listed), otherwise test must assemble without errors. If assembling without errors is expected, test should rather produce binary to compare end result.
  - listing files contain source files names as they are opened/closed, their line numbers, memory address and emitted machine code bytes and original source with some substitutions applied. Error and warning messages are also included on separate lines ahead of the line causing them.
  - To add a feature test, create a `.asm` file in the appropriate `tests/` subfolder and add its expected listing/binary outputs as needed. Run the matching subset with `make test TEST=<folder-prefix>` while developing; `ContinuousIntegration/test_folder_tests.sh` is also used by the full `make test` target and CI.
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
- Test: `make test`
- See `README.md` and `docs/documentation.html` for more details

## Common Development Patterns
- **Pass-aware logic**: Features may depend on multiple passes or require virtual memory. Test with both pipe mode and device mode when applicable.
- **Backward compatibility**: Multi-platform and device support matter; avoid breaking existing `.asm` files.
- **Incremental testing**: Add `.asm` test files first, generate `.lst` or binary, patch expected results, then implement feature until test passes (TDD approach).
- **Substitution system** (key feature, different from typical software):
  - Happens per-line during assembly (not as pre-processing stage). See section "Assembling Process" in `docs/documentation.xml` for formal rules.
  - Macro arguments → DEFINE symbols → DEFARRAY (iterated ~30 times until convergence).
  - Defines starting with `_` have restricted matching (beginning-of-identifier only) to prevent accidental mid-word collisions.
  - Glue operator `_` (space-enclosed) removes whitespace between substitution results; enables dynamic label assembly (e.g., `part1 _ part2` → `part1part2`).
  - Implementation: `ReplaceDefineInternal()` in `parser.cpp`, called iteratively until no more replacements.
- **Documentation approach**:
  - Long-standing feature gaps (e.g., issue #37 on substitution rules) are addressed via integrated *architecture* chapters (e.g., "Assembling Process"), not scattered feature notes.
  - When adding major features, consider whether a doc chapter needs updating or a new explanatory section is warranted. See `docs/documentation.xml` for chapter structure.

## C++ Code Style
- this is legacy project, so style may vary between different parts of codebase, but generally:
  - The project currently targets C++17 in both Make and CMake. Keep new code C++17-compatible by default, but call out significant C++17-vs-C++20 opportunities and weigh their benefits against the lowest supported compiler/toolchain. If a C++20 feature materially improves the code, recommend a deliberate standard bump; if the benefit is too small, keep the C++17-compatible approach (a brief TODO can record a worthwhile deferred idea). Do not silently introduce C++20-only requirements.
  - avoid reformatting of existing code unless it is being modified as part of functional change (no cosmetic-only changes)
  - use tabs (viewed as 4 space wide) for indentation in sjasm/ C++ files, use 2 or 4 spaces in .asm test files (mainly follow other files in the same dir)
  - opening braces on same line
  - use `//` for single-line comments, try to avoid `/* ... */` multi-line comments as they make it harder to temporarily comment out code during development
  - use `nullptr` over `NULL` or `0` for pointers in new code
  - use `override` keyword for overridden virtual functions
  - prefer range-based for loops where applicable
  - follow existing patterns in the codebase for consistency unless modern practice leads to lot simpler code
  - implementation code is often a bit terse, but straightforward without adding too many layers of indirection and abstractions
  - often implement in-place first, extract to functions later when same-ish code appears multiple times and practical API design emerges
  - in comparisons use only less or less/equal, ie. `if (0 <= x && x < 100)`, not `if (x >= 0 && x < 100)`

---

*Update this file if you add new major features, workflows, or conventions. For detailed usage, see the documentation files referenced above.*
