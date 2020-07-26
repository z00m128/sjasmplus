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
