#!/usr/bin/env bash

## script init + helper functions
HELP_STRING="Run the script from \033[96mproject root\033[0m directory."
HELP_STRING+="\nYou can provide one argument to specify particular sub-directory in \033[96mtests\033[0m directory, example:"
HELP_STRING+="\n  $ \033[96mContinuousIntegration/test_folder_tests.sh z80/\033[0m \t\t# to run only tests from \033[96mtests/z80/\033[0m directory"
HELP_STRING+="\nIf partial file name is provided, it'll be searched for (but file names with space break it,\033[1m it's not 100% functional\033[0m):"
HELP_STRING+="\n  $ \033[96mContinuousIntegration/test_folder_tests.sh z8\033[0m \t\t# to run tests from \033[96mtests/z80/\033[0m and \033[96mtests/z80n/\033[0m directories"
PROJECT_DIR=$PWD
TEST_RUNNER="${PROJECT_DIR}/ContinuousIntegration/test_folder_tests.sh"
BUILD_DIR="$PROJECT_DIR/build/tests"
exitCode=0
totalTests=0        # +1 per ASM
totalChecks=0       # +1 per diff/check

source ContinuousIntegration/common_fn.sh

echo -n -e "Project dir \"\033[96m${PROJECT_DIR}\033[0m\". "

# verify the directory structure is set up as expected and the working directory is project root
[[ ! -f "${TEST_RUNNER}" ]] && echo -e "\033[91munexpected working directory\033[0m\n$HELP_STRING" && exit 1

# `cmp` on macOS require minus switch to indicate that stdin is going to be processed
CMP_IN="" && [[ $(uname) == 'Darwin' ]] && CMP_IN=" -"
# check if `gcmp` or `cmp` accepts stdin input for second file to compare
CMP="gcmp" && cat "${TEST_RUNNER}" | $CMP $CMP_IN "${TEST_RUNNER}" 2> /dev/null || \
CMP="cmp" && cat "${TEST_RUNNER}" | $CMP $CMP_IN "${TEST_RUNNER}" 2> /dev/null || CMP=""
[[ -z $CMP ]] && echo -e "\n\033[91mNo \"cmp\" found which accepts stdin\033[0m (gcmp and cmp tried).\n" && exit 1
echo -n -e "Using \033[96m${CMP}${CMP_IN}\033[0m. "

[[ -n "$EXE" ]] && echo -e "Using EXE=\033[96m$EXE\033[0m as assembler binary"

## find the most fresh executable
#[[ -z "$EXE" ]] && find_newest_binary sjasmplus "$PROJECT_DIR" \
#    && echo -e "The most fresh binary found: \033[96m$EXE\033[0m"
# reverted back to hard-coded "sjasmplus" for binary, as the date check seems to not work on some windows machines

[[ -z "$EXE" ]] && EXE=sjasmplus

# seek for files to be processed (either provided by user argument, or default tests/ dir)
if [[ $# -gt 0 ]]; then
    [[ "-h" == "$1" || "--help" == "$1" ]] && echo -e $HELP_STRING && exit 0
fi
echo -n -e "Searching \033[96mtests/$1**\033[0m for '*.asm'. "
OLD_IFS=$IFS
IFS=$'\n'
TEST_FILES=($(find "$PROJECT_DIR/tests/$1"* -type f | grep -v -E '\.i\.asm$' | grep -E '\.asm$'))
IFS=$OLD_IFS

# check if some files were found, print help message if search failed
[[ -z $TEST_FILES ]] && echo -e "\033[91mno files found\033[0m\n$HELP_STRING" && exit 1

## create temporary build directory for output
echo -e "Creating temporary: \033[96m$BUILD_DIR\033[0m"
rm -rf "$BUILD_DIR"
# terminate in case the create+cd will fail, this is vital
# also make sure the build dir has all required permissions
mkdir -p "$BUILD_DIR" && chmod 700 "$BUILD_DIR" && cd "$BUILD_DIR" || exit 1

## go through all asm files in tests directory and verify results
for f in "${TEST_FILES[@]}"; do
    ## standalone .asm file was found, try to build it
    rm -rf ./*      # clear the temporary build directory
    totalTests=$((totalTests + 1))
    # set up various "test-name" variables for file operations
    src_dir=$(dirname "$f")         # source directory (dst_dir is "." = "build/tests")
    file_asm=$(basename "$f")       # just "file.asm" name
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
        chmod 700 ".${subf#$src_dir}"   # force 700 permissions to copied file
    done
    # copy "src_dir/basename*" sub-directories into working directory (ALL files in them)
    for subf in "$src_base"*; do
        [[ ! -d "$subf" ]] && continue
        [[ "${src_base}.config" == "$subf" ]] && continue   # some.config directory is not copied
        cp -r "$subf" ".${subf#$src_dir}"
        chmod -R 700 ".${subf#$src_dir}"   # force 700 permissions to copied files (recursively)
    done
    # see if there are extra options defined (and read them into array)
    options=('--lstlab=sort')	# enforce all symbol dumps to be sorted in any case (even when no --lst)
    options+=('-Wno-behost')	# don't report BE host platform (these kind of tests should pass on any platform)
    options+=('--color=off')	# don't colorize warnings/errors by default
    [[ -s "${OPTIONS_FILE}" ]] && options+=($(cat "${OPTIONS_FILE}"))
    # check if .lst file is required to verify the test, set up options to produce one
    [[ -s "${LIST_FILE}" ]] && MSG_LIST_FILE="" && options+=("--lst=${dst_base}.lst")
    [[ ! -s "${MSG_LIST_FILE}" ]] && MSG_LIST_FILE="" || LIST_FILE="${MSG_LIST_FILE}"
    ## built it with sjasmplus (remember exit code)
    totalChecks=$((totalChecks + 1))    # assembling is one check
    ok_tick_text="???"
    if [[ -s "${CLI_FILE}" ]]; then
        # custom test-runner detected, run it... WARNING, this acts as part of main script (do not exit(..), etc)
        echo -e "\033[95mRunning\033[0m \"\033[96m${CLI_FILE}\033[0m\" in \"\033[96m${src_dir##$PROJECT_DIR/}\033[0m\""
        last_result=126         # custom script must override this
        source "${CLI_FILE}"
        last_result_origin="custom test script '${CLI_FILE}'"
        ok_tick_text="run"
    else
        echo -e "\033[95mAssembling\033[0m \"\033[96m${file_asm}\033[0m\" in \"\033[96m${src_dir##$PROJECT_DIR/}\033[0m\", options [\033[96m${options[*]}\033[0m]"
        if [[ -z "${MSG_LIST_FILE}" ]]; then
            $MEMCHECK "$EXE" --nologo --msg=none --fullpath "${options[@]}" "$file_asm"
            last_result=$?
            [[ -s "${LIST_FILE}" ]] && ok_tick_text="lst" || ok_tick_text="asm"
        else
            $MEMCHECK "$EXE" --nologo --msg=lstlab --fullpath "${options[@]}" "$file_asm" 2> "${dst_base}.lst"
            last_result=$?
            ok_tick_text="msg"
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
        echo -n -e "\033[91mError status $last_result returned by $last_result_origin\033[0m\n "
        exitCode=$((exitCode + 1))
    else
        echo -n -e "  \\  \033[92m$ok_tick_text OK\033[0m "
    fi
    # check binary results, if TAP, CDT, BIN, RAW or TRD are present in source directory
    for binext in {'tap','cdt','bin','raw','trd'}; do
        if [[ -f "${CFG_BASE}.${binext}" ]]; then
            totalChecks=$((totalChecks + 1))        # +1 for each binary check
            ! $CMP "${CFG_BASE}.${binext}" "${dst_base}.${binext}" \
                && exitCode=$((exitCode + 1)) && echo -n -e "\033[91mError: $binext DIFFERS\033[0m " \
                || echo -n -e "\033[0m \\  \033[92m$binext OK\033[0m "
        fi
        # or see if compressed ".gz" binary was provided and compare that
        if [[ -f "${CFG_BASE}.${binext}.gz" ]]; then
            totalChecks=$((totalChecks + 1))        # +1 for each binary check
            ! gunzip -c "${CFG_BASE}.${binext}.gz" | $CMP $CMP_IN "${dst_base}.${binext}" \
                && exitCode=$((exitCode + 1)) && echo -n -e "\033[91mError: $binext DIFFERS\033[0m " \
                || echo -n -e "\033[0m \\  \033[92m$binext OK\033[0m "
        fi
    done
    # check other text results (not LST), if they are present in source directory
    for txtext in {'sym','exp','lbl'}; do
        if [[ -f "${CFG_BASE}.${txtext}" ]]; then
            totalChecks=$((totalChecks + 1))        # +1 for each text check
            ! diff -a --strip-trailing-cr "${CFG_BASE}.${txtext}" "${dst_base}.${txtext}" \
                && exitCode=$((exitCode + 1)) && echo -n -e "\033[91mError: $txtext DIFFERS\033[0m " \
                || echo -n -e "\033[0m \\  \033[92m$txtext OK\033[0m "
        fi
    done
    echo ""     # add new line after each test
    #read -p "press..."      # DEBUG helper to examine produced files
done # end of FOR (go through all asm files)
# display OK message if no error was detected ("\u25A0" is UTF big fat filled rectangle/square)
[[ $exitCode -eq 0 ]] \
    && echo -e "\033[92mFINISHED: OK, $totalChecks checks passed ($totalTests tests) \033[91m\u25A0\033[93m\u25A0\033[32m\u25A0\033[96m\u25A0\033[0m" \
    && exit 0
# display error summary and exit with error code
echo -e "\033[91mFINISHED: $exitCode/$totalChecks checks failed ($totalTests tests) \033[91m\u25A0\033[93m\u25A0\033[32m\u25A0\033[96m\u25A0\033[0m"
exit $exitCode
