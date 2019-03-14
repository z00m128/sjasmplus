# Automated tests of sjasmplus

## How to add test

Add `some.asm` file somewhere into `tests/` directory, and watch it being assembled (upon every commit or pull request) at Cirrus CI.

## But I want to have some ".asm" include file along it

Before the test is assembled, files are copied into temporary build directory. **Only** files with name "`some*.(asm|lua)`" from the directory of `some.asm` and sub-directories with name "`some*`" (with all files inside) (except `some.config` directory) are copied into temporary build directory. You can include any such file (keep paths relative to the position of `some.asm`).

But to avoid such helper files being assembled separately (mistaken for other test), use "`.i.asm`" extension (or other extension which does not end with "`.asm`").

## But my test needs to contain errors intentionally

Add next to it `some.lst` listing (produced also with `--lstlab` option), the successful test will then require identical
listing file output, while assembler may return error exit code.

Make sure the basename of listing file is identical with asm file basename.

## But I need other special option to compile it

Add `some.options` text file next to it with the required options (i.e. `echo "--zxnext" > some.options`).

The listing options are automatically added when the test is accompanied by `some.lst` file, do not add them manually.

Make sure the basename of options file is identical with asm file basename.

Keep include paths (for `-I` option) relative to base test file (`some.asm`) position (see above how to name and organize files for inclusion).

## But I also want to check if the produced file is binary identical

Add `some.tap` and/or `some.bin` files next to the test.

Make sure the basename of binary files are identical with asm file basename (only one TAP and one BIN supported at this moment, for multi-bin output verification the current test script must be extended, prepare such test and raise the issue on github).

## And I want a space in the test file name or sub-directory

Well, ok? Go ahead.

(In sanity without space insanity happens)

## There's too much clutter around the original `some.asm` file

If you add directory with `some.config` name, you can move `some.options`, `some.lst`, `some.tap` and `some.bin` files into it (this directory content is not copied into temporary build directory, so these files are not available to the test itself while being assembled).

## And I want to carelessly mix upper/lower case letters in file names, having different name in source and different on disk

You are obviously some user of some obsolete operating system. Grow up, install your Linux or MacOS today, and figure out why file names should be precisely identical in both source, and on disk (hint: modern file systems are case sensitive) (hint 2: just fix your file names, there is no workaround, the bug is on your side).

## Is my test assembled in the `tests/...` directory where the source is?

No. A copy from source directory is being assembled in "`build/tests/`" directory, and only some files are copied (and available) for the test, see "inclusion" rules near the start of this document, how to name files which are needed for assembling.

## But I want also a lollipop, rainbow and Swiss watches with fountain

As with any open source project with permissive license, you are free to fork yourself, a copy of this repository, and modify it to your liking.
