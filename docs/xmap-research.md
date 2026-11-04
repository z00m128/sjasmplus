# XMAP Memory Classification Research

Research notebook, 2026-11-04. This preserves the request, maintainer proposals,
implementation alternatives, and verification questions. It is not a feature
specification or implementation commitment. No assembler behavior is changed.

## Request And Existing Evidence

[Issue #161](https://github.com/z00m128/sjasmplus/issues/161) requests Xpeccy XMAP
export: labels, comments, and a classification flag for every physical memory
byte. This last part is not a label trait. Unlabelled regions and different
operands within a single directive need classification too.

[Issue #48](https://github.com/z00m128/sjasmplus/issues/48) is substantially
addressed by SLD's richer symbol metadata. Its remaining usage ideas are discussed
in [label-usage-traits-research.md](label-usage-traits-research.md). They are not a
prerequisite for XMAP. A symbol's READ/WRITE/EXEC uses and the originating kind of
each emitted byte are different observations.

The issue's proposed classifications use the high nibble:

| Flag | Meaning in the discussion |
| --- | --- |
| 0x00 | Default, treated as code |
| 0x10 | Byte data |
| 0x20 | Word data, displayed numerically |
| 0x30 | Address word, eligible for symbolic display |
| 0x40 | ASCII text |
| 0x50 | Code marked by runtime mapping as executed |

Do not silently redefine low bits or equate source-declared code with observed
execution. Whether assembler-generated instructions should use 0x00 or 0x50 needs
agreement with the consumer. Using 0x00 preserves the default-code interpretation
but does not distinguish unclassified space from known instruction bytes.

The requested format has an eight-byte `XMEMMAP ` header followed by chunks with
eight-byte identifiers, a four-byte length, and that many payload bytes. RAM and
ROM flags are separate arrays, not machine-code arrays. Labels and comments have
separate textual payloads. For ZX128, 128 KiB of RAM would need 131072 flag bytes;
the 16-bit CPU address space is not the size or indexing scheme of this array.

The [attached example archive](https://github.com/z00m128/sjasmplus/files/7799480/xmaptest.zip)
was inspected in memory during the preceding issue research. Its `sc.xmap` has:

* `ramflags`: 524288 bytes, despite `sc.asm` selecting ZXSPECTRUM128.
* `romflags`: 65536 bytes, all zero in this example.
* An empty `sltflags` chunk, not described in the issue's original format sketch.
* Separate `labels  ` and `comments` chunks. Comment lines include a RAM/ROM
  prefix, unlike the original sketch's shorter comment format.
* A 72-byte 0x50 run, 46 numeric-byte flags, and 40 ASCII flags. Mixed DEFB lines
  split control bytes, quoted text, and terminators into distinct runs.

The inspected chunk lengths decode as little-endian 32-bit integers. This is
sample evidence, not a complete current Xpeccy compatibility specification. The
larger allocation, optional chunks, flag semantics, text escaping, and accepted
RAM lengths should be checked against the target emulator version before coding.

Current SLD cannot reconstruct these distinctions. A preceding stdin experiment
produced identical SLD for `DB "AB"`, `DB 65,66`, and `DW $4241` at the same
labelled location. Instruction `T` records identify starts, not lengths or typed
data ranges. Reparsing source to fill these gaps would reproduce assembler logic.

## Maintainer Proposal: A Fourth Traversal

After ordinary assembly, traverse source again with an instruction table or emit
backend that writes classification flags instead of machine code. A distinct
compiled path, possibly using templates and `if constexpr`, could avoid extra
runtime classification work during ordinary assembly without XMAP.

The attraction is reusing established parsing, length calculation, macro expansion,
and page handling without manually duplicating every opcode. The concern is
source growth and maintenance: replacing a few hooks is attractive; doubling the
opcode source or adding branches to every instruction is not.

Local hypothesis: most opcode semantics can stay unchanged because every byte
of an instruction, including immediate operands, is classified as code. The
primary semantic additions belong at instruction-emission boundaries and typed
data producers. However, an output-backend substitution alone cannot guarantee
that a fourth source traversal recreates the final emitted program.

A cheap discriminating prototype would classify mixed DB, DW, and one multi-byte
instruction using shared parsing, then test final-pass Lua and device-memory
reads under replay. Compare this with classification attached to the existing
final traversal. No fourth-pass prototype, duplication percentage, or performance
measurement has been performed; in particular, "80% unchanged" is not established.

## What The Current Code Already Knows

* [EmitByteNoListing](../sjasm/sjio.cpp#L429) advances addresses and mapped memory,
  but writes actual output/device bytes only in LASTPASS. It has no data-kind
  parameter. Address/page changes must remain correct for flag output as well.
* [EmitByte and the bulk emitters](../sjasm/sjio.cpp#L454) carry an instruction-start
  boolean. `EmitBytes` knows when an instruction begins and encounters internal
  start markers for fake sequences. Ordinary following operand bytes have a false
  start flag, so that boolean alone does not classify every byte as code.
* `EmitWord` is a byte-order operation, not proof of word data: instruction
  encoding and wider data fields also use it. Defaulting all its calls to DW
  classification would be wrong.
* [DB-family parsing](../sjasm/reader.cpp#L647) recognizes strings before flattening
  them into an integer buffer. Preserve per-operand spans here, including rollback
  when a single character turns out to be part of an expression.
* [Data directives](../sjasm/directives.cpp#L109) distinguish DB, DW, D24, DWORD,
  prefixed/terminated strings, and initialized blocks. DW evaluates each operand
  separately, which is an appropriate place for optional address provenance.
* [Structure emission](../sjasm/tables.cpp#L1342) already switches on member kinds:
  byte, word, wider integer, text, block. It is another producer, not an ordinary
  DB/DW directive call, and must be covered independently.
* [Block and INCBIN emission](../sjasm/sjio.cpp#L510) can bypass `EmitByte`. A hook
  only in that public function misses these bytes.
* [Lua add_byte/add_word](../sjasm/lua_sjasm.cpp#L339) call ordinary emitters, while
  [CDevice::Poke](../sjasm/devices.cpp#L498) directly changes RAM without advancing
  the assembly address. Patches and other direct memory writes need a policy, not
  accidental classification based on which helper was used.

For core instruction classification, JP and CALL should not require special
metadata paths: their opcode and immediate address bytes are all code in #161's
model. Branch destination analysis belongs to usage research, not classification
of the instruction's own bytes. It is typed data and bypass paths that widen this
work beyond a single emitter replacement.

## Alternatives

### A. Sidecar Map During The Existing Final Pass

Keep machine-code emission unchanged in meaning and write classifications to a
separate, lazily allocated map while the final traversal emits actual bytes.
Attach semantic kind to a producer scope or an explicit typed range; apply it to
the physical locations actually written.

Advantages: no source replay, no extra Lua execution, and the same final-pass
control flow determines bytes and types. Untouched output behavior stays under
the existing pass gates. A small optional map pointer/flag can make this a
relatively local implementation.

Costs: a runtime check on disabled paths unless compiled out or specialized;
per-byte overhead if implemented naively; careful context restoration for nested
parsing. Batch contiguous ranges when possible, but split them at actual device
page transitions and preserve overwrite order.

A broad scope saying "instruction" works for ordinary opcode output. A DB scope
alone is insufficient for mixed numeric/string operands; those need finer spans.
Prefer explicit range/operand metadata over ambient context where direct Lua
calls or recursive parsing could inherit an inappropriate kind.

### B. Final-Pass Typed Events, Followed By A Map-Building Stage

Record events such as device identity, physical offset, length, and classification
while ordinary final emission occurs. Afterwards expand/coalesce these events
into flags and serialize XMAP. This is an extra processing stage, not another
assembly traversal.

Advantages: no execution replay; event ordering models overlaps; contiguous
regions are compact; export policy is separated from byte production. The same
events could support future typed-range SLD extensions or another consumer.

Costs: event storage or a streaming intermediate, allocation/coalescing policy,
and final-pass hooks still exist. Alternating types or many isolated overwrites
can make events larger than a dense flag array. Store resolved physical identity
at the time of writing, not a CPU address to reinterpret under the final mapping.
There is no need to retain opcode bytes if flag generation does not inspect them.

### C. Fourth Source Traversal With A Classification Sink

Reuse source parsing and replace emission behavior for the metadata traversal.
Keep machine bytes and flag bytes in different storage. Classification flags
must never replace the RAM image that assembly expressions or scripts inspect.

Advantages: potentially leaves the normal emission backend uninstrumented; reuses
numeric parsing and expansion; allows an opt-in slower metadata operation.

Costs: extra parsing/evaluation and substantial replay policy even when much
source remains shared. Merely setting `pass=4` is not sufficient. In the
[current loop](../sjasm/sjasm.cpp#L814), final output and many directives depend
on `pass == LASTPASS`; `__PASS__` and `sj.pass` are observable. Running again as
logical pass 3 instead repeats final-only code and external effects. Running as
phase 2 omits final-only code. This is not an N-pass settling iteration.

[InitPass](../sjasm/sjasm.cpp#L296) destroys and recreates devices, rebuilds macro
and structure tables, resets namespaces/counters, and advances temporary-label
baselines. It does not preserve the final machine image as a replay environment.
Retaining that image is also not a complete answer: a source memory read can
depend on the partially written image at that point, not the finished image.

[Lua execution](../sjasm/lua_sjasm.cpp#L485) depends on logical pass selection and
retains VM state. Skipping it loses generated bytes; repeating it can generate
different bytes or repeat file/process effects. Include files can change too.
Either define a restricted deterministic/replay-safe subset, cooperate with
scripts explicitly, or capture final semantic events/expansions to replay instead.
Do not silently promise transparent replay for every existing project.

All ordinary saves, outputs, exports, listing/SLD writes, breakpoint handling,
diagnostics, and cleanup would need explicit replay treatment. The emitter is
only one of these side-effect boundaries. A mismatch should fail metadata output
without overwriting already-produced valid binaries or rerunning the final pass.

#### Maintainer Clarification: Stage Ordering And Script Contract

After considering script replay, the maintainer no longer favors a fourth source
traversal as the initial approach. From the user's perspective XMAP generation
should mostly feel like the existing final pass, not an unexpected repeat of
assembly after final outputs and script state have already been committed.

The alternatives are observably different:

* Collect during the one ordinary pass 3, using dual emission of machine code and
  classifications. This does not require the existing emitter to grow a runtime
  branch: a specialized dual-emission implementation remains a candidate, provided
  selection reaches the relevant call paths. This combines A/B with D rather than
  requiring another traversal.
* Collect with pass-2 semantics before pass 3. Prefer observing the existing
  completed pass 2 where sufficient. A dedicated metadata traversal, if needed,
  must occur before final emission; for N-pass this would be after settling.
  Another logical pass 2 is still observable to cooperative scripts, but does
  not reverse the expected ordering of settling and final side effects. An added
  traversal must be checked for renewed layout changes rather than assumed inert.
* Do not disguise post-pass-3 traversal as pass 2. Final files may already exist,
  and Lua globals may have entered a state in which another settling traversal
  is no longer meaningful. Matching the public pass number does not restore the
  earlier execution environment.
* An explicit public stage 4 would instead make the new operation visible through
  a defined script contract. Scripts could deliberately repeat code generation
  or opt out. That is a new feature with execution-selection/API and coverage
  rules, not a transparent backend replacement; opt-out cannot promise complete
  metadata for omitted generated code. No stage-4 interface is selected here.

For script-generated code, the expected contract is matching pass-2/pass-3 emits;
pass-1/pass-2 differences can be justified during discovery. Deliberately changing
generated code between passes 2 and 3 is outside that normal contract, and the
author must understand the consequences. This does not prohibit ordinary
final-only saves or other output actions.

The current three-pass model does not detect convergence by iteration: pass 2
simply completes once, and source is expected to settle adequately for pass 3.
Diagnostics may expose a mismatch but are not a complete convergence proof.
Pass-2-based classification accepts that same design boundary and cannot promise
the exact effects of arbitrary final-only code or device-memory-dependent
generation. This is a distinct tradeoff from collecting actual final emission;
N-pass settling does not itself make post-final replay transparent.

### D. Compile-Time Backends With Shared Source

A C++17 policy/template backend can discard classification code with `if constexpr`
in the normal specialization. This is a compilation strategy that can support
either same-traversal collection or a separate traversal; it does not resolve
replay semantics by itself. No C++20 standard bump is needed for this mechanism.

One concrete target is an ordinary machine-code-only emitter and a specialized
machine-code-plus-flags emitter, selected for the single final traversal. Both
produce the same machine bytes and preserve the ordinary logical pass sequence.
The requested zero-cost property concerns the non-XMAP path even when XMAP is
available in the executable, not only a separate build with support compiled out.

Ideally classification decisions occur in a few shared emit/producer helpers,
not an `if constexpr` in every instruction body. String/word producers still need
explicit semantic information. Selecting two opcode tables can reuse the existing
dispatch shape, but their entry functions must reach different compiled backends.
Two wrappers calling the same non-templated global emitter do not achieve that.

The key risk is propagation: template/static policy has to reach every relevant
call through instruction helpers, directives, structures, and script bindings.
If wrappers switch a global backend instead, they trade specialization for runtime
state/branches. Duplicating whole translation units with macros can share source
text but creates symbol/linkage and testing complexity; do not assume it is free.

Two compiled specializations need not mean twice the source text. They can still
increase binary size, compile time, and instruction-cache pressure. Distinguish
zero additional metadata instructions in the normal path from literally zero
measurable cost. Inspect generated code and measure before claiming either.

### E. Runtime Backend Dispatch

Use a selected function table, callback, or sink for byte/range output. This can
keep source changes small and backend implementations separate. A once-per-range
dispatch is cheaper in frequency than a once-per-byte dispatch, but still runtime
work. Indirect calls can affect inlining; switching a global function pointer is
not zero-overhead ordinary assembly. A dormant optional sink is a pragmatic
candidate if measured overhead is acceptable, not compliance with a strict
zero-extra-instruction requirement.

### F. Separate Instrumented Build Or Helper Executable

Compile metadata observation out of the normal binary, and enable it in an XMAP
build. This offers the clearest separation for the ordinary build's runtime path
without templating every call chain. Shared source still needs typed hooks;
there are two configurations to build and test. A helper that assembles source
again has the same replay problems as C. A metadata-enabled assembler that emits
both binaries and flags in its one final traversal avoids those replay problems.

### G. External Conversion, Annotations, Or Existing Exports

A converter is attractive once typed events exist, or with a documented manual
annotation mechanism. Existing SLD plus binaries can recover labels and identify
instruction starts, but cannot distinguish identical bytes from DB text, DB
numbers, and DW. A listing/source parser is incomplete around aliases, macros,
conditionals, structures, scripts, and mapping unless it duplicates assembler
semantics. Disassembly/string heuristics can be useful optional guesses but are
not equivalent to #161's assembly-time provenance.

### H. Record And Replay A General Assembly IR

Capture a semantic intermediate representation or complete final execution trace,
then run machine-code and flag backends over it. This can eliminate source replay
and support multiple consumers cleanly. It is a much larger architecture change
than needed solely for XMAP, especially if expressions, scripts, or patches must
remain executable rather than already-resolved events. Prefer B's narrow resolved
metadata events unless another feature independently justifies a general IR.

### I. Packed Machine Byte And Classification Carrier

Maintainer proposal: carry both the machine byte and extra classification bits
in the existing integer emission value. For example, a conceptual byte token is
`(machineByte & 0xFF) | (mapFlag << 8)`: default/code has no upper bits, numeric DB
uses flag 0x10, and ASCII uses 0x40. A dual emitter separates the low machine byte
from its classification. This is a transport representation, compatible with
same-final-pass collection and specialized MC-only/dual backends, not another
traversal or a requirement to widen device RAM.

Most instruction producers could remain untagged because their bytes have default
classification, including operand bytes. The existing `int` byte buffers already
have room for this conceptual token; it need not double their element width.
Only producers of non-default kinds need to supply tags. The proposed "95%
unchanged" is a plausible motivation, not a measured source-change estimate.
DB/DW are not the complete scope: structure fields, blocks, strings with prefixes
or terminators, INCBIN, and direct/script memory writes still need coverage.

Advantages: explicit per-byte metadata without an ambient type scope, no separate
classification argument at every opcode call, and no new flag argument in most
instruction buffers. A mixed DB line can retain string/numeric distinctions while
sharing its ordinary buffer and emit loop. This is more specific than the generic
sidecar/event options above and may provide their low-intrusion transport.

Important implementation boundaries:

* [EmitByte](../sjasm/sjio.cpp#L454) currently masks the value to eight bits before
  calling the lower emitter. Extract/forward metadata before that mask in the
  dual path; listing, raw/HEX output, and machine RAM must still see only MC.
* [Emitter sentinels](../sjasm/sjio.h#L36) are -1 and -2. Never tag or reinterpret
  them as payload tokens. Normalize valid signed byte values separately from
  marker handling; use a defined unsigned packing operation, not shifts of
  negative integers. Audit any range checks or comparisons on tagged buffers.
* `EmitWord` has sixteen payload bits, so a word's high byte cannot double as
  classification. Either tag after splitting into bytes or define a distinct
  word-token layout with classification above the sixteen payload bits and
  propagate that flag to both emitted bytes. Wider fields need an explicit rule.
  The maintainer favors tagging at this existing split: a data-word path can
  retain its 16-bit input and attach 0x20 separately to each resulting byte,
  avoiding a new wide-word token altogether. Keep the classification explicit:
  [opcode handlers also call EmitWord](../sjasm/z80.cpp#L700), so changing its
  unconditional default to DW would classify some instruction operands as data.
  The intended baseline keeps today's ordinary `EmitWord` entry/path unchanged:
  its split bytes remain untagged and therefore code/default 0x00. DW and similar
  data producers select a separate data-word entry/wrapper or specialization
  that tags the resulting bytes 0x20. A configurable data entry can allow a later
  address-word 0x30 variant if selected. This avoids changing every machine-code
  caller or making all word emission default to data.
* Arithmetic, range validation, truncation, relocation, string transformations,
  and filler selection must operate on machine values, not accidentally include
  tags. Pack after those operations where practical, and preserve tags across
  later buffer manipulation. This is where apparently unchanged helpers need
  auditing despite unchanged opcode producers.
* Zero is a real classification on an explicit write. Code overwriting an earlier
  DB region must replace its nonzero flags with zero; "store only nonzero tags"
  would leave stale data classifications. This does not resolve the separate
  policy for memory-preserving blocks and untyped patches.

Keep storage independent: retain the existing byte-addressed machine RAM and
allocate a sidecar only when XMAP is requested, or record sparse typed writes for
later expansion. Do not unconditionally replace every RAM byte with a wider
MC-plus-flags element. A dense one-byte sidecar doubles the RAM-array payload
while enabled, not total process memory; disabled assembly should allocate none.
Sparse storage can defer/reduce internal allocation, but serializing XMAP still
requires the physical-memory-sized flag payload (which may be streamed).

The carrier does not by itself establish zero disabled-path execution cost.
If data producers always calculate and OR tags, they add work even when no map
is requested. Combine this representation with compiled MC-only/dual producer
and emitter variants to eliminate that work, or explicitly measure and accept
the cheaper runtime-gated alternative. Merely allocating the sidecar lazily
solves disabled memory overhead, not disabled instruction overhead. Audit the
scope of specialization before claiming small source growth or zero overhead.

#### Maintainer Follow-Up: A Small Runtime Check Is Also A Candidate

Strictly eliminating disabled-path instructions remains desirable, but is no
longer a reason to require extensive specialization. The maintainer considers
a single predictable optional-map check per emitted byte potentially acceptable:
even a large cited MSX project is below roughly three million source lines and
has a 2 MiB cartridge image, not gigabytes of output. This is workload motivation,
not a measured bound on this assembler's overhead or a universal project limit.
Compare the simplest runtime-gated packed emitter against specialized variants
before paying substantial source/maintenance cost for a zero-instruction claim.
No flag array should be allocated when XMAP is not requested in either design.

## Classification Rules Still To Select

* Every byte of a parsed instruction is code, including prefixes, displacements,
  immediates, and fake-instruction expansions. DB-encoded opcodes remain byte
  data unless an explicit override is supported. Self-modifying code can retain
  source-code classification; types are not a claim about all runtime uses.
* Mixed `DB 22,0,0,"text",13` needs byte/text/byte spans. Single-character
  expressions, transformed ABYTE/DC values, encoding conversion, and non-ASCII
  text need a deterministic policy. The issue's described ASCII range and actual
  consumer handling of 0x7F/high-bit bytes should be verified, not guessed.
* DZ terminators and DP length prefixes should not accidentally inherit the
  body's ASCII flag. A DC high-bit terminator may not be ordinary ASCII. Preserve
  operand provenance before flattening rather than classifying by byte statistics.
* Numeric versus address DW is not resolved by "contains a label": `end-start`
  is a size and an EQU can be a constant or address. Conservative provenance,
  an explicit override, or initially treating all DW as numeric are alternatives.
  Reuse expression work from usage research only if its semantics genuinely fit.
* D24/DWORD, graphics/hex directives, incbin assets, padding/alignment, and block
  initialization have no exact flag for every possible original type. Define a
  lossy fallback. Splitting a DWORD into two machine words does not establish two
  semantically independent 16-bit data items.
* INCBIN classification is explicitly open. The maintainer reports posting an
  RFC on #161 asking whether to mark its entire included range 0x10 (byte data)
  or 0x00 (default/code). The current leaning is DB-like because it imports raw
  bytes, but complex projects also include code assembled in preceding build
  steps. Neither classification can infer the blob's contents or mixed regions.
  ASCII guessing is rejected. In the 2026-11-04 follow-up, Volutar also favors
  DB/DEFB because a raw binary has lost its type information, and questions adding
  XMAP-specific classification parameters to INCBIN. This supports 0x10 as the
  working default direction, not an implemented or finalized directive contract.
  Imported metadata is a separate possible extension, discussed below.
* Structures need their own member-kind coverage, including default text/fillers,
  nested members, wide fields, and blocks that preserve existing memory.
* A two-byte word crossing a physical page boundary, odd-aligned words, partial
  overwrites, and adjacent address words need consumer tests. The example does
  not establish how word grouping/start boundaries are represented by low bits.

## Follow-Up: INCBIN Metadata Composition And Consumer Coordination

The [2026-11-04 follow-up discussion](https://github.com/z00m128/sjasmplus/issues/161#issuecomment-6634386848)
adds three directions beyond choosing a default INCBIN flag:

* Volutar suggests that typed data in SLD would also help, at least enough for
  an external converter: byte versus word versus address data. This is a proposed
  extension, not information that current SLD already supplies. Typed ranges
  need extents and bank/address identity, including unlabelled data; more traits
  on label records alone would not satisfy it. This supports alternatives B/G
  without choosing native XMAP export versus an intermediate format yet.
* Volutar identifies [Xpeccy+](https://github.com/dotkoval/xpeccy-plus) as an actively
  developed, more user/developer-friendly fork and welcomes cross-development
  agreements. Treat it as a candidate compatibility partner; this notebook has
  not independently tested its current importer. Agree on a target version and
  existing format behavior rather than presume it matches the original sample.
  Existing sjasmplus exports may offer immediate integration opportunities while
  new typed-memory metadata remains unimplemented.
* The maintainer proposes assembler-side composition: a producer assembly exports
  its binary blob and XMAP; a later assembly pairs INCBIN with a possible XMAP
  import directive and incorporates the metadata into its final exported map.
  The emulator would receive one composed map, not have to cascade component
  maps itself. No import directive name, syntax, or automatic pairing is selected.

This import is an independent optional enhancement. Plain INCBIN can remain a
DB-like byte range; projects with preassembled code or mixed data could explicitly
restore classification from the producer's map. No type inference from binary
content and no rerun of the producer's source/scripts is required.

An initial import experiment could handle flags only, leaving labels/comments to
later work. Before selecting implementation rules, resolve these boundaries:

1. A binary file offset is not an XMAP physical-memory offset. Record or explicitly
   supply which producer memory range corresponds to the saved blob, especially
   with partial saves, holes, banks, or concatenated output. INCBIN's offset/length
   selection must select the corresponding metadata, not the whole producer map.
2. Translate the selected source range into the importing device's actual write
   locations, splitting at page boundaries and respecting any displacement policy.
   Same-page/same-origin import is only a simple special case. A metadata import
   must not silently relocate machine code or rewrite embedded address values.
3. Define ordering relative to INCBIN and subsequent writes. Imported flags must
   replace the default INCBIN classification, including explicit 0x00 code flags;
   later overwrites should follow the selected ordinary map-write policy. Define
   what happens if metadata is imported without a matching blob write.
4. Validate selected bounds, chunk lengths, supported device/mapping information,
   and missing or stale companion artifacts. XMAP alone does not establish that
   a map belongs to a particular binary; do not claim identity verification without
   a corresponding mechanism. Reject unsupported mappings rather than guess.
5. If labels/comments are later imported, define naming, aliases, address
   translation, collisions, and merge precedence separately. Moving flag bytes is
   not sufficient evidence that all exported symbol values should be rebased.

Useful tests include a producer blob containing code plus numeric/string data,
a partial INCBIN selection, a changed destination origin/page, imported zero flags
over the DB default, a later overwrite, and mismatched map/blob bounds. Verify
that the composed map displays correctly in the agreed emulator version and that
neither producer nor consumer machine-code output is changed by metadata import.

## Addressing, Overwrites, And Lifetime

The maintainer favors device-only XMAP support. A DEVICE gives the physical
array's extent and bank mapping; a source-positioned export directive can snapshot
its current map just as memory-save directives snapshot machine RAM. Streaming
mode has neither that complete device image nor an equally clear map extent and
export boundary. Treat streaming support as out of the initial scope, not a
problem that must be solved before device-mode implementation. No directive name
or syntax is selected.

The intended activation mechanism is discovery of the export directive during
pass 2. Retain the feature request across pass initialization, enable collection
from the start of pass 3, and allocate the relevant device sidecar before its
first write. Devices are recreated during initialization, so allocation must fit
their creation lifetime rather than require an already-existing device at the
instant pass 3 begins. A directive near the end can then export classifications
for earlier bytes without allocating metadata for ordinary assemblies that never
request XMAP. Discovery enables the feature; it does not write the export file.

Maintainer clarification: deliberately hiding the only export request behind
`IF 3 == __PASS__` is outside the supported discovery contract, not an assembler
deficiency requiring retrospective collection or unconditional allocation. Normal
source should encounter the request in pass 2 as well as pass 3. A diagnostic for
an undiscovered final-pass request would be useful; silently exporting an
apparently complete map with missing earlier writes would not be. No diagnostic
wording or directive syntax is selected here. Under future N-pass assembly, use
request discovery from the accepted settling traversal rather than accumulate
requests from branches discarded during settling.

Each source-positioned export is a snapshot, not an automatic end-of-assembly
dump. Later writes may change a later export without modifying an earlier file.
Define the corresponding label/comment selection and multiple-export/device
rules explicitly; do not defer serialization to EOF while claiming directive-
position semantics. Requests should be validated in dry passes, but files written
only during the normal final-pass export operation.

Use physical RAM offsets for the array, distinguishing device identity and page
from CPU address. For uniform ZX128 pages, page times 16384 plus page-local offset
is the intended linear form. The sample's CPU address 30000 maps to RAM offset
0x17530 in page 5. Page switches and wrap options can split a contiguous CPU span.

ZX48's assembler page numbering is not the emulator's 5/2/0 RAM numbering, and
the device model is not a complete ROM model. Either define and test translation
or initially restrict support to a documented device set. Do not silently export
arbitrary custom/Next device pages as ZX128. Multiple devices in one source also
need a selection, multiple-file, or rejection policy.

DISP separates physical write location from intended runtime address. Choose
whether the map describes storage or runtime placement. Runtime placement may
need explicit page data; a static source map cannot infer arbitrary runtime copies,
decompression, overlays, or loaders. Label translation must follow the selected
interpretation rather than accidentally mixing SLD logical pages with physical
flag offsets.

A natural initial policy is last explicit write wins, in actual emission order.
But a poke patching an instruction operand may reasonably preserve its existing
CODE classification rather than turn it into data. Define automatic emission,
untyped patch, and explicit metadata override behavior separately. Preserving
memory with DS/structure blocks should not accidentally erase earlier types.
ORG without writing, backwards address motion, and device-initialized memory also
need policies. Do not infer classification from zero versus nonzero machine data.

The dense array is modest for ZX128 but a custom device can be much larger.
Allocate metadata only on request, bound memory use and chunk lengths, and decide
whether untouched pages serialize as defaults. Sparse ranges can save internal
storage; the final XMAP payload is still the array expected by the consumer.

Labels are a separate conversion problem: handle signed/non-address EQU values,
page validity, same-address aliases, naming, UTF-8/newlines, ROM/RAM prefixes, and
deterministic output order. The author accepts first/last alias selection. Comments
need a selection/merge policy and a decision whether to export only explicit
annotations or general source comments; XMAP permits only one comment per address
in the discussed version. Existing SLD keyword collection is a useful precedent,
not a drop-in format serializer.

## Recommendation And Verification Gates

First establish classification and consumer rules, independently of pass count.
Prototype a narrow same-final-pass sidecar or typed-event collector (A/B), because
it describes the bytes actually emitted without another script/source execution.
Also prototype the smallest compile-time hook boundary if eliminating disabled
runtime instructions is a firm requirement. Compare it with a measured optional
runtime check rather than assuming either cost is decisive.

The packed carrier in I is a concrete candidate for that prototype: preserve
ordinary instruction values, add tags at typed producers, and compare compiled
MC-only/dual-emission paths with a simple optional-map check. Test mixed DB,
data-specific word splitting, marker
safety, and zero-tag overwrites before extending producer coverage. Verify that
the non-XMAP path allocates no map; measure tag/check work in the runtime-gated
variant rather than requiring it to meet the specialized zero-instruction goal.
Start with device-only snapshots. The RFC follow-up supports a DB-like INCBIN
default of 0x10; confirm that design choice before implementation and keep optional
companion-map import separate from the initial export feature. Coordinate typed
SLD/converter possibilities and format compatibility with the chosen consumer.

The maintainer's initial preference for a fourth source traversal has receded
because of its script-visible lifecycle. Retain it as an alternative for an
explicit stage-4 contract or a documented replay-safe subset, not the baseline.
Pass-2-like collection belongs before final emission, with its limitations made
explicit. Event-driven postprocessing needs no extra source/script traversal.
Do not select replay solely to avoid a branch before accounting for its pass-state
and side-effect surface.
No design currently demonstrates that every opcode must be rewritten, nor that
a handful of emit substitutions suffices for complete coverage.

Before choosing an implementation, verify:

1. Mixed DB and structure fields, DW numeric/address policy, full instruction
   extents, and all bypass paths produce the expected flags without changing
   binaries, diagnostics, symbol values, listing/SLD, or existing output files.
2. Compare against hand-authored expected flag arrays, not merely a round trip
   through the new serializer. Test bank mapping, page crossings, overlaps,
   preservation/patches, DISP, unlabelled data, aliases, and untouched RAM.
  Include export after earlier writes, two exports separated by overwrites,
  device/request discovery, and rejection of unsupported streaming export.
3. Decode a generated XMAP with an independent reader and load it in the target
   Xpeccy version. Verify chunk lengths/endianness, RAM capacity, absent/empty
   optional chunks, low-bit conventions, word boundaries, text, and comments.
4. If source replay is used, test ALLPASS/PASS3 Lua, Lua byte emission and pokes,
   memory-derived values/checksums, final-only branches, changed input files,
   saves/process effects, and stdin. Detect divergence without replaying outputs
   or silently returning an apparently successful but mismatched map.
5. Measure ordinary-build disabled overhead, enabled classification, serialization,
   memory use, binary size, and compile time. Include large instruction streams,
   large blocks/incbins, mixed data, macros, and Lua-generated output. Check
   generated normal-path code for compile-time alternatives; keep comparisons
   reproducible and report variation, not a single timing.

Use existing assembler-level tests and the normal focused test runner rather than
inventing a new harness. Sample archive inspection and the earlier SLD comparison
are characterization evidence only: no XMAP generator, fourth-pass prototype,
new regression fixtures, or benchmarks were implemented. Issue #161 remains open;
this research does not alter GitHub state or select public syntax.