cd
@call ContinuousIntegration\winbuild_set_msys2_path.bat
rem MinGW build
mingw32-make -f Makefile.win clean
mingw32-make -f Makefile.win -j3
dir sjasmplus.exe
rem sjasmplus install
mingw32-make -f Makefile.win PREFIX=c:/tools/sjasmplus/ install
mingw32-make -f Makefile.win clean
dir sjasmplus.exe
dir c:\tools\sjasmplus
sjasmplus --version
