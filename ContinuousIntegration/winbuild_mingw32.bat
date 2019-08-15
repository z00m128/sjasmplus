pwd
@call winbuild_set_msys2_path.bat
rem MinGW build
mingw32-make -f Makefile.win clean
mingw32-make -f Makefile.win -j3
rem sjasmplus install
mingw32-make -f Makefile.win PREFIX=c:/tools/sjasmplus/ install
mingw32-make -f Makefile.win clean
dir c:\tools\sjasmplus
sjasmplus --version
rem try to run test script already here (experiment)
bash ContinuousIntegration/test_folder_examples.sh
rem  bash ContinuousIntegration\test_folder_examples.sh
echo "ok"