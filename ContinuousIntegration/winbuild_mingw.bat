@rem NOT NEEDED right now, GIT has them all: choco install -y --no-progress diffutils findutils

@call ContinuousIntegration\winbuild_priority_for_git_path.bat
rem MinGW build
mingw32-make -f Makefile.win clean
mingw32-make -f Makefile.win -j3
dir /N sjasmplus.exe
rem sjasmplus install
mingw32-make -f Makefile.win PREFIX=c:/tools/sjasmplus/ install
mingw32-make -f Makefile.win clean
rem check installation and paths
dir /N c:\tools\sjasmplus
sjasmplus --version
sjasmplus --help
