# Automated tests of sjasmplus


## How to run tests

Test "runner" is BASH script, so you need UNIX-like environment with bash (late v3.x+ should be enough). From project root directory enter `ContinuousIntegration/test_folder_tests.sh` (or `ContinuousIntegration/test_folder_examples.sh` for *examples* test-build).

The script `build_tests_in_place.sh` is internal helper to rebuild most of the tests outputs (and its results are not always correct and one has to manually validate+prune them before committing changes to git), used to refresh files when some change of sjasmplus does affect (intentionally) old tests outputs.

### Extra arguments and configuration of test runner

To run only some tests you can add the beginning of the directory path as argument: `..tests.sh dev` will try to build only tests from all directories `tests/dev*`.

To run tests with specific executable, set up EXE environment-variable before running the script, like: `EXE=sjasmplus1.10.4 ContinuousIntegration/test_folder_tests.sh`

### Common issues (mostly MS Windows specific)

If your terminal shows ANSI colour escape sequences literally (and they clutter your output a lot), you can disable output colouring by: `NOCOLOR=1 ContinuousIntegration/test_folder_tests.sh` command line.

Unfortunately some "binary" files in tests directory representing expected results contain only ASCII-text values with UNIX new-line value (LF = 10). The git itself is capable to modify new-line sequences between LF and CRLF (13, 10) during checkout and push operations, which is convenient for text files, but does damage the "binary" text files. Such modified files with CRLF sequence will make some tests fail. Configure the sjasmplus project git to support only UNIX line endings, and checkout/push files like that (this may then cause other problems, like inability to edit source files with Notepad.exe, but most modern tools/editors allow for LF only new lines even in MS Windows environments, so you should be able to find tools working with it). While it would be possible to mark `bin|tap|raw` files as "binary" in `.gitattributes` file, I'm not sure if it would fix 100% of problems, and generally sjasmplus project is supported as LF-only (to keep things simpler for lazy maintainers like me).


## How to add test

Add `some.asm` file somewhere into `tests/` directory, and watch it being assembled (upon every commit or pull request) at Cirrus CI.

### But I want to have some ".asm" include file along it

Before the test is assembled, files are copied into temporary build directory. **Only** files with name "`some*.(asm|lua)`" from the directory of `some.asm` and sub-directories with name "`some*`" (with all files inside) (except `some.config` directory) are copied into temporary build directory. You can include any such file (keep paths relative to the position of `some.asm`).

But to avoid such helper files being assembled separately (mistaken for other test), use "`.i.asm`" extension (or other extension which does not end with "`.asm`").

### But my test needs to contain errors intentionally

Add next to it `some.lst` listing (produced also with `--lstlab` option), the successful test will then require identical
listing file output, while assembler may return error exit code.

Make sure the basename of listing file is identical with asm file basename.

### But I need other special option to compile it

Add `some.options` text file next to it with the required options (i.e. `echo "--zxnext" > some.options`).

The listing options are automatically added when the test is accompanied by `some.lst` file, do not add them manually.

Make sure the basename of options file is identical with asm file basename.

Keep include paths (for `-I` option) relative to base test file (`some.asm`) position (see above how to name and organize files for inclusion).

### But I also want to check if the produced file is binary identical

Add `some.tap`, `some.bin` and/or `some.raw` files next to the test.

Make sure the basename of binary files are identical with asm file basename (only one TAP, one BIN and one RAW are supported at this moment, for multi-bin output verification the current test script must be extended, prepare such test and raise the issue on github).

### But I also want to check symbol/export/label files are identical

Add `some.sym`, `some.exp` and/or `some.lbl` files next to the test and add those outputs into `some.options` file or use directives in source to produce them.

Make sure the basename of files are identical with asm file basename.

### And I want a space in the test file name or sub-directory

Well, ok? Go ahead.

(In sanity without space insanity happens)

### There's too much clutter around the original `some.asm` file

If you add directory with `some.config` name, you can move `some.options`, `some.lst` and `some.tap|bin|raw|sym|exp|lbl` files into it (this directory content is not copied into temporary build directory, so these files are not available to the test itself while being assembled).

### And I want to carelessly mix upper/lower case letters in file names, having different name in source and different on disk

You are obviously some user of some obsolete operating system. Grow up, install your Linux or MacOS today, and figure out why file names should be precisely identical in both source, and on disk (hint: modern file systems are case sensitive) (hint 2: just fix your file names, there is no workaround, the bug is on your side).

### Is my test assembled in the `tests/...` directory where the source is?

No. A copy from source directory is being assembled in "`build/tests/`" directory, and only some files are copied (and available) for the test, see "inclusion" rules near the start of this document, how to name files which are needed for assembling.

### But I want also a lollipop, rainbow and Swiss watches with fountain

As with any open source project with permissive license, you are free to fork yourself, a copy of this repository, and modify it to your liking.
