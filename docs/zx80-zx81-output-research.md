# ZX80 `.o` and ZX81 `.p` output

Research and proposal for [sjasmplus #239](https://github.com/z00m128/sjasmplus/issues/239).

## Recommendation

Start with working examples on `DEVICE NOSLOT64K`. A macro that only derives
the `SAVEBIN` range from `E_LINE` is a small validation convenience, not a way
to avoid preparing the image. For that, prototype a conventional image builder
that takes a tokenized BASIC program and supplies the ROM bookkeeping. Keep
`SAVEBIN`, `OUTPUT`, and `--raw` for custom layouts. These are niche targets even
among retro Z80 platforms; one higher-level workflow is enough.

## File formats

These are Sinclair program images, not host object files or CPU snapshots.
File offset zero maps to a fixed address. The image is one contiguous RAM range
ending immediately before `E_LINE`; the early bytes contain system variables,
not a separate container header. Read `E_LINE` as a little-endian 16-bit
address, not as a byte count. The exact file length is `E_LINE - load base`.

| Target ROM | Output | Load base | `E_LINE` in RAM (file offset) | Ordinary saved contents |
| --- | --- | --- | --- | --- |
| ZX80 4 KiB integer BASIC | `.o` / `.80` | `$4000` | `$400A` (`$0A`) | Entire system area, BASIC from `$4028`, then variables. Display file and edit line are not saved. |
| ZX81 8 KiB BASIC | `.p` / `.81` | `$4009` | `$4014` (`$0B`) | System area from `VERSN`, BASIC from `$407D`, display file, then variables. The first nine system-variable bytes and the edit line are not saved. |

The ROM determines the layout, not just the machine badge: a ZX80 with the
ZX81 ROM upgrade uses the ZX81 program format. Canonical output contains no
magic, checksum, tape pulses, or trailing padding. Some historical `.o` and `.p`
files have extra bytes after the declared end; that is a reader compatibility
issue, not something a writer should reproduce. For example, the
[ZEsarUX save routines](https://github.com/chernandezba/zesarux/blob/main/src/snap/snap_zx8081.c)
use `E_LINE - load base + 1` for both formats. The ZX80 has no on-tape program
name; on the ZX81 the name is present on real tape but absent from `.p`/`.81`.
The name-prefixed `.p81` variant and TZX/audio output are out of scope.

An ordinary variables area ends in `$80` at `E_LINE - 1`. For ZX81, `D_FILE`
(`$400C`) and `VARS` (`$4010`) depend on layout; a normal collapsed blank
display file takes 25 `$76` bytes, versus 793 bytes fully expanded. `VERSN`
is normally zero for Sinclair ZX81 ROMs. `NXTLIN` (`$4029`) selects the next
**BASIC line address**, not a CPU entry point; a loader can use it to start a
BASIC line that calls machine code via `USR`. A stopped image can point it at
the display-file marker. `CDFLAG` (`$403B`) also carries the requested FAST/SLOW
state. The usual ZX80 workflow is to load, then `RUN` or invoke the program
manually; ROM-specific autostart tricks are not a feature to generate here.
Its `VARS` is at `$4008`, and display/edit pointers still matter to the ROM even
though those areas are not written to the file.

Do not treat the ordinary layout as a universal validator. For example, the
[z88dk appmake writer](https://github.com/z88dk/z88dk/blob/master/src/appmake/zx81.c)
builds toolchain-specific loaders, including a separate ZX80 branch. The
[no$zx notes](https://problemkaputt.de/zxdocs.htm) also describe nonstandard
ZX80 layouts with bytes after the variable terminator but before `E_LINE`.
Check the image boundary in the saver; check the rest in the examples that
choose a particular layout.

## Device Or Stream?

- **Device save (recommended):** Assemble the system area and program at their
  actual addresses, then export the currently mapped bytes in one call. This
  handles address gaps and later `ORG` patches, and can leave unrelated output
  out of the image. Unwritten addresses are whatever is in virtual RAM, so
  initialize deliberate gaps explicitly.
- **Existing sequential output:** `ORG` establishes addresses but does not
  insert file padding or seek in the output. If source emits exactly the image
  in order, even a forward reference in `DW imageEnd` can supply `E_LINE` by
  the final pass. Nothing needs backpatching. This already works with `OUTPUT`
  or `--raw`, without a new format-aware stream API.
- **New stream directives (not recommended):** A begin/end pair could count
  bytes, but a generated `E_LINE` must be available near the start. Without a
  supplied forward label it requires buffering or seeking back (possible with
  `FPOS` on a file, not on a non-seekable sink). It also needs rules for gaps,
  output switches and unfinished blocks. That duplicates the device workflow
  for little gain.

`NOSLOT64K` provides a single mapped 64 KiB window without imposing Spectrum
initialization. Leave page 0 mapped in examples; the file records no page or
bank numbers. It is not a hardware model: it does not enforce RAM capacity,
ROM boundaries, or video fetch mirroring. Stock 1 KiB RAM runs from `$4000` to
`$43FF`; a conventional 16 KiB pack reaches `$7FFF`. Leave room for ROM-created
workspace, display (on ZX80) and stack, rather than filling either range.
Put those limits in example assertions, not in the file writer: programs may
target expanded or otherwise nonstandard setups. A dedicated device only makes
sense if users need a repeatable memory-map or capacity check beyond what source
assertions provide; a device would not emulate the ROM or make loaders portable.
[#232](https://github.com/z00m128/sjasmplus/issues/232) and the attachment to
#239 establish that `NOSLOT64K` works for this use, not how common it is.

## Syntax And Ownership

Today, with `imageEnd` placed immediately after the final saved byte and used
to initialize `E_LINE`, the save calls are:

```asm
    SAVEBIN "demo.o", $4000, imageEnd - $4000
    SAVEBIN "demo.p", $4009, imageEnd - $4009
```

These are alternatives, each after assembly of the matching image. Optional
range-checking macro calls, not current built-ins:

```asm
    ZX80_SAVE "demo.o"
    ZX81_SAVE "demo.p"
```

The macro name selects the layout; the filename is just an output path. Read
`E_LINE` from virtual RAM at the call site, so there is no second length or end
argument to disagree with it. Require device mode; document `NOSLOT64K` as the
recommended device, with no format dependency on its name. Place the call
after the image and any patches, before switching device or mapping. Neither
macro changes RAM, consumes an `END` entry point, or adds an autostart stub.

### `hello_world.asm` With Today's Assembler

This ZX81 example assembles `10 PRINT "HELLO WORLD"` and points `NXTLIN` at
line 10 so the ROM can continue there on load. It uses BASIC rather than a
machine-code loader to make the file layout visible without a `REM`/`USR`
wrapper. Assemble it with `sjasmplus hello_world.asm`. The ROM defaults are
based on the #239 example; the program and addresses below are derived anew.

```asm
   DEVICE NOSLOT64K
   ORG $4009                  ; First saved byte; $4000..$4008 stay out

imageStart:
   DB 0                       ; VERSN: Sinclair ZX81
   DW 10                      ; E_PPC: selected BASIC line number
   DW displayFile             ; D_FILE
   DW displayFile+1           ; DF_CC: first printable position
   DW variables               ; VARS
   DW 0                       ; DEST
   DW imageEnd                ; E_LINE: first byte not saved
   DW imageEnd+4              ; CH_ADD: conventional saved editor state
   DW 0                       ; X_PTR
   DW imageEnd+5,imageEnd+5   ; STKBOT, STKEND: empty calculator stack
   DB 0                       ; BERG
   DW calculatorMemory        ; MEM
   DB 0,2                     ; Unused, DF_SZ
   DW 10,$FDBF                ; S_TOP, LAST_K
   DB 15,55                   ; DEBOUN, MARGIN (50 Hz template)
   DW line10                  ; NXTLIN: use displayFile for no autostart
   DW 0                       ; OLDPPC
   DB 0                       ; FLAGX
   DW 0,$0C8D,0,$F5A3,0       ; STRLEN, T_ADDR, SEED, FRAMES, COORDS
   DB $BC                     ; PR_CC
   DW $1821                   ; S_POSN
   DB $40                     ; CDFLAG: request SLOW mode
   DS 32,0                    ; PRBUFF: spaces
   DB $76                     ; Printer-buffer newline
calculatorMemory:
   DS 30,0                    ; MEMBOT
   DW 0                       ; Remaining unused system bytes

basicStart:
   ASSERT basicStart == $407D
line10:
   DB 0,10                    ; BASIC line number, big-endian
   DW line10End-line10Text    ; Line length, little-endian, includes newline
line10Text:
   DB $F5,$0B                 ; PRINT token, opening quote
   DB $2D,$2A,$31,$31,$34,0   ; "HELLO " in the ZX81 character set
   DB $3C,$34,$37,$31,$29     ; "WORLD"
   DB $0B,$76                 ; Closing quote, BASIC newline
line10End:
basicEnd:

displayFile:
   DS 25,$76                  ; Leading marker and 24 empty rows
variables:
   DB $80                     ; Empty BASIC variables area
imageEnd:
   SAVEBIN "hello_world.p", imageStart, imageEnd-imageStart
```

`SAVEBIN` does not know that the 161 bytes it writes form a ZX81 image. The
source sets `E_LINE` to `$40AA`, after the `$80` at `$40A9`, and keeps all the
other pointers consistent. `ZX81_SAVE "hello_world.p"` would only infer and
check that range; every line above the save call would still be needed.

### Can BasicLib Be Reused?

[BasicLib](../examples/BasicLib/BasicLib.asm) is a Spectrum byte-emission
helper, not a tokenizer for arbitrary BASIC text. The ZX81 ancestry shows up
in the line framing and some token values, but a subset of Spectrum commands
is not enough to make its output compatible:

| Piece | Spectrum BasicLib | ZX81 | ZX80 (4 KiB ROM) |
| --- | --- | --- | --- |
| Line header | `LINE` emits a big-endian line number and a little-endian length | Same; length includes the terminator | Big-endian line number, no length word |
| Line ending | `LEND` emits `$0D` and computes the length | `$76`; same length calculation | `$76`; no length calculation |
| Tokens and strings | `PRINT = $F5`, `USR = $C0`; ASCII strings | `PRINT = $F5`, `USR = $D4`; machine character codes, e.g. quote `$0B`, space `$00` | Different token table (`PRINT = $F4`); `USR` is spelled out, and punctuation differs even from ZX81 |
| Numbers | `DEC` emits ASCII digits; `NUM` adds `$0E` and a Spectrum short integer, or uses `VAL` | ZX81 digits, `$7E`, and a five-byte floating-point encoding for nonzero literals; do not copy the Spectrum short integer form | ZX80 digits as text for integer literals, no hidden numeric payload |

The reusable part is the `LINE`/`LEND` pattern for ZX81: emit a forward
length, then derive it from labels. `DEC`'s Lua conversion to decimal text
could also be adapted to emit machine digits. Neither macro can be used as-is
to emit the whole record, and BasicLib does not build the surrounding image.

For this example, a small specialized macro saves spelling out the line
header, length, and character bytes at each call site. It is an adaptation of
the idea, not an `INCLUDE` of Spectrum BasicLib. Define it before `basicStart`,
then replace the BASIC block (from `basicStart` through `basicEnd`) as shown.
Keep the system area, display, variables, and `SAVEBIN` unchanged.

```asm
   MACRO ZX81_PRINT_TWO_WORDS lineNumber, firstWord, secondWord
      DB HIGH lineNumber, LOW lineNumber
      DW .lineEnd-.lineText
.lineText:
      DB $F5,$0B
      ABYTE -$1B firstWord
      DB $00
      ABYTE -$1B secondWord
      DB $0B,$76
.lineEnd:
   ENDM

basicStart:
   ASSERT basicStart == $407D
line10:
   ZX81_PRINT_TWO_WORDS 10, "HELLO", "WORLD"
basicEnd:
```

The offset maps ASCII `A`..`Z` only; the space is emitted separately as `$00`.
It does not translate digits, lowercase, or punctuation. For one line the
helper is longer than the explicit block. It pays off across repeated lines;
a general source helper would pair per-ROM token and character tables with
line and numeric emitters. For ZX80, omit the length word and use its own
tables. Keep this convenience separate from the proposed image writer.

### What A Built-In Could Own

One useful contract is to package an already-tokenized BASIC program. With
proposed syntax, the same source would keep `DEVICE NOSLOT64K`, set
`ORG $407D`, keep only the BASIC block above, and finish with:

```asm
   SAVEZX81 "hello_world.p", basicStart, basicEnd, line10
```

`basicEnd` is exclusive. The optional fourth argument is an address of a BASIC
line header within the block, not a line number or machine-code entry point;
omit it to load stopped. The writer would generate the saved system area,
derive `D_FILE`, `DF_CC`, `VARS`, `E_LINE` and `NXTLIN`, and append a collapsed
blank display and `$80`. It would use a tested ROM profile for the other
fields and build the result in an output buffer without modifying device RAM.
Source still owns BASIC tokenization, the character encoding and any machine
code it embeds. A `REM` carrier and `RAND USR` line can be provided by a source
helper; automatically wrapping an arbitrary machine-code block is a different
feature, with choices about entry address, placement, and token collisions.

`SAVEZX80 "hello_world.o", basicStart, basicEnd` could use the same contract
at `$4028`, with the ZX80 system area and empty variables but no saved display
or autostart argument. Verify ZX80's generated display/edit pointers against a
ROM save before choosing defaults. For both machines, custom screen data,
variables, or unconventional layouts still belong in an explicit `SAVEBIN`
image. Do not silently overwrite source-supplied system variables.

## Implementation And Verification

1. Establish fixtures before adding syntax. The [#239 Hello World archive](https://github.com/user-attachments/files/16922645/helloworldzx81.zip)
   contains a sjasmplus source using `NOSLOT64K` and a `.p` reported working in
   ZEsarUX. Its 217-byte image starts at `$4009`, with `D_FILE = $40BC`,
   `VARS = $40E1`, `E_LINE = $40E2`, `NXTLIN = $40AA`, and a final `$80`.
   The [zasm ZX80 golden file](https://github.com/Megatokio/zasm/blob/master/Test/ZXSP/original/template_o.o)
   is an empty-program image: 41 bytes from `$4000`, with `VARS = $4028`,
   `E_LINE = $4029`, and a final `$80`. Both fixtures match the exclusive-end
   rule. Still obtain a nonempty ZX80 image saved by a 4 KiB ROM for a behavioral
   comparison. Use the external examples as references and create small
   original test sources rather than importing them wholesale.
2. Prototype an include with the two save macros. On the final pass (`IF
   __PASS__ == 3`), read the little-endian word using `{address}`. Reject an
   end below `$4029` for ZX80 or `$407E` for ZX81 (system area plus at least one
   byte); use the full unsigned 16-bit address, without modulo arithmetic or
   interpreting zero as `$10000`. Put validation and `SAVEBIN` in separate
   branches so an assertion failure cannot also write a file. In particular,
   never pass a zero or negative length: `SAVEBIN` gives those values an
   end-of-RAM meaning. Manage the program's layout with labels as usual on all
   passes; only the inspection and save are final-pass operations. Do not
   require a final `$80` in the generic macro; assert it in conventional examples.
3. Add focused assembler regressions (e.g. `make test TEST=zx80_zx81`): compare
   both files byte-for-byte, check base and exclusive end via their expected
   bytes, and cover a late `ORG` patch, a missing device, and a zero or short
   `E_LINE` with no output. Confirm that repeated saves see memory as it stands
   at each call and that no bytes past the declared end leak into the file.
   Separately test `LOAD`/`RUN` or autostart on the intended ROMs in an emulator
   at the stated RAM size. Prefer at least one ROM-driven load check (convert
   to tape externally if necessary): quickload may bypass ROM behavior and
   tolerate an image that would fail on hardware.
4. Prototype the BASIC packaging contract as a source helper first and ask
   ZX80/ZX81 users whether it removes the boilerplate they actually maintain.
   For a native version, follow [the `SAVEBIN` handler](../sjasm/directives.cpp#L930)
   for filename handling, diagnostics, and final-pass I/O. Require the fixed
   BASIC origin, validate the exclusive end and generated addresses before
   opening the file, and check that any autostart pointer names a line header,
   not an address inside its body. Compare the packaged file to its explicit
   `SAVEBIN` counterpart and confirm the writer leaves virtual RAM unchanged.
   Add coverage for stopped and autostart loads, malformed or oversized ranges,
   and invalid autostart addresses. No stream counterpart or new device is
   needed.

## References

- [Kio's ZX80/ZX81 format note](https://k1.spdns.de/Develop/Projects/zasm/Info/O80%20and%20P81%20Format.txt): both load bases, exclusive end pointers, and the `.p81` distinction.
- [no$zx technical reference](https://problemkaputt.de/zxdocs.htm), specifically the ZX80/ZX81 memory-map and cassette sections: ROM-specific layout, legacy trailing bytes, and nonstandard loaders.
- [zasm ZX80 output](https://k1.spdns.de/Develop/Projects/zasm/Documentation/z122.htm) and its [ZX80 source template](https://k1.spdns.de/Develop/Projects/zasm/Examples/template_o.asm): an assembler precedent that expects source-defined variables and checks `E_LINE`.
- [z88dk appmake](https://github.com/z88dk/z88dk/blob/master/src/appmake/zx81.c): a contrasting precedent that generates BASIC and machine-code scaffolding for a particular runtime.