@echo off
del sjasmplus*
cd ..
set DJGPP=.\..\..\..\C++\Compilers\DJGPP\djdev203\DJGPP.ENV
set LFN=y
set PATH=.\..\..\..\C++\Compilers\DJGPP\djdev203\bin;%PATH%
rem set C=gpp.exe -s -O3 -Llib -DMAX_PATH=PATH_MAX sjasm.cpp sjio.cpp tables.cpp reader.cpp z80.cpp parser.cpp
rem support.cpp directives.cpp io_trd.cpp io_tape.cpp io_snapshots.cpp

gpp.exe -O3 -Llib -DMAX_PATH=PATH_MAX -c directives.cpp -o 1.o
gpp.exe -O3 -Llib -DMAX_PATH=PATH_MAX -c io_snapshots.cpp -o 2.o
gpp.exe -O3 -Llib -DMAX_PATH=PATH_MAX -c io_tape.cpp -o 3.o
gpp.exe -O3 -Llib -DMAX_PATH=PATH_MAX -c io_trd.cpp -o 4.o
gpp.exe -O3 -Llib -DMAX_PATH=PATH_MAX -c parser.cpp -o 5.o
gpp.exe -O3 -Llib -DMAX_PATH=PATH_MAX -c reader.cpp -o 6.o
gpp.exe -O3 -Llib -DMAX_PATH=PATH_MAX -c sjasm.cpp -o 7.o
gpp.exe -O3 -Llib -DMAX_PATH=PATH_MAX -c sjio.cpp -o 8.o
gpp.exe -O3 -Llib -DMAX_PATH=PATH_MAX -c support.cpp -o 8a.o
gpp.exe -O3 -Llib -DMAX_PATH=PATH_MAX -c tables.cpp -o 9.o
gpp.exe -O3 -Llib -DMAX_PATH=PATH_MAX -c z80.cpp -o 10.o

gpp.exe -O3 -Llib -DMAX_PATH=PATH_MAX 1.o 2.o 3.o 4.o 5.o 6.o 7.o 8.o 8a.o 9.o 10.o

del *.o

strip.exe a.exe
djp a.exe
del a.out
copy a.exe dos\a.exe
del a.exe
cd dos
exe2coff.exe a.exe
COPY /B CWSDSTUB.EXE+a sjasmplus_dos_stub.exe
del a
ren a.exe sjasmplus_dos.exe
pause

