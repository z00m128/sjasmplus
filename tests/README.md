# Automated tests of sjasmplus

## How to add test

Add `some.asm` file somewhere into `tests/` directory, and watch it being assembled (upon every commit or pull request) at Cirrus CI.

## But I want to have some ".asm" include file along it

To avoid include files being assembled, you **must** use "`.i.asm`" extension (or any other which does not end with ".asm").

## But my test needs to contain errors intentionally

Add next to it `some.lst` listing (produced also with `--lstlab` option), the successful test will then require identical
listing file output, while assembler may return error exit code.

Make sure the basename of listing file is identical with asm file basename.

## But I need other special option to compile it

Add `some.options` text file next to it with the required options (i.e. `echo "--zxnext" > some.options`).

The listing options are automatically added when the test is accompanied by `some.lst` file.

The include path for the directory of test itself is added automatically.

Make sure the basename of options file is identical with asm file basename.

## But I also want to check if the produced file is binary identical

Add `some.tap` and/or `some.bin` files next to the test.

Make sure the basename of binary files are identical with asm file basename (only one TAP and one BIN supported at this moment, for multi-bin output verification the current test script must be extended, prepare such test and raise the issue on github).

## And I want a space in the test file name or sub-directory

Well, ok? Go ahead.

(In sanity without space insanity happens)

## And I want to carelessly mix upper/lower case letters in file names, having different name in source and different on disk

You are obviously some user of some obsolete operating system. Grow up, install your Linux or MacOS today, and figure out why file names should be precisely identical in both source, and on disk (hint: modern file systems are case sensitive) (hint 2: just fix your file names, there is no workaround, the bug is on your side).

## Is my test assembled in the same working directory where the source is?

No. It's being assembled from `build/tests/` directory. If you have trouble implementing some idea under this condition, raise an issue on github and describe your idea, but for the sake of tests simplicity and self-containment, the current system should be enough (unless somebody shows me good use case and proves me wrong).

## But I want also a lollipop, rainbow and Swiss watches with fountain

As with any open source project with permissive license, you are free to fork yourself, a copy of this repository, and modify it to your liking.
