rem Exploring the VM image and what is available
path

rem CMAKE windows build with MS compiler
del Makefile
ren Makefile.win Makefile
mkdir build
cd build
@rem cmake --help
cmake --config Release ..
dir /W
@rem C:\tools\msys64\usr\bin\find "C:/Program Files (x86)/Microsoft Visual Studio" -iname vcvars64.bat -type f
@rem C:\tools\msys64\usr\bin\find "C:/Program Files (x86)/Microsoft Visual Studio" -iname msbuild.exe -type f
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
path
echo "Starting build by running msbuild.exe"
msbuild sjasmplus.vcxproj /property:Configuration=Release
echo "installing to c:\tools\sjasmplus"
@echo on
mkdir c:\tools\sjasmplus
copy Debug\sjasmplus.exe c:\tools\sjasmplus\sjasmplus.exe
copy Release\sjasmplus.exe c:\tools\sjasmplus\sjasmplus.exe
dir /N c:\tools\sjasmplus\sjasmplus.exe
c:\tools\sjasmplus\sjasmplus.exe --version

rem Install diffutils for tests runner script
choco install -y --no-progress diffutils
