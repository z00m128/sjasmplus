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
C:\tools\msys64\usr\bin\find "C:/Program Files (x86)/Microsoft Visual Studio" -iname vcvars64.bat -type f
C:\tools\msys64\usr\bin\find "C:/Program Files (x86)/Microsoft Visual Studio" -iname msbuild.exe -type f
"C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
path
msbuild sjasmplus.vcxproj
