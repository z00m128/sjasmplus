#!/usr/bin/env bash

# "remote curl build" bash script to build latest stable release v1.14.2
# Designed for the ZX Spectrum Next community, for the Raspberry Pi Zero
# "accelerator" distro maintainer.

# do NOT run on local box unless you understand what this script is doing and how it
# will affect your local linux box (by installing those extra packages and sjasmplus).

# It will download + build + install latest stable sjasmplus release (from github)
# Will install packages: GNU make, GCC-6 and G++-6
# After successful build it will install sjasmplus into: PREFIX=/usr
# After successful install the test-runner bash scripts are launched, storing output
# into log files. These are valuable for sjasmplus maintainers (in case of some bugs).

# expected usage (something like this):
#  mkdir -p /tmp/sjasmplus
#  cd /tmp/sjasmplus
#  curl https://raw.githubusercontent.com/z00m128/sjasmplus/master/ContinuousIntegration/remote_curl_build.sh | sh -

# expected output:
#  /usr/bin/sjasmplus
#  /tmp/sjasmplus/path_to_binary.log
#  /tmp/sjasmplus/tests.log
#  /tmp/sjasmplus/examples.log

# download+extract the source tar.gz with curl:
echo "# Downloading + extracing sjasmplus sources (stable release v1.14.2) from github..."
curl -O -L https://github.com/z00m128/sjasmplus/archive/v1.14.2.tar.gz && \
tar xf v*.tar.gz && \
cd sjasmplus*
SRC_RESULT=$?
if [ $SRC_RESULT -ne 0 ]; then
    echo "# Downloading + extracting failed:" $SRC_RESULT
    exit $SRC_RESULT
fi

# try to install tools required to build sjasmplus binary
# (first version of script, so far using integrated copy of LUA inside the sources)
echo "# Installing required packages for build: make gcc-6 g++-6 (+ their deps)"
sudo apt -y install make gcc-6 g++-6
APT_RESULT=$?
if [ $APT_RESULT -ne 0 ]; then
    echo "# Installing packages failed:" $APT_RESULT
    exit $APT_RESULT
fi

# try to build and install the binary
echo "# Running make to build + install the binary"
make CC=gcc-6 CXX=g++-6 && \
sudo make PREFIX=/usr CC=gcc-6 CXX=g++-6 install && \
make clean
BUILD_RESULT=$?
if [ $BUILD_RESULT -ne 0 ]; then
    echo "# Build+install failed:" $BUILD_RESULT
    exit $BUILD_RESULT
else
    echo "# 'which sjasmplus' = " `which sjasmplus`
    which sjasmplus > ../path_to_binary.log
fi

# try to run, collect all output to "../tests.log" and "../examples.log"
echo "# Running the tests... output is in (tests|examples).log files"
NOCOLOR=1 bash ContinuousIntegration/test_folder_tests.sh > ../tests.log 2>&1
NOCOLOR=1 bash ContinuousIntegration/test_folder_examples.sh > ../examples.log 2>&1

# display summary of tests run...
if [ -s ../tests.log ]; then
    head -n 3 ../tests.log
    echo " ..."
    tail -n 2 ../tests.log
else
    echo "# ERROR: ../tests.log seems missing or empty"
fi
if [ -s ../examples.log ]; then
    head -n 3 ../examples.log
    echo " ..."
    tail -n 2 ../examples.log
else
    echo "# ERROR: ../examples.log seems missing or empty"
fi

# final cleanup
cd ..
#TODO ... really?# rm -rf sjasmplus*
#TODO ... really?# rm *.tar.gz
ls -la
