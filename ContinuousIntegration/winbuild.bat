path
dir /w
dir /w C:\ProgramData\chocolatey\lib\mingw\tools\install\mingw64\bin
dir /w C:\tools\msys64
@rem MinGW make experiments
mingw32-make --help
rem  make -f Makefile.win clean
rem  make -f Makefile.win
rem  make -f Makefile.win install
rem  bash ContinuousIntegration/test_folder_examples.sh
rem  bash ContinuousIntegration\test_folder_examples.sh
@rem CMAKE experiments
del Makefile
ren Makefile.win Makefile
mkdir build
cd build
cmake --help
cmake -DCMAKE_BUILD_TYPE=Release ..
dir /w
