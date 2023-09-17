
## Installation Instructions

Requirements:

- GNU/Linux / Unix / macOS / BSD with bash compatible shell
- all common system progs (grep, cat, etc...)
- all common build requirements (libc, libstdc++, g++, GNU make, etc...)
- optionally CMake

or

- complete MinGW environment for MS Windows, configured with MinGW bin directories added in `PATH` variable (typically `C:\MinGW\bin;` `C:\MinGW\msys\1.0\bin`) or possibly with any BASH emulator (e.g. the one which comes with [git for windows](https://gitforwindows.org/)) will do it instead of msys is missing / not set.
- CMake installed into MinGW bin directory (optionally)

Compilation is tested with GCC 5.5.0, it should run also with older 5.x versions. It will not work with GCC 4.x and older.

## Getting full source code of sjasmplus

Use `git` to clone the github repository and all git-submodules:

	git clone --recursive -j8 https://github.com/z00m128/sjasmplus.git

If you already have cloned repository without submodules, you can update submodules only by:

	git submodule update --init --recursive

If you are not using `git`, you can download and extract archive from releases, the manually added `.tar.xz` one (the automatically github provided  zip files are missing the submodules sources and will fail to build). Or you can download the github provided archives, but then you need to download each submodule individually and extract them to correct folders inside sjasmplus folder.

## Default method for GNU/Linux / Unix / macOS / BSD

Go to folder with sjasmplus project. Edit install path `PREFIX` in file `Makefile` according your preferences (default `/usr/local`). Run following commands:

	make clean
	make

Then run as root or use sudo:

	make install

### Gentoo GNU/Linux

Check [cizo2000's github gentoo-overlay/dev-util/sjasmplus](https://github.com/cizo2000/gentoo-overlay/tree/master/dev-util/sjasmplus) for ebuild files.

### Arch Linux

Recently (2022) it seems leo72 started providing AUR for z00m's fork of sjasmplus: [aur.archlinux.org/packages/sjasmplus-z00m128](https://aur.archlinux.org/packages/sjasmplus-z00m128) (AFAIK there's no connection with any maintainer of this project, but hopefully this will continue and provide good experience to AUR users, thanks leo72).

## Default method for MS Windows

Go to folder with sjasmplus project. Edit install path `PREFIX` in file `Makefile.win` according your preferences (default `c:\mingw\usr\local\bin`). Remove `-static` parameter in `CFLAGS` if you don't need standalone Windows executable (binary is MinGW dependant then, but it's smaller). Run following commands:

	make -f Makefile.win clean
	make -f Makefile.win
	make -f Makefile.win install

## CMAKE method for Linux / Unix / macOS / BSD

Go to folder with sjasmplus project and run following set of commands:

	cmake -DCMAKE_BUILD_TYPE=Release -S . -B build
	cmake --build build
	cmake --install build

The project will use internal copy of Lua 5.4.4 by default, but you can use system Lua 5.4 by using `-DSYSTEM_LUA=ON`.

For disabling of LUA scripting support add `-DENABLE_LUA=OFF` option:

	cmake -DENABLE_LUA=OFF -DCMAKE_BUILD_TYPE=Release -S . -B build

Binary sjasmplus file will be placed in `/usr/bin` by default.

To change install directory prefix add `-DCMAKE_INSTALL_PREFIX:PATH` option with specified prefix:

	cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr/local -DCMAKE_BUILD_TYPE=Release -S . -B build

## CMake method for MS Windows

Go to folder with sjasmplus project. Delete or rename file `Makefile`. Rename file `Makefile.win` to `Makefile`. Create `build` subdirectory and enter to it. Run following command:

	cmake-gui

Click `Browse Source...` button, select extracted tarball folder. Click `Browse Build...` button, select the `build` folder. Click `Configure` button, select `MinGW Makefiles`, select `Use default native compilers`. Click `Finish` and wait until configuration is done. Change `CMAKE_INSTALL_PREFIX` install path according your preferences (click on path). Click `Generate`. Run `cmd.exe`, enter the build directory and run following commands:

	make
	make install	

The CMake can generate also VS project files, and sources should compile with VS compiler, since
v1.14.1 the VS built executable should mostly work as well as MinGW, although there are still
corner-case bugs which need to be fixed, see issues #77 and #78 for details/progress and to help.

The official binary "exe" is built with MinGW toolchain and that's recommended option.

## Helping with sjasmplus development

There are few extra recommendations if you want to join sjasmplus development and use all the features:

- work with git clone of repository ideally, so you can easily update to latest source base, track your changes or review changes of other developers
- within the git repository init and update the submodules too, this will clone the UnitTest++ and LuaBridge2.8 repository which are required to build sjasmplus and unit tests (`git submodule init`,  `git submodule update`)
- linux + gcc + Makefile is the config of Ped7g, having access to the same config to re-create his workflow locally may be of help (when troubleshooting some issue or comparing results with different platform)
- but having different local configuration would be very helpful to keep the source base cross-platform and in good shape
- you can check `.cirrus.yml` file and accompanying scripts/batch-files in `ContinuousIntegration` folder to see how different environments and different build tasks are prepared and executed. If you are not familiar with CI setup and configuration yet, you should take at least a brief glimpse on it, even if you want just to contribute small patch to the sjasmplus, because any pull request will be scrutinized by the CI build system automatically.

My (Ped7g) local workflow is:

1. KDevelop IDE set up to use CMake import of project to build+install debug binary in my `~/.local/bin` folder, which is the first binary found by my search path (to build + install the sjasmplus I use Project/Install Selection [Shift+F8]).
1. with new debug binary locally installed, I run in terminal `ContinuousIntegration/test_folder_tests.sh` to verify if it works (adding new tests exercising the feature/change which I am working at). Sometimes I limit the scope of tests being run by adding argument to the script like "module" to run only `tests/modules/*` tests.
1. when I'm finished with a change, and I'm preparing commit, I use `make clean && make` to verify the release can be built too, and `make DEBUG=1 clean && make DEBUG=1 coverage` to run full test suite, C++ unit tests and create coverage report (text files in build directory) so I can manually check if everything did change as expected.
1. after this review I commit + push the changes to the repository, where the Cirrus CI setup will try to replicate my local experience in different environments of the CI, if some of these fails, I check the Cirrus logs to see why build failed, and work on the fix commit.
1. when working on small/medium change where I'm sure I can get main repository into "green" state whenever I push changes to github, I tend to work directly on `master` branch, but when experimenting with things with unclear outcome, I use experimental branches, later merging them into `master` when they are ready (or even my fork of the main repository, if the experiment is really just experiment, and I am not even sure if it will ever land in the main repository).

Enjoy!
