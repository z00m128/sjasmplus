rem Exploring the VM image and what is available
set PATH=%PATH%;C:\tools\msys64\usr\bin\
path

@rem dir /w
@rem dir /w C:\ProgramData\chocolatey\lib\mingw\tools\install\mingw64\bin
@rem dir /w C:\tools\msys64
@rem dir /w C:\tools\msys64\clang32
@rem dir /w C:\tools\msys64\mingw32
@rem dir /w C:\tools\msys64\opt
@rem dir /w C:\tools\msys64\usr
@rem dir /w C:\tools\msys64\usr\bin
@rem type C:\tools\msys64\msys2_shell.cmd
@rem (does terminate the script completely?!) msys2_shell bash --version
bash --version
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
vcvars64.bat
msbuild sjasmplus.vcxproj
find "C:/Program Files (x86)/Microsoft Visual Studio" -name vcvars64.bat
find "C:/Program Files (x86)/Microsoft Visual Studio" -name msbuild.exe
