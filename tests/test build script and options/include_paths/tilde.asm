; testing multiple new changes in v1.21.0:
; - include path options (i, I, inc) now can be provided with path by next following CLI argument, ie. "-I dir/"
;   (this allows the shell to expand ~/ paths to full path)
; - include path literally starting with "~" will be reported with hint to read docs (shell didn't expand it)
; - include path which can't be initially opened will be reported in error (missing dir?)
;
; (test is not testing if the shell did correctly expand "~" in normal use case, because it's not known
; how the test enviroment is set up, if it has $HOME and if it is related to running tests - leap of faith)
;
; (oh, it does not substitute it from test runner when provided in .options file any way... strange, but it's fine for this test)
;

    INCLUDE "tilde.i.asm"   ; verify the include path works
    INCLUDE <tilde.i.asm>
