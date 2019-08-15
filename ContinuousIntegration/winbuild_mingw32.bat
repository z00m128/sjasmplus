rem Borrow bash and other tools from MSYS2
set PATH=C:\tools\msys64\usr\bin\;%PATH%
path
bash --version
mingw32-make --version
rem MinGW build
mingw32-make -f Makefile.win clean
mingw32-make -f Makefile.win -j3
mingw32-make -f Makefile.win PREFIX=c:/tools/sjasmplus/ install
mingw32-make -f Makefile.win clean
dir c:\tools\sjasmplus
set PATH=%PATH%;c:\tools\sjasmplus
path
sjasmplus --version
rem try to run test script already here (experiment)
bash ContinuousIntegration/test_folder_examples.sh
rem  bash ContinuousIntegration\test_folder_examples.sh
echo "ok"