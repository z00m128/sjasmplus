#!/usr/bin/env bash

## script init + helper functions
HELP_STRING="Run the script from \033[96mproject root\033[0m directory without arguments."
PROJECT_DIR=$PWD
BUILD_DIR="$PROJECT_DIR/build/examples"
exitCode=0
totalAsmFiles=0        # +1 per ASM

source ContinuousIntegration/common_fn.sh

# read list of files to ignore, preserve spaces in file names, ignore comments
ignoreAsmFiles=()
if [[ -s ContinuousIntegration/examples_ignore.txt ]]; then
    OLD_IFS=$IFS
    IFS=$'\n'           # input/internal field separator
    while read line; do
        [[ -z "$line" ]] && continue            # skip empty lines
        [[ "#" == ${line::1} ]] && continue     # skip comments
        lineLen=${#line}
        [[ '"' == ${line::1} && '"' == ${line:${lineLen}-1} ]] && line=${line:1:${lineLen}-2}
        ignoreAsmFiles+=("${line}")
    done < ContinuousIntegration/examples_ignore.txt
    IFS=$OLD_IFS
fi
echo -e "Files to ignore: \033[93m${ignoreAsmFiles[@]}\033[0m"

echo -n -e "Project dir \"\033[96m${PROJECT_DIR}\033[0m\". "

# verify the directory structure is set up as expected and the working directory is project root
[[ ! -f "${PROJECT_DIR}/ContinuousIntegration/test_folder_examples.sh" ]] && \
echo -e "\033[91munexpected working directory\033[0m\n$HELP_STRING" && exit 1
# check for unexpected arguments, bail out
if [[ $# -gt 0 ]]; then
    echo -e $HELP_STRING && exit 0
fi

[[ -n "$EXE" ]] && echo -e "Using EXE=\033[96m$EXE\033[0m as assembler binary"

## find the most fresh executable
#[[ -z "$EXE" ]] && find_newest_binary sjasmplus "$PROJECT_DIR" \
#    && echo -e "The most fresh binary found: \033[96m$EXE\033[0m"
# reverted back to hard-coded "sjasmplus" for binary, as the date check seems to not work on some windows machines

[[ -z "$EXE" ]] && EXE=sjasmplus

# seek for files to be processed
echo -n -e "Searching \033[96mexamples/**\033[0m for '*.asm'. "
OLD_IFS=$IFS
IFS=$'\n'
EXAMPLE_FILES=($(find "$PROJECT_DIR/examples/" -type f | grep -v -E '\.i\.asm$' | grep -E '\.asm$'))
IFS=$OLD_IFS

# check if some files were found, print help message if search failed
[[ -z $EXAMPLE_FILES ]] && echo -e "\033[91mno files found\033[0m\n$HELP_STRING" && exit 1

## create temporary build directory for output
echo -e "Creating temporary: \033[96m$BUILD_DIR\033[0m"
rm -rf "$BUILD_DIR"
# terminate in case the create+cd will fail, this is vital
# also make sure the build dir has all required permissions
mkdir -p "$BUILD_DIR" && chmod 700 "$BUILD_DIR" && cd "$BUILD_DIR" || exit 1

## go through all asm files in examples directory and try to assemble them
for f in "${EXAMPLE_FILES[@]}"; do
    ## ignore files in the ignore list
    for ignoreFile in "${ignoreAsmFiles[@]}"; do
        [[ "$ignoreFile" == "${f#${PROJECT_DIR}/examples/}" ]] && f='IGNORE'
    done
    [[ 'IGNORE' == $f ]] && continue
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
    echo -e "\033[95mAssembling\033[0m \"\033[96m${asmname}\033[0m\" in \"\033[96m${dirpath##$PROJECT_DIR/}\033[0m\", options [\033[96m${options[@]}\033[0m]"
    $MEMCHECK "$EXE" --nologo --msg=war --fullpath --inc="${dirpath}" "${options[@]}" "$f"
    last_result=$?
    ## report assembling exit code problem
    if [[ $last_result -ne 0 ]]; then
        echo -e "\033[91mError status $last_result\033[0m"
        exitCode=$((exitCode + 1))
    else
        echo -e "\033[92mOK: done\033[0m"
    fi
done
# display OK message if no error was detected
[[ $exitCode -eq 0 ]] \
    && echo -e "\033[92mFINISHED: OK, $totalAsmFiles examples built \033[91m\u25A0\033[93m\u25A0\033[32m\u25A0\033[96m\u25A0\033[0m" \
    && exit 0
# display error summary and exit with error code
echo -e "\033[91mFINISHED: $exitCode/$totalAsmFiles examples failed \033[91m\u25A0\033[93m\u25A0\033[32m\u25A0\033[96m\u25A0\033[0m"
exit $exitCode
