Installation Instructions
=========================

Requirements:
- Linux / Unix / MacOS / BSD with bash compatible shell 
- all common system progs (grep, cat, etc...)
- all common build requirements (libc, libstdc++, g++, make, etc...)
- optionally cmake

or

- complete MinGW environment for MS Windows, optionally CMake installed into MinGW bin directory

Compilation is tested with GCC 5.3.0, it should run also with older versions, but warnings or errors may occur.

Make / Make Install method for Linux / Unix / MacOS / BSD
=========================================================

- download sjasmplus tarball archive
- extract tarball archive and go to extracted folder
- edit install path PREFIX in file 'Makefile' according your preferences (default /usr/local)
- run make clean
- run make
- run make install as root or use sudo

Make / Make Install method for MS Windows
=========================================

- download sjasmplus tarball archive
- extract tarball archive and go to extracted folder
- delete or rename file 'Makefile'
- edit install path PREFIX in file 'Makefile.win' according your preferences (default c:\mingw\usr\local)
- rename file 'Makefile.win' to 'Makefile'
- run mingw32-make clean
- run mingw32-make
- run mingw32-make install


CMAKE method for Linux / Unix / MacOS / BSD
===========================================

Extract tarball archive, go to extracted folder and run following set of commands:

	mkdir build 
	cd build
	cmake -DCMAKE_BUILD_TYPE=Release ..
	make
	make install

You can have external Lua and ToLua, it is detected automatically. If not, internal version is used.

For disabling of LUA scripting support add following option:

	-DENABLE_LUA=OFF 

	E.g: cmake -DENABLE_LUA=OFF ..

Binary sjasmplus file will be placed in /usr/bin by default.

To change install directory prefix add following option with specified prefix:

	-DCMAKE_INSTALL_PREFIX:PATH=/usr/local

	e.g: cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr/local ..


MS Windows and MinGW with cmake
===============================

- extract tarball archive and go to the extracted folder
- delete or rename file 'Makefile'
- rename file 'Makefile.win' to 'Makefile'
- create 'build' subdirectory and enter to it
- run 'cmake-gui' tool
- click 'Browse Source...' button, select extracted tarball folder
- click 'Browse Build...' button, select the 'build' folder
- click 'Configure' button, select 'MinGW Makefiles', select 'Use default native compilers'
- click 'Finish' and wait until configuration is done
- change CMAKE_INSTALL_PREFIX install path according your peferences (click on path)
- click 'Generate'

Enjoy!
