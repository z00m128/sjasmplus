SymbOS "nslookup" sources adaptation to sjasmplus syntax and features, for original
visit http://www.symbos.org/

To build use:
sjasmplus Cmd-NsLookUp-sj.asm

The adaptation builds binary-identical nslookup.com file.

The adaption is intentionally trying to modify absolute minimum amount of lines
in original source, all differences are documented in diff patch file:
adaptation.patch

The file names with too much specific file path are renamed (the system includes
use the `<>` notation, these will search in include paths first - if provided
byt `-I` option. The output drops absolute "e:\.." path and writes to current working
directory (adjustable with `--outprefix` option to target particular folder).

And all labels must start at the beginning of line in sjasmplus. Also all instructions
and directives should by default start after some whitespace, which is recommended
way of patching sources when migrating to sjasmplus, but to minimize the impact of
adaptation in this example the option `--dirbol` is used to allow directives at
the beginning of the line.

--------------------------------------------------------------------------------------
2022-06-09 v1.20.0 update

The SymbOS relocates binaries only by patching the MSB (most significant byte, alias
"high" byte). The sjasmplus now supports specific `RELOCATE_START HIGH` mode which
enables programmer to use also expressions like `ld a,high label`, and get the correct
data for relocation of such instruction.

I'm keeping the example source as it was, but to switch to HIGH mode, two lines have
be modified:
line 8: `relocate_start` -> `relocate_start high`
line 119: `relocate_table` -> `relocate_table +1`

To enable high mode, and to produce relocation table pointing ahead of the MSB (that's
how SymbOS expects the data, sjasmplus is producing offsets directly onto MSB).

--------------------------------------------------------------------------------------
The original "#readme.txt" content follows:
--------------------------------------------------------------------------------------

======================================= 
*     ___       ____  _    ___  ___   * 
*    /__  /__/ / / / /_\  /  / /__    * 
*   ___/ ___/ /   / /__/ /__/ ___/    * 
*       SYMBIOSIS MULTITASKING        * 
*       BASED OPERATING SYSTEM        * 
======================================= 
            N S L O O K U P 
         (Domain name lookup) 
--------------------------------------- 
  Author: Prodatron/SymbiosiS 
 Version: 1.0 
    Date: 12.01.2016 
Requires: SymbOS 3.0 
  Memory: 192K (or more) 
--------------------------------------- 
[...] 
--------------------------------------- 
This archive contains the following 
files: 
....................................... 
nslookup.com   Executable 
sources\       Source codes 
NsLookUp-CPC.DSK 
               disk image (CPC or PCW) 
NsLookUp-FAT.DSK 
               disk image (MSX or EP) 
--------------------------------------- 
For additional information please visit 
         http://www.symbos.org 
======================================= 
