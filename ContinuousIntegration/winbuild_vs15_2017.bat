rem Exploring the VM image and what is available
path

rem CMAKE experiments
del Makefile
ren Makefile.win Makefile
mkdir build
cd build
cmake --help
cmake -DCMAKE_BUILD_TYPE=Release ..
dir /w
vcvars64.bat
msbuild sjasmplus.vcxproj

C:\tools\msys64\usr\bin\find "C:/Program Files (x86)/Microsoft Visual Studio" -name vcvars64.bat
C:\tools\msys64\usr\bin\find "C:/Program Files (x86)/Microsoft Visual Studio" -name msbuild.exe
