#!/bin/bash

# $1 = EXE_NAME, $2 = PROJECT_DIR, result is set into global $EXE
function find_newest_binary() {
    # find the most fresh executable
    for P1EXT in "$1"{,".exe"}; do
        command -v "$P1EXT" >/dev/null 2>&1 && EXE="$P1EXT" # system installed executable
        local EXE_MAKE="$2/$P1EXT"
        [[ -f "$EXE_MAKE" && "$EXE_MAKE" -nt "$EXE" ]] && EXE=$EXE_MAKE
        local EXE_CMAKE="$2/build/$P1EXT"
        [[ -f "$EXE_CMAKE" && "$EXE_CMAKE" -nt "$EXE" ]] && EXE=$EXE_CMAKE
    done
}

# "decolorize" output if NOCOLOR is set to anything non-empty
[[ -n "$NOCOLOR" ]] && function echo() {
    command echo "$@" | sed -e 's/\x1b\[[0-9]\+m//g'
}

function pushd () {
    command pushd "$@" > /dev/null
}

function popd () {
    command popd "$@" > /dev/null
}
