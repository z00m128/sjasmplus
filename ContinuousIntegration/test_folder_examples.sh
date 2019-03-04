#!/bin/bash

## script init + helper functions
shopt -s globstar nullglob
PROJECT_DIR=$PWD
exitCode=0
totalAsmFiles=0        # +1 per ASM
# read list of files to ignore, preserve spaces in file names, ignore comments
ignoreAsmFiles=()
if [[ -s ContinuousIntegration/examples_ignore.txt ]]; then
    OLD_IFS=$IFS
    IFS=$'\n'           # input/internal field separator
    while read line; do
        [[ -z "$line" ]] && continue            # skip empty lines
        [[ "#" == ${line::1} ]] && continue     # skip comments
        [[ '"' == ${line::1} && '"' == ${line:(-1)} ]] && line=${line:1:(-1)}
        ignoreAsmFiles+=("${line}")
    done < ContinuousIntegration/examples_ignore.txt
    IFS=$OLD_IFS
fi

## create temporary build directory for output
rm -rf $PROJECT_DIR/build/examples
mkdir -p $PROJECT_DIR/build/examples && cd $PROJECT_DIR/build/examples
echo -e "Searching directory \e[96m${PROJECT_DIR}/examples/\e[0m for '.asm' files..."

## go through all asm files in examples directory and try to assemble them
for f in "${PROJECT_DIR}/examples/"**/*.asm; do
    ## ignore files in the ignore list
    for ignoreFile in "${ignoreAsmFiles[@]}"; do
        [[ "$ignoreFile" == "${f#${PROJECT_DIR}/examples/}" ]] && f='ignore.i.asm'
    done
    ## ignore "include" files (must have ".i.asm" extension)
    if [[ ".i.asm" == ${f:(-6)} ]]; then
        continue
    fi
    ## standalone .asm file was found, try to build it
    totalAsmFiles=$((totalAsmFiles + 1))
    dirpath=`dirname "$f"`
    asmname=`basename "$f"`
    mainname="${f%.asm}"
    # see if there are extra options defined
    optionsF="${mainname}.options"
    options=()
    [[ -s "$optionsF" ]] && options=(`cat "${optionsF}"`)
    ## built it with sjasmplus (remember exit code)
    echo -e "\e[95mAssembling\e[0m example file \e[96m${asmname}\e[0m in \e[96m${dirpath}\e[0m, options [\e[96m${options[@]}\e[0m]"
    sjasmplus --inc="${dirpath}" "${options[@]}" "$f"
    last_result=$?
    ## report assembling exit code problem
    if [[ $last_result -ne 0 ]]; then
        echo -e "\e[91mError status $last_result\e[0m"
        exitCode=$((exitCode + 1))
    else
        echo -e "\e[92mOK: done\e[0m"
    fi
done
# display OK message if no error was detected
[[ $exitCode -eq 0 ]] \
    && echo -e "\e[92mFINISHED: OK, $totalAsmFiles examples built \e[91m■\e[93m■\e[32m■\e[96m■\e[0m" \
    && exit 0
# display error summary and exit with error code
echo -e "\e[91mFINISHED: $exitCode/$totalAsmFiles examples failed \e[91m■\e[93m■\e[32m■\e[96m■\e[0m"
exit $exitCode
