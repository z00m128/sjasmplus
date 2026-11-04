# Label Usage Traits Research

Research notebook, 2026-11-04. This records proposals, not a feature specification
or implementation commitment. No assembler behavior or export format is changed.

## Scope And Historical Context

[Issue #48](https://github.com/z00m128/sjasmplus/issues/48) requested richer label
information for documentation generators, disassemblers, and debuggers. SLD now
substantially addresses the metadata/export part: symbol scope, EQU and structure
traits, used status, source locations, memory pages, and instruction-start records.
It does not implement operand-specific EXEC/READ/WRITE/LOAD/DATA usage traits.

The 2019 discussion proposed those traits, but the requester rejected attributing
EXEC to `example1` merely because `call example1+15` occurs. Instruction start is
not the same thing as membership in an executable region. The discussion also
favored keeping related metadata together, rather than requiring several exports.
The 2020 follow-up proposed structured annotations and MSX slot/subslot identity;
keyword comments and page descriptions address parts of this, not a complete MSX
mapping model. These were exploratory suggestions, not a settled completion list.

Closing #48 as substantially implemented by SLD is reasonable if the deferred
usage work is acknowledged. This notebook preserves that remaining direction;
it does not claim that every suggestion in #48 was implemented.

[Issue #161](https://github.com/z00m128/sjasmplus/issues/161) is separate. Its XMAP
memory flags classify every physical byte, including unlabelled bytes and mixed
numeric/text operands within one DB. Symbol usage traits cannot replace that map.
Existing symbol information could supply its labels chunk after format conversion,
page translation, and selection among same-address labels. A future typed-emission
stream could share infrastructure with these traits, but neither feature requires
the other. XMAP design is outside this notebook.

## Proposed Meaning Of Traits

These are static source-use observations, not proof of runtime execution or a
complete type system. Traits accumulate and are not mutually exclusive. A routine
can be read, written, and called; unused code can still contain references.

| Candidate trait | Suggested observation | Important limit |
| --- | --- | --- |
| EXEC | Direct control-flow destination | Not all symbols participating in a target expression are entry points |
| READ | Address operand of a CPU memory read | Not an assembly-time memory query or an immediate constant |
| WRITE | Address operand of a CPU memory write | Can describe a base plus offset, not necessarily the exact labelled byte |
| LOAD | Symbol value loaded as an immediate | Does not establish that the value is a pointer |
| DATA | Symbol value emitted as data | Does not establish that the symbol points to data |

Maintainer proposal: `ld (txt_data+15),a` legitimately gives `txt_data` a WRITE
trait, while `call txt_data+15` should not automatically give it EXEC. Preserve
this asymmetry explicitly: WRITE here means an address derived from the symbol
is written, not necessarily that the byte at its exact value is written.
READ can follow the same base/offset policy if selected. This is still only a
use relation: without object-size knowledge it does not prove that offset 15
belongs to the labelled object.

Names and serialized spellings are undecided. In particular, LOAD and DATA need
wording that consumers will not mistake for pointer types or region classes.

## Local Implementation Evidence

* [ParseLine](../sjasm/parser.cpp#L1061) prepares/substitutes a line, then parses
  labels, macros, and instructions. A reset at source-line entry is too broad for
  operand attribution and must also accommodate nested macro/repeat/Lua parsing.
* [SearchLabel](../sjasm/tables.cpp#L203) resolves local/module/macro name variants.
  It is also used for existence queries. Collect only the selected resolution,
  not every candidate examined during namespace fallback.
* [GetLabelValue and related accessors](../sjasm/tables.cpp#L286) distinguish value,
  page, physical value/page, and size queries. Hooking every search indiscriminately
  would confuse these uses. Ordinary numeric temporary labels take another path.
* [Expression primitives](../sjasm/parser.cpp#L37) support assembly-time memory
  reads, `$`, page/physical operators, and named/temporary labels. Unary operations
  and arithmetic can turn an address into an unrelated integer.
* [ParseExpression](../sjasm/parser.cpp#L393) evaluates an alternate result first
  when relocation is active, then the ordinary result. This must not create two
  independent semantic uses or leak alternate values into attribution.
* [CALL](../sjasm/z80.cpp#L662), [JP/JR](../sjasm/z80.cpp#L951), and
  [LD](../sjasm/z80.cpp#L1161) own the operand meanings. LD distinguishes immediate
  values from memory addresses after parsing and has register/indexed/fake forms.
  Multi-argument syntax loops inside instruction handlers.
* [Label SLD output](../sjasm/parser.cpp#L887) happens at definition time during
  the final pass. [ExportLabelToSld](../sjasm/tables.cpp#L136) serializes traits
  already known then. Later uses cannot retrospectively alter that written line.
  DEFL symbols are deliberately omitted from these SLD records.

Hypothesis: operand-scoped expression observation plus a few instruction-handler
commit points can implement a useful subset without changing parser architecture.
The cheapest discriminating prototype would handle direct CALL and the two
absolute-memory LD directions, testing offset attribution, relocation double
evaluation, failed parsing, and uses after a label's SLD record. No prototype or
overhead benchmark has been performed for this notebook.

## Maintainer Proposal: Collect Then Classify

The proposed mechanism is to clear a small list, collect resolved labels while
evaluating expressions, and let the particular instruction/directive tag them
after it knows their use. This separates numeric evaluation from operand meaning
and avoids teaching the expression parser every opcode.

Refine the lifetime to one semantic operand, not every line or even every opcode:

1. Enable collection for a selected operand; save any enclosing collection state.
2. Record resolved symbol identities and any provenance needed by the chosen rule.
3. Perform the ordinary evaluation; suppress observation of the relocation trial.
4. Classify the successfully recognized operand form and validate it.
5. Commit its semantic use only when the instruction form is accepted; otherwise
   discard it. Restore the enclosing state on every exit path.

The exact commit point needs care: expression success alone does not establish a
valid instruction, and some handlers emit fallback bytes after diagnostics.
Operand syntax alternatives also need checkpoints/discard, not just a single
instruction-wide success flag. A scoped C++ helper is a possible small mechanism,
not an existing API or a requirement for a new general parser-context framework.

One instruction can evaluate multiple expressions with different roles:
`ld (ix+offset),value` must not tag `value` WRITE, and `offset` is a displacement
used with an unknown runtime base, not an absolute symbol address. Repeated
arguments and fake instructions must start new semantic scopes as appropriate.
Recursive evaluation inside one expression must contribute to that expression,
whereas a nested independent assembly operation must not inherit its collector.

Do not change the existing `used` semantics: IFUSED/IFNUSED influence assembly.
These descriptive traits should not select code or make convergence depend on
debug metadata. If they ever become source-queryable, that is a separate feature.

## Why Matching Final Values Is Not Enough

For `call txt_data+15`, filtering referenced symbols by equality with the final
target avoids the obvious wrong EXEC attribution to `txt_data`. It is a useful
filter, but not a sufficient proof of intent:

```asm
    call target+(size-size)
    call target*0+destination
    ld (buffer+index),a
    ld hl,end_label-start_label
```

`size` or the cancelled `target` can coincidentally have the same value as the
result. `index` can be a numeric offset, not an object written. The final LD loads
a distance, not both label addresses. A list of names plus one numeric result
does not retain these distinctions. Filtering all READ/WRITE candidates by value
would also lose the desired `buffer+15` attribution.

Keep numeric matching as an optional heuristic only, or combine it with a
conservative provenance rule. Do not call it unambiguous semantic attribution.
Comparisons must use the appropriate logical/physical address space and page,
not just a low 16-bit value. Banked aliases, DISP, explicit EQU pages, relocation,
and out-of-range values narrowed to machine operands need explicit policies.
Do not legitimize an invalid operand merely because its truncated value matches.

## Implementation Options

### A. Small Resolved-Label List

This is the maintainer's low-intrusion starting point. Use a reusable vector of
resolved entries, active only for selected operands. `clear()` normally retains
capacity; it does not imply freeing/reallocating the vector each time. Stable
symbol identity avoids storing/reparsing names or looking up every symbol again.
Verify entry lifetime before retaining pointers beyond the synchronous operand.

Repeated occurrences can be left in the short list and committed with idempotent
bitwise OR, avoiding a hash set. This is cheap but loses expression structure:
either explicitly document heuristic attribution or initially accept only a
restricted syntactic subset. A list by itself cannot distinguish a base from a
cancelled symbol, dimension, or offset constant.

### B. Conservative Expression Provenance

Alongside the existing numeric result, optionally track a small summary such as
no symbolic value, one symbol plus a constant offset, or ambiguous/unsupported.
Distinguish ordinary value access from page/size/existence queries. Preserve a
base for supported additions/subtractions; mark unsupported combinations unknown.
There is no need to store a full expression tree to provide this limited subset.

EXEC could require an eligible symbolic target with zero offset. READ/WRITE could
accept an eligible base plus a constant offset, matching the maintainer's example.
Expressions such as `end-start`, HIGH/LOW, multiplication, and mixed-symbol sums
can conservatively produce no address-use trait. Missing some true uses is better
than silently claiming precise inference from an ambiguous expression.

This requires touching expression operator propagation, not just symbol lookup.
It may still fit the existing recursive-descent evaluator, but its footprint and
cost are not established. Treat EQU and DEFL identity separately from inferred
address-ness: an EQU can intentionally name a port, a constant, or an entry point.

### C. Bare-Symbol First Subset

An even smaller semantic target is accepted direct named-symbol operands only,
with optional parentheses where they select memory access. Commit EXEC for
`call routine`, READ for `ld a,(variable)`, WRITE for `ld (variable),a`.
Reject compound expressions for attribution rather than introducing a second
source parser or reparsing a symbol and changing its existing lookup side effects.
An expression summary of "exactly one bare value symbol" can support this subset.

This deliberately omits the desired WRITE on `buffer+15`, so it is a staged
implementation, not a complete realization of the maintainer's proposal.

### D. Semantic Use Records Instead Of Immediate Label Bits

Instruction handlers could emit events describing the operand role, referenced
symbol/base if known, target value, and source location. A collector/exporter then
derives traits. This retains offsets and explains why a trait was assigned, and
can avoid final-pass definition-order problems by exporting uses as later records.
It needs a compatible export contract and more metadata than aggregate bits.
Full use-site persistence should be optional if consumers only need totals.

Reverse lookup of every label at a numeric target is not an equivalent shortcut:
it tags unreferenced aliases, needs page-aware indexing, and loses symbolic intent.
An opcode-specific "set trait on lookup now" mode also cannot safely undo failed
or reinterpreted parses and still has the compound-expression problem.

## User-Visible Boundaries Worth Deciding

* `ld a,(value)` reads memory; `ld a,value` loads an immediate. Assembly-time
  `{value}` reads device memory during assembly, not CPU memory at runtime.
* `call routine`, `jp routine`, `jr routine`, `djnz routine`, and `rst vector`
  can have direct targets; JR/DJNZ need the original destination, not the encoded
  displacement. Conditional control flow is a possible use, not guaranteed execution.
* `jp (hl)` has no statically known target. `ld hl,routine : jp (hl)` does not
  establish EXEC without data-flow analysis, which is outside the proposed scope.
* `inc (hl)` and `set bit,(ix+offset)` read and write memory but reveal no named
  absolute target. LDIR and stack effects likewise cannot be attributed to named
  objects from their opcode alone. Do not claim complete memory-use coverage.
* `out (port),a` and `in a,(port)` address I/O, not RAM. Separate I/O traits or no
  memory trait is preferable to silently merging address spaces.
* `dw routine` stores a symbol value; it does not prove an execution target or a
  pointer table. Conversely, `dw end-start` is a size. DATA should describe use
  in an initializer, not assert a target's memory type.
* `alias EQU routine` raises whether uses attach to alias only or transitively to
  routine. Initially record the symbol explicitly referenced; propagation needs
  retained definition dependencies and policy, not value equality among aliases.
* DEFL rebinding makes a whole-symbol union historical rather than one-address
  information. Numeric temporary labels and smart-SMC labels also need explicit
  support or documented exclusion. Existing +smc is not the same as a WRITE use.
* Skipped source and unexpanded macro definitions should not contribute CPU-use
  traits. Replayed macros/repeats and Lua-injected assembly should contribute
  their actual parsed operands, without retaining parent collectors accidentally.

## Passes, Export Timing, And Cost

An export-only observer can be disabled unless requested. The intended baseline
is to collect usage traits during pass 2 and retain them for definition-time SLD
output in pass 3. Thus a use later in source has already contributed its traits
before the final pass reaches the label definition. Neither buffering SLD labels
nor adding update records is required for this design.

Maintainer clarification: source introducing a trait only late in pass 3 does not
fit the expected three-pass settling model. Missing that trait from an earlier
SLD record is an accepted limitation, not an export-timing defect to solve here.
This does not claim that all final-pass-only source is invalid: final-only output
actions are normal, but new semantic uses need not be reflected retrospectively.

For future N-pass assembly, use traits from the accepted preceding settling
traversal, not a union of discarded traversals. Trait reset/retention belongs with
that pass lifecycle. Buffering or later use/update records remain optional richer
export designs, not prerequisites for the current three-pass feature.

Preserve the current binary output, diagnostics, symbol values, `used` state, and
default export behavior. Keep the broad parser refactor independent. Operand
attribution and instruction coverage are the main reasons this can exceed "a few
hooks" even if the first subset is small; definition-time SLD output is compatible
with the intended pass-2 collection.

The cost question needs measurements, not an assumed microsecond estimate.
Measure disabled, enabled, and export-I/O costs separately on a large realistic
project and a generated million-instruction workload. Include symbol-free code,
many references per expression, macros, and relocation. Reuse collector capacity;
avoid per-operand allocation, string copying, full-table scans, and hash sets
unless measurements justify them. Report compiler/build configuration, workload,
repetitions and elapsed-time variation; do not infer overhead from one noisy run.
An inactive observer still adds a branch at its hook sites; quantify that cost.

## Focused Prototype And Regression Plan

Start with CALL and absolute-memory LD, one operand collector and a deliberately
limited attribution rule, collecting in pass 2 for existing pass-3 SLD output.
Compare candidates A/C against a small provenance summary B;
do not implement a full tree or dependency graph just to settle this choice.

Tests should cover exact symbols and offsets; cancelled/multiple symbols and
coincidental equal values; forward/backward definitions and same-address aliases;
immediate versus memory operands; invalid/fallback parses; page/size/existence
queries; assembly-time memory access; relocation double evaluation; DISP/banked
addresses; macro/repeat replay and multi-argument instruction forms. Verify unchanged
binaries and existing IFUSED behavior as well as exported traits. Include a label
whose only use is later in source: its pass-2 trait must be present when its SLD
definition is emitted in pass 3. Characterize late pass-3-only uses as the accepted
limitation above, not a requirement for retrospective SLD updates.

Extend the existing [SLD feature tests](../tests/listing/sld/sld_basics.asm) rather
than inventing a separate harness. A dedicated no-export performance baseline
and enabled-observer benchmark are needed before choosing wider instruction
coverage. No implementation, fixtures, benchmarks, or GitHub issue state were
changed by this research.