@call ContinuousIntegration\winbuild_priority_for_git_path.bat

rem Exploring the VM image and what is available
rem STATUS: no MSC compiler installed in the image? Seems I need to install it myself every build

rem DEBUG search for Visual Studio and C compiler, when the windows image does change and paths breaks
path
dir /W "C:\Program Files"
dir /W "C:\Program Files (x86)"

dir /W "C:\Program Files (x86)\Microsoft Visual Studio\2019"
dir /W "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools"
dir /W "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild"
dir "C:\Program Files (x86)\Microsoft Visual Studio\2019\*.bat" /s /b
dir "C:\Program Files (x86)\Microsoft Visual Studio\2019\*.exe" /s /b
dir "C:\ProgramData\chocolatey\bin\*.bat" /s /b
dir "C:\ProgramData\chocolatey\bin\*.exe" /s /b
dir "C:\ProgramData\chocolatey\lib\*.bat" /s /b
dir "C:\ProgramData\chocolatey\lib\*.exe" /s /b

dir "C:\Program Files (x86)\Microsoft Visual Studio\*vcvars64.bat" /s /b
dir "C:\Program Files (x86)\Microsoft Visual Studio\*vcvarsall.bat" /s /b

rem Setup MSCC (VSC) by calling the vcvars batch file, TODO: rework with "where" or "dir /s /b" output?
rem call "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
rem for /f "delims=" %%I in ('dir "%ProgramFiles(x86)%\*vcvars64.bat" /s /b') do call "%%I"
path

rem CMAKE windows build with MS compiler
del Makefile
ren Makefile.win Makefile
mkdir build
cd build
@rem cmake --help
cmake --config Release ..
if %ERRORLEVEL% NEQ 0 exit /b 1

dir /W
echo "Starting build by running msbuild.exe"
msbuild sjasmplus.vcxproj /property:Configuration=Release
if %ERRORLEVEL% NEQ 0 exit /b 1
echo "installing to c:\tools\sjasmplus"
@echo on
mkdir c:\tools\sjasmplus
copy Debug\sjasmplus.exe c:\tools\sjasmplus\sjasmplus.exe
copy Release\sjasmplus.exe c:\tools\sjasmplus\sjasmplus.exe
rem check installation and paths
dir /N c:\tools\sjasmplus
sjasmplus.exe --version
sjasmplus.exe --help
