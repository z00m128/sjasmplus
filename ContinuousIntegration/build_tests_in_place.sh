#!/bin/bash

echo -e "\033[91mThis script will try to build all tests 'in place' => may and will overwrite files used to verify test results.\n\033[96m"
read -p "Are you sure? (y/n) " -n 1 -r
echo -e "\033[0m"
[[ ! $REPLY == "y" ]] && exit 0

## script init + helper functions
shopt -s globstar nullglob
PROJECT_DIR=$PWD
exitCode=0
totalTests=0        # +1 per ASM

# verify the directory structure is set up as expected and the working directory is project root
[[ ! -f "${PROJECT_DIR}/ContinuousIntegration/build_tests_in_place.sh" ]] && echo -e "\033[91munexpected working directory\033[0m" && exit 1

source ContinuousIntegration/common_fn.sh

[[ -n "$EXE" ]] && echo -e "Using EXE=\033[96m$EXE\033[0m as assembler binary"

## find the most fresh executable
#[[ -z "$EXE" ]] && find_newest_binary sjasmplus "$PROJECT_DIR" \
#    && echo -e "The most fresh binary found: \033[96m$EXE\033[0m"
# reverted back to hard-coded "sjasmplus" for binary, as the date check seems to not work on some windows machines

[[ -z "$EXE" ]] && EXE=sjasmplus

# seek for files to be processed (either provided by user argument, or default tests/ dir)
if [[ $# -gt 0 ]]; then
    TEST_FILES=("${PROJECT_DIR}/tests/$1"**/*.asm)
else
    echo -e "Searching directory \033[96m${PROJECT_DIR}/tests/\033[0m for '.asm' files..."
    TEST_FILES=("${PROJECT_DIR}/tests/"**/*.asm)  # try default test dir
fi
# check if some files were found, print help message if search failed
[[ -z $TEST_FILES ]] && echo -e "\033[91mno files found\033[0m\n" && exit 1

## go through all asm files in tests directory and build them "in place" (rewriting result files)
for f in "${TEST_FILES[@]}"; do
    ## ignore directories themselves (which have "*.asm" name)
    [[ -d $f ]] && continue
    ## ignore "include" files (must have ".i.asm" extension)
    [[ ".i.asm" == ${f:(-6)} ]] && continue
    ## standalone .asm file was found, try to build it
    totalTests=$((totalTests + 1))
    # set up various "test-name" variables for file operations
    src_dir=`dirname "$f"`          # source directory
    file_asm=`basename "$f"`        # just "file.asm" name
    src_base="${f%.asm}"            # source directory + base ("src_dir/file"), to add extensions
    dst_base="${file_asm%.asm}"     # local-directory base (just "file" basically), to add extensions
    [[ -d "${src_base}.config" ]] && CFG_BASE="${src_base}.config/${dst_base}" || CFG_BASE="${src_base}"
    OPTIONS_FILE="${CFG_BASE}.options"
    LIST_FILE="${CFG_BASE}.lst"
    # see if there are extra options defined (and read them into array)
    options=()
    [[ -s "${OPTIONS_FILE}" ]] && options=(`cat "${OPTIONS_FILE}"`)
    # check if .lst file already exists, set up options to refresh it + delete it
    [[ -s "${LIST_FILE}" ]] && options+=("--lst=${LIST_FILE}") && options+=('--lstlab') && rm "${LIST_FILE}"
    ## built it with sjasmplus (remember exit code)
    echo -e "\033[95mAssembling\033[0m file \033[96m${file_asm}\033[0m in test \033[96m${src_dir}\033[0m, options [\033[96m${options[@]}\033[0m]"
    # switch to test directory and run assembler
    pushd "${src_dir}"
    "$EXE" --nologo --msg=none --fullpath "${options[@]}" "$file_asm"
    last_result=$?
    popd
    # non-empty LST file overrides assembling exit code => OK
    [[ -s "${LIST_FILE}" ]] && last_result=0
    # report assembling exit code problem here
    if [[ $last_result -ne 0 ]]; then
        echo -e "\033[91mError status $last_result returned by $EXE\033[0m"
        exitCode=$((exitCode + 1))
    else
        echo -e "\033[92mOK: assembling (+listing)\033[0m"
    fi
    #read -p "press..."      # DEBUG helper
done # end of FOR (go through all asm files)
# display OK message if no error was detected
[[ $exitCode -eq 0 ]] \
    && echo -e "\033[92mFINISHED: OK, $totalTests tests built \033[91m■\033[93m■\033[32m■\033[96m■\033[0m" \
    && exit 0
# display error summary and exit with error code
echo -e "\033[91mFINISHED: $exitCode/$totalTests tests failed to build \033[91m■\033[93m■\033[32m■\033[96m■\033[0m"
exit $exitCode
