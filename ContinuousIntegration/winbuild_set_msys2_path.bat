rem Borrow bash and other tools from MSYS2 (and put them ahead of other MS crap)
set PATH=C:\tools\msys64\usr\bin\;%PATH%;c:\tools\sjasmplus
bash --version
diff --version
cmp --version
find --version
gcc --version
mingw32-make --version
