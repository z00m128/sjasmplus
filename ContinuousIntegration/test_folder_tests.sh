#!/bin/bash

## script init + helper functions
HELP_STRING="Run the script from \033[96mproject root\033[0m directory."
HELP_STRING+="\nYou can provide one argument to specify particular sub-directory in \033[96mtests\033[0m directory, example:"
HELP_STRING+="\n  $ \033[96mContinuousIntegration/test_folder_tests.sh z80/\033[0m \t\t# to run only tests from \033[96mtests/z80/\033[0m directory"
HELP_STRING+="\nIf partial file name is provided, it'll be searched for (but file names with space break it,\033[1m it's not 100% functional\033[0m):"
HELP_STRING+="\n  $ \033[96mContinuousIntegration/test_folder_tests.sh z8\033[0m \t\t# to run tests from \033[96mtests/z80/\033[0m and \033[96mtests/z80n/\033[0m directories"
PROJECT_DIR=$PWD
BUILD_DIR="$PROJECT_DIR/build/tests"
exitCode=0
totalTests=0        # +1 per ASM
totalChecks=0       # +1 per diff/check

# verify the directory structure is set up as expected and the working directory is project root
[[ ! -f "${PROJECT_DIR}/ContinuousIntegration/test_folder_tests.sh" ]] && echo -e "\033[91munexpected working directory\033[0m\n$HELP_STRING" && exit 1

source ContinuousIntegration/common_fn.sh

[[ -n "$EXE" ]] && echo -e "Using EXE=\033[96m$EXE\033[0m as assembler binary"

## find the most fresh executable
#[[ -z "$EXE" ]] && find_newest_binary sjasmplus "$PROJECT_DIR" \
#    && echo -e "The most fresh binary found: \033[96m$EXE\033[0m"
# reverted back to hard-coded "sjasmplus" for binary, as the date check seems to not work on some windows machines

[[ -z "$EXE" ]] && EXE=sjasmplus

# seek for files to be processed (either provided by user argument, or default tests/ dir)
if [[ $# -gt 0 ]]; then
    [[ "-h" == "$1" || "--help" == "$1" ]] && echo -e $HELP_STRING && exit 0
else
    echo -e "Searching directory \033[96m${PROJECT_DIR}/tests/\033[0m for '.asm' files..."
fi
OLD_IFS=$IFS
IFS=$'\n'
TEST_FILES=($(find "$PROJECT_DIR/tests/$1"* -type f | grep -v -E '\.i\.asm$' | grep -E '\.asm$'))
IFS=$OLD_IFS

# check if some files were found, print help message if search failed
[[ -z $TEST_FILES ]] && echo -e "\033[91mno files found\033[0m\n$HELP_STRING" && exit 1

## create temporary build directory for output
echo -e "Creating temporary \033[96m$BUILD_DIR\033[0m directory..."
rm -rf "$BUILD_DIR"
# terminate in case the create+cd will fail, this is vital
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR" || exit 1

## go through all asm files in tests directory and verify results
for f in "${TEST_FILES[@]}"; do
    ## standalone .asm file was found, try to build it
    rm -rf *        # clear the temporary build directory
    totalTests=$((totalTests + 1))
    # set up various "test-name" variables for file operations
    src_dir=`dirname "$f"`          # source directory (dst_dir is "." = "build/tests")
    file_asm=`basename "$f"`        # just "file.asm" name
    src_base="${f%.asm}"            # source directory + base ("src_dir/file"), to add extensions
    dst_base="${file_asm%.asm}"     # local-directory base (just "file" basically), to add extensions
    CLI_FILE="${dst_base}.cli"      # sub-script test-runner (internal feature, not documented)
    [[ -d "${src_base}.config" ]] && CFG_BASE="${src_base}.config/${dst_base}" || CFG_BASE="${src_base}"
    OPTIONS_FILE="${CFG_BASE}.options"
    LIST_FILE="${CFG_BASE}.lst"
    MSG_LIST_FILE="${CFG_BASE}.msglst"
    # copy "src_dir/basename*.(asm|lua|cli)" file(s) into working directory
    for subf in "$src_base"*.{asm,lua,cli}; do
        [[ ! -e "$subf" || -d "$subf" ]] && continue
        cp "$subf" ".${subf#$src_dir}"
    done
    # copy "src_dir/basename*" sub-directories into working directory (ALL files in them)
    for subf in "$src_base"*; do
        [[ ! -d "$subf" ]] && continue
        [[ "${src_base}.config" == "$subf" ]] && continue   # some.config directory is not copied
        cp -r "$subf" ".${subf#$src_dir}"
    done
    # see if there are extra options defined (and read them into array)
    options=()
    [[ -s "${OPTIONS_FILE}" ]] && options=(`cat "${OPTIONS_FILE}"`)
    # check if .lst file is required to verify the test, set up options to produce one
    [[ -s "${LIST_FILE}" ]] && MSG_LIST_FILE="" && options+=("--lst=${dst_base}.lst") && options+=('--lstlab')
    [[ ! -s "${MSG_LIST_FILE}" ]] && MSG_LIST_FILE="" || LIST_FILE="${MSG_LIST_FILE}"
    ## built it with sjasmplus (remember exit code)
    totalChecks=$((totalChecks + 1))    # assembling is one check
    if [[ -s "${CLI_FILE}" ]]; then
        # custom test-runner detected, run it... WARNING, this acts as part of main script (do not exit(..), etc)
        echo -e "\033[95mRunning\033[0m file \033[96m${CLI_FILE}\033[0m in test \033[96m${src_dir}\033[0m"
        last_result=126         # custom script must override this
        source ${CLI_FILE}
        last_result_origin="custom test script ${CLI_FILE}"
    else
        echo -e "\033[95mAssembling\033[0m file \033[96m${file_asm}\033[0m in test \033[96m${src_dir}\033[0m, options [\033[96m${options[@]}\033[0m]"
        if [[ -z "${MSG_LIST_FILE}" ]]; then
            $MEMCHECK "$EXE" --nologo --msg=none --fullpath "${options[@]}" "$file_asm"
            last_result=$?
        else
            $MEMCHECK "$EXE" --nologo --msg=lstlab --fullpath "${options[@]}" "$file_asm" 2> "${dst_base}.lst"
            last_result=$?
        fi
        last_result_origin="sjasmplus"
    fi
    ## validate results
    # LST file overrides assembling exit code (new exit code is from diff between lst files)
    if [[ -s "${LIST_FILE}" ]]; then
        diff -a --strip-trailing-cr "${LIST_FILE}" "${dst_base}.lst"
        last_result=$?
        last_result_origin="diff"
    fi
    # report assembling exit code problem here (ahead of binary result tests)
    if [[ $last_result -ne 0 ]]; then
        echo -e "\033[91mError status $last_result returned by $last_result_origin\033[0m"
        exitCode=$((exitCode + 1))
    else
        echo -e "\033[92mOK: assembling or listing\033[0m"
    fi
    # check binary results, if TAP, BIN or RAW are present in source directory
    for binext in {'tap','bin','raw'}; do
        if [[ -f "${CFG_BASE}.${binext}" ]]; then
            upExt=`echo $binext | tr '[:lower:]' '[:upper:]'`
            totalChecks=$((totalChecks + 1))        # +1 for each binary check
            echo -n -e "\033[91m"
            ! diff "${CFG_BASE}.${binext}" "${dst_base}.${binext}" \
                && exitCode=$((exitCode + 1)) && echo -e "Error: $upExt differs\033[0m" \
                || echo -e "\033[92mOK: $upExt is identical\033[0m"
        fi
    done
    # check other text results (not LST), if they are present in source directory
    for txtext in {'sym','exp','lbl'}; do
        if [[ -f "${CFG_BASE}.${txtext}" ]]; then
            upExt=`echo $txtext | tr '[:lower:]' '[:upper:]'`
            totalChecks=$((totalChecks + 1))        # +1 for each text check
            echo -n -e "\033[91m"
            ! diff -a --strip-trailing-cr "${CFG_BASE}.${txtext}" "${dst_base}.${txtext}" \
                && exitCode=$((exitCode + 1)) && echo -e "Error: $upExt differs\033[0m" \
                || echo -e "\033[92mOK: $upExt is identical\033[0m"
        fi
    done
    #read -p "press..."      # DEBUG helper to examine produced files
done # end of FOR (go through all asm files)
# display OK message if no error was detected
[[ $exitCode -eq 0 ]] \
    && echo -e "\033[92mFINISHED: OK, $totalChecks checks passed ($totalTests tests) \033[91m■\033[93m■\033[32m■\033[96m■\033[0m" \
    && exit 0
# display error summary and exit with error code
echo -e "\033[91mFINISHED: $exitCode/$totalChecks checks failed ($totalTests tests) \033[91m■\033[93m■\033[32m■\033[96m■\033[0m"
exit $exitCode
