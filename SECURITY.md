# Security Policy

## Supported Versions

None, this software is by design vulnerable to attacks even when working as intended.

Do not host sjasmplus assembler online as service unless you sandboxed the hosting
machine properly and isolated the sjasmplus process to maximum extent, as the
assembler itself provides legit ways to [create/patch](https://z00m128.github.io/sjasmplus/documentation.html#po_output) and [execute](https://z00m128.github.io/sjasmplus/documentation.html#po_shellexec) custom binaries on host
system just by providing assembly source.

While assembling sources locally, make sure you trust the authors of the source code
or review it properly before assembling.

There's no need to look for any bugs in the code base to achieve things like RCE,
just regular usage offers this functionality built in, including Lua as scripting
language and powerful directives to work with files and their content.

If you are seriously interested into hosting sjasmplus as online service, open
github issue where we can discuss some basic ways to sanitize the available
directives, but don't expect miracles and you would have to put development
effort into it.

## Reporting a Vulnerability

Open github issue with your bug report, there's no need for any special regime
because of the nature of this software.

## Do you even want to hear about the bug?

All this said, we are still interested to hear about unintended behaviour like bugs,
and we will attempt to fix them, this file is just reminder this SW should be
never considered "safe" as it opens access to host machine in trivial way by design.
