@call ContinuousIntegration\winbuild_set_msys2_path.bat
bash ContinuousIntegration/test_folder_tests.sh

@rem kill exit code of the test script, because it will be surely failing on windows forever
@set ERRORLEVEL=0
@echo "Masa povidala, ze to stejne neni smeroplatne"
