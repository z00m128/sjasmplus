@call ContinuousIntegration\winbuild_priority_for_git_path.bat
@rem call with first argument being "1" if the ERRORLEVEL should be ignored (set to 0)
bash ContinuousIntegration/test_folder_tests.sh

@if "%~1"=="" goto keepErrorLevel
@if not "%~1"=="1" goto keepErrorLevel
@rem kill exit code of the test script, because it will be surely failing on windows forever
@set ERRORLEVEL=0
@echo "Masa povidala, ze to stejne neni smeroplatne (ERRORLEVEL reset to 0)"
:keepErrorLevel
