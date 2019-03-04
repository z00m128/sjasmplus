#!/bin/bash

## script init + helper functions
shopt -s globstar nullglob
PROJECT_DIR=$PWD
exitCode=0
totalTests=0        # +1 per ASM
totalChecks=0       # +1 per diff/check

## create temporary build directory for output
echo -e "Creating temporary \e[96mbuild/tests\e[0m directory..."
rm -rf $PROJECT_DIR/build/tests
# terminate in case the create+cd will fail, this is vital
mkdir -p $PROJECT_DIR/build/tests && cd $PROJECT_DIR/build/tests || exit 1
echo -e "Searching directory \e[96m${PROJECT_DIR}/tests/\e[0m for '.asm' files..."

## go through all asm files in tests directory and verify results
for f in "${PROJECT_DIR}/tests/"**/*.asm; do
    ## ignore directories themselves (which have "*.asm" name)
    [[ -d $f ]] && continue
    ## ignore "include" files (must have ".i.asm" extension)
    [[ ".i.asm" == ${f:(-6)} ]] && continue
    ## standalone .asm file was found, try to build it
    rm -rf *        # clear the temporary build directory
    totalTests=$((totalTests + 1))
    # set up various "test-name" variables for file operations
    src_dir=`dirname "$f"`          # source directory (dst_dir is "." = "build/tests")
    file_asm=`basename "$f"`        # just "file.asm" name
    src_base="${f%.asm}"            # source directory + base ("src_dir/file"), to add extensions
    dst_base="${file_asm%.asm}"     # local-directory base (just "file" basically), to add extensions
    # copy "src_dir/basename*.asm" file(s) into working directory
    for subf in "$src_base"*.asm; do
        [[ -d "$subf" ]] && continue
        cp "$subf" ".${subf#$src_dir}"
    done
    # copy "src_dir/basename*" sub-directories into working directory (ALL files in them)
    for subf in "$src_base"*; do
        [[ ! -d "$subf" ]] && continue
        cp -r "$subf" ".${subf#$src_dir}"
    done
    # see if there are extra options defined (and read them into array)
    options=()
    [[ -s "${src_base}.options" ]] && options=(`cat "${src_base}.options"`)
    # check if .lst file is required to verify the test, set up options to produce one
    [[ -s "${src_base}.lst" ]] && options+=("--lst=${dst_base}.lst") && options+=('--lstlab')
    ## built it with sjasmplus (remember exit code)
    echo -e "\e[95mAssembling\e[0m file \e[96m${file_asm}\e[0m in test \e[96m${src_dir}\e[0m, options [\e[96m${options[@]}\e[0m]"
    totalChecks=$((totalChecks + 1))    # assembling is one check
    sjasmplus --fullpath "${options[@]}" "$file_asm"
    last_result=$?
    last_result_origin="sjasmplus"
    ## validate results
    # LST file overrides assembling exit code (new exit code is from diff between lst files)
    if [[ -s "${src_base}.lst" ]]; then
        diff "${src_base}.lst" "${dst_base}.lst"
        last_result=$?
        last_result_origin="diff"
    fi
    # report assembling exit code problem here (ahead of binary result tests)
    if [[ $last_result -ne 0 ]]; then
        echo -e "\e[91mError status $last_result returned by $last_result_origin\e[0m"
        exitCode=$((exitCode + 1))
    else
        echo -e "\e[92mOK: assembling or listing\e[0m"
    fi
    # check binary results, if TAP or BIN are present in source directory
    for binext in {'tap','bin'}; do
        if [[ -f "${src_base}.${binext}" ]]; then
            upExt=`echo $binext | tr '[:lower:]' '[:upper:]'`
            totalChecks=$((totalChecks + 1))        # +1 for each binary check
            echo -n -e "\e[91m"
            ! diff "${src_base}.${binext}" "${dst_base}.${binext}" \
                && exitCode=$((exitCode + 1)) \
                || echo -e "\e[92mOK: $upExt is identical\e[0m"
            echo -n -e "\e[0m"
        fi
    done
done
# display OK message if no error was detected
[[ $exitCode -eq 0 ]] \
    && echo -e "\e[92mFINISHED: OK, $totalChecks checks passed ($totalTests tests) \e[91m■\e[93m■\e[32m■\e[96m■\e[0m" \
    && exit 0
# display error summary and exit with error code
echo -e "\e[91mFINISHED: $exitCode/$totalChecks checks failed ($totalTests tests) \e[91m■\e[93m■\e[32m■\e[96m■\e[0m"
exit $exitCode
