rem Exploring the VM image and what is available
path

rem CMAKE windows build with MS compiler
del Makefile
ren Makefile.win Makefile
mkdir build
cd build
@rem cmake --help
cmake --config Release ..
dir /w
@rem C:\tools\msys64\usr\bin\find "C:/Program Files (x86)/Microsoft Visual Studio" -iname vcvars64.bat -type f
@rem C:\tools\msys64\usr\bin\find "C:/Program Files (x86)/Microsoft Visual Studio" -iname msbuild.exe -type f
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
path
echo "Starting build by running msbuild.exe"
msbuild sjasmplus.vcxproj
copy Debug\sjasmplus.exe sjasmplus.exe
copy Release\sjasmplus.exe sjasmplus.exe
dir Debug\sjasmplus.exe
dir Release\sjasmplus.exe
dir sjasmplus.exe
