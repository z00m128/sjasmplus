Installation Instructions
=========================

Requirements:
- Linux / Unix / MacOS / BSD with bash compatible shell 
- all common system progs (grep, cat, etc...)
- all common build requirements (libc, libstdc++, g++, make, etc...)
- optionally CMake

or

- complete MinGW environment for MS Windows, optionally CMake installed into MinGW bin directory

Compilation is tested with GCC 5.3.0, it should run also with older versions, but warnings or errors may occur.

Default method for Linux / Unix / MacOS / BSD
=========================================================

Extract tarball archive and go to extracted folder. Edit install path PREFIX in file 'Makefile' according your preferences (default /usr/local). Run following commands:

	make clean
	make
	make install as root or use sudo

Default method for MS Windows
=========================================

Extract tarball archive and go to extracted folder. Delete or rename file 'Makefile'. Edit install path PREFIX in file 'Makefile.win' according your preferences (default c:\mingw\usr\local\bin). Remove '-static' parameter in CFLAGS if you don't need standalone Windows executable (binary is MinGW dependant then, but it's smaller). Rename file 'Makefile.win' to 'Makefile', then run following commands:

	mingw32-make clean
	mingw32-make
	mingw32-make install

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


CMake method for MS Windows
===========================

Extract tarball archive and go to the extracted folder. Delete or rename file 'Makefile'. Rename file 'Makefile.win' to 'Makefile'. Create 'build' subdirectory and enter to it. Run following command:

	cmake-gui
	
Click 'Browse Source...' button, select extracted tarball folder. Click 'Browse Build...' button, select the 'build' folder. Click 'Configure' button, select 'MinGW Makefiles', select 'Use default native compilers'. Click 'Finish' and wait until configuration is done. Change CMAKE_INSTALL_PREFIX install path according your peferences (click on path). Click 'Generate'. Run 'cmd.exe', enter the build directory and run following commands:

	make
	make install	

Enjoy!
