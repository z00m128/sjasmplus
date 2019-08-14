path
dir /w
make -f Makefile.win clean
make -f Makefile.win
make -f Makefile.win install
bash ContinuousIntegration/test_folder_examples.sh
bash ContinuousIntegration\test_folder_examples.sh
@rem  del Makefile
@rem  ren Makefile.win Makefile
@rem  dir Makefile
@rem  mkdir build
@rem  cd build
@rem  cmake /?
@rem  cmake --help
@rem  cmake -DCMAKE_BUILD_TYPE=Release ..
@rem  dir /w
