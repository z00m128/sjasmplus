rem Set GIT directory as priority (over MS crap) path to borrow GNU: bash, find, diff, cmp
rem and add sjasmplus to the path
set PATH=C:\Program Files\Git\usr\bin\;%PATH%;c:\tools\sjasmplus

rem test availability and version of all required tooling
where bash
bash --version
where find
find --version
where diff
diff --version
where cmp
cmp --version
where gcc
gcc --version
where mingw32-make
mingw32-make --version
