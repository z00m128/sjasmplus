#!/bin/bash

## script init + helper functions
shopt -s globstar nullglob
PROJECT_DIR=$PWD
exitCode=0
totalTests=0        # +1 per ASM
totalChecks=0       # +1 per diff/check

## create temporary build directory for output
rm -rf $PROJECT_DIR/build/tests
mkdir -p $PROJECT_DIR/build/tests && cd $PROJECT_DIR/build/tests
echo -e "Searching directory \e[96m${PROJECT_DIR}/tests/\e[0m for '.asm' files..."

## go through all asm files in tests directory and verify results
for f in "${PROJECT_DIR}/tests/"**/*.asm; do
    ## ignore "include" files (must have ".i.asm" extension)
    if [[ ".i.asm" == ${f:(-6)} ]]; then
        continue
    fi
    ## standalone .asm file was found, try to build it
    totalTests=$((totalTests + 1))
    dirpath=`dirname "$f"`
    asmname=`basename "$f"`
    mainname="${f%.asm}"
    # see if there are extra options defined
    optionsF="${mainname}.options"
    options=()
    [[ -s "$optionsF" ]] && options=(`cat "${optionsF}"`)
    # check if .lst file is required to verify the test, set up options to produce one
    lstSrcF="${mainname}.lst"
    lstDstF="${asmname%.asm}.lst"
    [[ -s "$lstSrcF" ]] && options+=("--lst=$lstDstF") && options+=('--lstlab')
    ## built it with sjasmplus (remember exit code)
    echo -e "\e[95mAssembling\e[0m file \e[96m${asmname}\e[0m in test \e[96m${dirpath}\e[0m, options [\e[96m${options[@]}\e[0m]"
    totalChecks=$((totalChecks + 1))    # assembling is one check
    sjasmplus --inc="${dirpath}" "${options[@]}" "$f"
    last_result=$?
    last_result_origin="sjasmplus"
    ## validate results
    # LST file overrides assembling exit code (new exit code is from diff between lst)
    if [[ -s $lstSrcF ]]; then
        # fix full-path errors in freshly produced lst to fake "local" path errors
        # and do DIFF over the result, setting new "exit code" for the test
        sed "s~^${f}~${asmname}~g" "$lstDstF" | diff "$lstSrcF" -
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
        if [[ -f "${mainname}.${binext}" ]]; then
            upExt=`echo $binext | tr '[:lower:]' '[:upper:]'`
            totalChecks=$((totalChecks + 1))        # +1 for each binary check
            echo -n -e "\e[91m"
            ! diff "${mainname}.${binext}" "${asmname%.asm}.${binext}" \
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
echo -e "\e[91mFINISHED: $exitCode/$totalChecks checks failed ($totalTests tests)\e[0m"
exit $exitCode
