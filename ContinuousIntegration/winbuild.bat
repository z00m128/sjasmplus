rem Exploring the VM image and what is available
path
dir /w
dir /w C:\ProgramData\chocolatey\lib\mingw\tools\install\mingw64\bin
dir /w C:\tools\msys64
dir /w C:\tools\msys64\clang32
dir /w C:\tools\msys64\clang64
dir /w C:\tools\msys64\mingw32
dir /w C:\tools\msys64\mingw64
dir /w C:\tools\msys64\opt
dir /w C:\tools\msys64\usr
dir /w C:\tools\msys64\usr\bin
type C:\tools\msys64\msys2_shell.cmd

rem MinGW make experiments
mingw32-make -f Makefile.win clean
mingw32-make -f Makefile.win
mingw32-make -f Makefile.win PREFIX=c:/tools/sjasmplus install
mingw32-make -f Makefile.win clean
dir /w c:\tools
dir /w c:\tools\sjasmplus
rem  bash ContinuousIntegration/test_folder_examples.sh
rem  bash ContinuousIntegration\test_folder_examples.sh

rem CMAKE experiments
del Makefile
ren Makefile.win Makefile
mkdir build
cd build
cmake --help
cmake -DCMAKE_BUILD_TYPE=Release ..
dir /w
msbuild sjasmplus.vcxproj
