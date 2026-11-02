# N-Pass Assembly Research

Research notebook, 2026-11-02. This is not a feature specification or an
implementation commitment. No assembler behavior is changed by this research.

## Recommendation

Repeating logical pass 2 is a sound direction for sjasmplus. It preserves the
useful split between discovery, layout settling, and final emission. The existing
numeric-label and relocation machinery already embodies parts of this model.
The main loop is close; production-quality convergence and state management are
not just a loop change.

Keep `__PASS__` and Lua's `sj.pass` at 1, 2, and 3. Use a separate internal
generation for each source traversal. Repeat logical pass 2 until two consecutive
settling results agree, then perform logical pass 3 once, retaining consistency
checks against the accepted baseline. Do not expose an actual-iteration define
without a demonstrated need. Verbose progress/error messages can report iteration
counts without making them available to source expressions.

Start opt-in and preserve the existing three-pass default. No command-line syntax,
default iteration limit, version target, or detailed compatibility policy is
selected here. Supporting 20+ settling iterations is reasonable; guaranteeing that
arbitrary programs converge is not. Keep this independent of the larger
[parser-context refactor](parser-context-research.md).

## Scope And Evidence

Inspected the pass driver/reset code, named/numeric/structure symbol paths,
diagnostic phase gates, relocation, smart-SMC, device emission/reads, Lua lifetime,
and early/final output paths. The current manual's three-pass and Lua examples
remain the specification of existing behavior. This research proposes possible
extensions, not a change to that specification.

Built with `make -j8`. Ran 15 characterization cases against the current release
executable using stdin and `--raw=-`, with a five-second timeout per invocation.
One IFUSED probe was initially invalid because it used register names; the results
below use the corrected routine names. Also ran five small fixed-point models in
Python. These models are not an N-pass assembler implementation and cannot prove
that the complete C++ program would converge identically.

No C++ sources, headers, permanent test fixtures, output formats, or public options
were changed. Only research documents and the TODO link were edited. Baseline
tests were run sequentially with `make -j8 test TEST=<prefix>`:

| Prefix | Tests | Checks | Result |
| --- | ---: | ---: | --- |
| `parsing` | 54 | 67 | Pass |
| `misc` | 78 | 116 | Pass |
| `sjasmplus_regressions` | 20 | 29 | Pass |
| `lua_examples` | 34 | 38 | Pass |
| `define` | 11 | 15 | Pass |
| `expressions` | 4 | 6 | Pass |
| `relocate` | 30 | 32 | Pass |
| Total | 231 | 303 | Pass |

The full suite, other toolchains, and an actual repeated-pass prototype were not
run. The readiness assessment below is based on inspected code and bounded
experiments, not a measured implementation effort.

## Current Architecture

### Driver And Phase Identity

[sjasm.cpp](../sjasm/sjasm.cpp) increments global `pass`, calls `InitPass()`, reads
each source, finishes repeat/DISP state, and stops at `LASTPASS`.
[sjdefs.h](../sjasm/sjdefs.h) sets `LASTPASS` to 3. Output/SLD/HEX initialization
is tied to entering that final phase. After assembly, `pass` becomes 9999 before
dumping symbols, closing output, freeing state, and closing Lua.

Simply increasing `LASTPASS` is the wrong implementation: several paths explicitly
test `pass == 1` or `pass == 2`, while source-visible defines, Lua selectors,
diagnostics, and label refresh use the same integer for different purposes.
Intermediate pass numbers 3, 4, etc. would not automatically behave like pass 2.

Separate at least these concepts:

* Logical phase: discovery, settling, or final emission; source sees 1/2/3.
* Internal generation: unique for each source traversal, including final emission.
* Settling iteration: progress/limit accounting, not an expression primitive.
* Previous completed baseline versus definitions/events produced by this traversal.

### What Resets And What Survives

| State / owner | Current lifecycle | N-pass implication |
| --- | --- | --- |
| Address, DISP/module/local-label state, macro numbering, scratch context: [InitPass](../sjasm/sjasm.cpp) | Mostly reset each pass | Useful reset boundary; audit remaining globals rather than assuming it resets the entire process |
| Macro/STRUCT definitions and macro arguments | Rebuilt each pass | Correct general direction; generated definitions still publish persistent named symbols |
| DEFINE/DEFARRAY and `__COUNTER__` | Reset from command-line definitions; counter resets | Keep per-traversal reconstruction and source-order behavior |
| Named labels: [CLabelTable](../sjasm/tables.cpp) | Map persists; entries refreshed using `updatePass` | Need generation-aware definition identity and a policy for absent definitions |
| Usage flags and SIZEOF traits/data | Usage accumulates during non-final passes; SIZEOF is tracked through source boundaries | Include relevant state in convergence; do not casually reset sticky usage |
| Numeric labels: [CTemporaryLabelTable](../sjasm/tables.cpp) | Previous and current ordered vectors | Strong starting pattern; compare complete sequences before final emission |
| Smart-SMC: [ParseLabel](../sjasm/parser.cpp), [resolveRelocationAndSmartSmc](../sjasm/sjio.cpp) | Positions collected in pass 1; offsets refreshed later | First-pass flow remains an anchor; needs a rebasing policy for adaptive settling |
| Relocation: [Relocation::InitPass](../sjasm/relocate.cpp) | Current offsets copied to previous; table count refreshed, current cleared | Already iterative in shape; compare ordered contents/count and audit persistent flags |
| Devices: [InitPass](../sjasm/sjasm.cpp), [devices.cpp](../sjasm/devices.cpp) | Recreated each pass; single-DEVICE global-device heuristic uses preceding pass | Configuration/mapping can itself need settling; not only labels |
| DEFDEVICE definitions: [dirDEFDEVICE](../sjasm/directives.cpp) | Accepted on pass 1; retained until cleanup | Definitions first reached in a later settling branch are not automatically supported |
| Lua VM/global state: [lua_sjasm.cpp](../sjasm/lua_sjasm.cpp) | Persists across all passes | Repeated PASS2/ALLPASS execution is observable and may be non-idempotent |
| Files/stdin: [OpenFile, ReadBufData](../sjasm/sjio.cpp) | Files re-read; stdin recorded once and replayed | Stable-input assumption needs a policy for includes, binaries, Lua I/O, and external changes |
| Errors/warnings: [io_err.cpp](../sjasm/io_err.cpp) | Counts persist; phase-gated messages update predefined counts | Retried provisional failures must not accidentally poison success or affect source forever |
| Outputs/breakpoints/debug files | Mostly final-only, but not universally | Audit each owner; repeated dry traversals are not automatically side-effect-free |

This inventory identifies responsibilities, not a claim that every retained field
should be reset. Some persistence is intentional and affects language semantics.

## Named Symbols: The First Concrete Obstacle

`CLabelTable::Insert()` refreshes an existing ordinary definition when its page is
undefined or `label.updatePass < pass`. `SLabelTableEntry::updatePass` is an
`int8_t`. Repeating logical pass 2 with no generation change therefore bypasses
the normal complete refresh of value, traits, logical/physical pages, and
relocatability. Do not repurpose this narrow field as an unrestricted iteration
counter or wrap it after enough passes.

There is a subtle partial fallback: [ParseLabel](../sjasm/parser.cpp) calls
`Update()` when a pass-2 insertion returns false. This can still change a plain
EQU's value, so a toy extra loop may appear successful. It does not replace full
definition refresh. Structure labels take a different path in
`InsertSingleStructLabel()` and report an early duplicate when insertion fails.
Fixing only the ordinary-label caller would miss those and other insertion sites.

A generation-aware symbol lifecycle must distinguish:

* A previous traversal's definition, available for forward lookup.
* The first definition of that symbol in the current traversal.
* An actual same-traversal duplicate versus a legitimate DEFL reassignment.
* A reference placeholder versus a real definition.
* A definition absent from the newly completed traversal.

Today, absent definitions are not generally removed from the persistent map. A
probe below shows `exist gone` remaining true after its defining branch disappears.
That is existing observable behavior, not a policy to silently change while
adding N-pass support. Options include preserving legacy visibility while tracking
current membership separately, or using previous/current definition sets and
retiring absent definitions at a completed-generation boundary in the new mode.
The latter is cleaner but can expose oscillations hidden by stale symbols.

For example, an existence test that defines a symbol only when it does not exist
can alternate between presence and absence under retirement. Forward fallback
must remain available until the current traversal is complete. Immediate deletion
at the start would destroy ordinary forward references. Keyword reservations and
undefined placeholders also need separate handling.

Preserve current source-order evaluation: a reference may see a fresh definition
earlier in this traversal or a previous-traversal definition later in the source.
A strict previous-only double-buffered evaluator is another possible language
model, but would alter propagation order; it is not merely an implementation
detail of adding snapshots.

## Defining Convergence

### A Bounded Fixed-Point Iteration

For deterministic source and sufficiently captured state, think of a settling
traversal as applying a function to the previous baseline. Accept a result only
after consecutive logical-pass-2 traversals agree. Do not compare discovery with
the first settling traversal as sufficient proof: phase-1/phase-2 source branches
and discovery-only actions can differ deliberately.

```text
run discovery with phase=1
previousSettlingResult = none
repeat up to the configured settling limit:
		advance internal generation
		rebuild traversal-local state
		candidate = run settling with phase=2 and previous baseline
		finish all layout/size/definition bookkeeping
		if candidate agrees with previousSettlingResult and has no blocking issues:
				accept baseline
				break
		previousSettlingResult = candidate
otherwise report non-convergence without starting final emission
run final emission with phase=3 against accepted baseline
check final consistency; report failure on prohibited divergence
```

This straightforward rule requires at least four physical traversals: 1, 2, 2, 3.
The fixed three-pass default can remain separate. A generation increments for
every traversal; a settling limit counts only phase-2 iterations, and its meaning
should be unambiguous in diagnostics. A finite configurable cap comfortably above
20 is appropriate; 64 or 128 are candidate defaults, not decisions.

### What To Compare

Ordinary end-of-pass numeric values are too weak. At minimum assess these
categories when defining the new mode's guarantee:

* Defined-symbol membership, values, page/physical-address metadata, relevant
	traits, relocatability, computed sizes, and the chosen usage-state policy.
* Complete numeric-label sequence: identity/order, values, relocation flags, and
	count, including removed trailing entries and internal DP helper labels.
* Smart-SMC positions/order and resolved offsets; relocation table contents/count.
* Layout effects: instruction/data/reservation lengths, ORG/DISP transitions,
	device/page/MMU state and wrapping where these affect addressing.
* Definition and expression-read events where end-state values conceal different
	intermediate DEFL values, lookup targets, or flow relevant to layout.
* Required unresolved references and deferred failures, separately from equality.

An undefined EQU chain can become numerically stationary at zero while still
containing missing symbols. Equality does not turn unresolved definitions into
success. Conversely, observing every assignment as a change is too strong: a
DEFL variable may reset and count from zero identically every traversal. Compare
corresponding semantic events or completed snapshots, not each mutation against
the immediately preceding mutation within the same traversal.

A lightweight event stream/fingerprint can avoid retaining huge emitted buffers.
It should use stable semantic fields, not pointers, allocation order, generation
timestamps, diagnostic counters, or other incidental identities. Source locations
help explain differences, but source-only identity is insufficient for repeated
macro instances; include stable expansion/occurrence information where needed.
Start with exact comparisons or verify equality after a matching hash; a hash
collision must not justify accepting incorrect assembly.

Branch decisions themselves are not universally equal across logical phases:
`IF __PASS__ == 3` around SAVEBIN is normal final-only behavior. Trace comparison
must normalize phases and focus on settled semantic/layout effects, not demand
identical raw directive visitation between settling and final emission. A stricter
rule for final-only byte emission is a separate compatibility decision.

End address alone is also insufficient: `ORG 0` can hide a changed emitted length.
End label maps cannot observe unnamed output regions. Depending only on a generic
"label changed" bit would miss both cases.

### Cycles, Drift, And Diagnostics

Always have a finite cap. Optional cycle detection can compare a candidate with
earlier settling snapshots and report a period, but only within the captured
state/determinism contract. A repeated partial signature is not proof of a cycle
when a hidden Lua counter or changing input will affect a later iteration.

On failure, report the logical phase, settling count, and a bounded sample of
changing symbols/locations and old/new values. Distinguish oscillation, continued
drift, unresolved references, and a hard source error. Keep enough previous
metadata to name the changed numeric-label occurrence, relocation entry, or
layout event, not merely say "too many passes".

Repeated settling follows the assembler's existing evaluation order; it is not
a constraint solver. The padding equation `padding = (8 - previous_end) & 15`,
with `end = padding`, alternates between 0 and 8 from the ordinary zero seed even
though 4 and 12 are fixed points. More iterations do not find them. Automatically
selecting a different solution, applying damping, or searching layouts would be
a much larger and potentially incompatible feature.

## Numeric Labels, Smart-SMC, And Relocation

The numeric-label refactor is genuinely inspirational here.
`CTemporaryLabelTable::InitPass()` moves the just-collected vector into the previous
baseline. Backward searches use fresh current entries; forward searches use the
previous vector. Current collection can differ from discovery, while final-pass
errors/warnings enforce agreement with the penultimate traversal.

For N-pass, keep rebasing while settling; promote mismatches to another iteration
rather than final-phase errors. Compare the entire finished vector, not only
entries encountered by `InsertRefresh()`: an omitted suffix has no insertion
call to announce its absence. Preserve relocation metadata and DP's negative
internal helper IDs, not just user-written positive numeric labels.

Smart-SMC differs: pass 1 builds `smartSmcLines`; later phases index that original
position sequence and reuse/update resolved offsets. A source location becoming
active only in pass 2 currently produces a mismatch even if pass 3 repeats it.
Adopt a previous/current-record model for settling or deliberately restrict that
case. Do not describe numeric-label flexibility as already applying to smart-SMC.

Relocation already copies `offsets` to `offsetsPrevious` and rebuilds the current
table. `maxTableCount`, early table emission from the previous copy, table content,
and `relocate_count`/`relocate_size` form a dependency loop of their own. Include
them in settling. Audit `alternative_offset`, `areLabelsOffset`, affected-result
flags, and warning state: `InitPass()` is not a blanket reset of every static in
the namespace. Preserve final checks against the accepted preceding table.

## Usage, Sizes, And Devices

IFUSED can benefit directly from extra passes: reverse-ordered routines can expose
one more dependency at a time. `SearchLabel()` marks uses during non-final phases,
and the `used` bits currently persist. This resembles monotone reachability in
simple IFUSED libraries, not a freshly computed per-iteration use set.

Preserving sticky uses is the conservative compatibility option. Recomputing
reachability could remove stale dependencies but changes behavior, especially
with IFNUSED, conditional references, and namespace fallback. Include usage bits
in convergence; do not silently substitute one policy for the other. General
conditional assembly is non-monotone even if a particular IFUSED pattern is not.

SIZEOF mutates symbol sizes at source/block boundaries rather than only when a
label is inserted. Snapshot after those boundaries are finalized and verify no
tracking-stack state leaks across iterations. Structure definitions are rebuilt,
but their size/member symbols participate in the persistent symbol lifecycle.

DEVICE instances are recreated; the global-device detector may change the next
pass's starting device based on the previous pass's directives. Include the
layout-relevant configuration/mapping in stability rather than assuming every
iteration begins with identical device state. DEFDEVICE's discovery-only rule
needs deliberate handling if a definition is first reachable later.

Memory-dependent assembly is a separate limitation. `EmitByteNoListing()` updates
device RAM only in the final phase, and `MemGetByte()` returns zero in earlier
phases. Therefore dry phase-2 repetition does not make memory-dependent layout
converge to final execution. Options are to keep/document this restriction, detect
and reject final layout differences, or introduce a much broader evaluation mode
that simulates memory writes/reads during settling. The latter is not required to
support ordinary address/alignment fixed points and should not be smuggled in.

## Scripting And External State

Lua globals persist intentionally, as demonstrated in the manual. PASS1 runs once,
PASS2 would run on every settling iteration under the proposed phase model,
PASS3 once, and ALLPASS on every traversal. Lua's read-only `sj.pass` must use the
same logical phase as `__PASS__`.

Keeping `__PASS__` at 2 does not make repetition fully transparent: a global
counter increments each time, random/time/file reads can differ, and scripts can
produce assembly or change external files. This is observable without exposing
an iteration define. Arbitrary Lua state cannot be reliably snapshotted/restored
while preserving closures, userdata, open handles, and external side effects.

Maintainer clarification: shared Lua state is an accepted part of the design,
not an unresolved obstacle to N-pass support. Scripts are external participants
expected to cooperate with the logical-stage model. They may observe or count
physical traversals; preventing that is neither necessary nor a goal. The sj
binding and `__PASS__` must still report `1, 2, 2, ..., 3` as appropriate.

PASS2/ALLPASS scripts run on every applicable traversal and are responsible for
repeat-safe assembly effects. A private counter used for logging need not settle;
using that counter to keep changing layout can prevent convergence, which is an
acceptable user-induced failure. The observer should track relevant assembly
effects, not require equality of the Lua heap or every script variable. Preserving
logical phase identity does not promise identical execution counts to three-pass
assembly.

VM restart, rollback, physical-pass concealment, or caching scripts to execute them
only once are outside the intended solution. Restarting changes established
cross-pass state and can repeat initialization side effects; caching can freeze
symbol queries and generated assembly. Neither is needed to uphold the stage
contract. Document script scheduling and retain bounded settling/final checks,
without promising convergence for arbitrary scripted or externally changing input.
The same principle should apply to a future optional JS runtime.

Source files and INCBIN inputs are re-opened, while stdin is replayed from its
initial log. A release design should choose between a stable-input requirement,
change detection, or snapshotting assembly inputs. Snapshotting every external
resource available to scripts is not realistic. Do not promise hermetic assembly
merely because the core input stream is cached.

## Diagnostics And Observable Side Effects

[io_err.cpp](../sjasm/io_err.cpp) distinguishes EARLY, final-only, all-pass, and
startup/final diagnostic types. Counts persist and update `__ERRORS__` and
`__WARNINGS__`. Repeated EARLY warnings can multiply; an early error can remain in
the process exit status after the underlying layout later becomes valid. Warning
state altered through OPT also needs a lifecycle audit beyond syntax-stack reset.

Separate hard errors from provisional settling issues. Never retry fatal I/O,
invalid syntax, duplicates, or missing inputs merely because another iteration is
available. Some risky forward references are intentionally forbidden today;
N-pass support does not automatically legalize them. For retryable phase issues,
options include buffered per-iteration diagnostics, deduplication, or reporting
only the accepted/failing candidate. Define the counts visible to source under
that policy; otherwise source depending on `__ERRORS__` can affect its own layout.
This is a compatibility issue, not just quieter logging.

Most ordinary emission, OUTPUT/SAVE directives, HEX/SLD writes, DISPLAY, and
SHELLEXEC are final-only. Preserve that gating. However:

* BPLIST opens a file in phase 2 for use throughout phase 3. Its source already
	contains an N-pass TODO, and `OpenBreakpointsFile()` rejects a second open.
	A simple extra settling pass therefore needs a lifecycle change even when no
	ordinary binary output occurs. Prefer collecting intended configuration and
	opening from the accepted baseline before final emission; first-iteration
	open-once caching alone can retain a now-inactive filename/configuration.
* Listing files can already be opened before settling. Early diagnostics can be
	printed there even though ordinary listing lines are final-only.
* Lua PASS2/ALLPASS and discovery-only INCLUDELUA can perform unrestricted I/O.
	Extra iterations must not be described as fully transactional.
* LABELSLIST's configuration and DEFDEVICE are discovery-only; CSPECTMAP and many
	other output configurations are final-only. Preserve their intended scheduling
	or separately specify changes, rather than replacing every gate with a number.

Do not start final binary/debug/snapshot emission when settling fails. Once final
emission starts, a mismatch can still be detected after bytes or files were
written. Existing clean-on-error behavior is not a general transaction/rollback
mechanism, and stdout cannot be retracted. Optional temporary-file staging could
improve output integrity but is another scoped feature; external scripts and
SHELLEXEC remain outside such a transaction.

## Final Emission Is Still A Verification Phase

Repeated settling does not justify removing final checks. Phase-selected source,
memory reads, nondeterministic scripts, or changed inputs can still alter phase 3.
Named-symbol drift currently often warns and updates the table rather than failing;
numeric flow changes and structure inconsistencies use different diagnostics.
An opt-in convergence mode should define which final mismatches are hard failures
and retain useful old/new details, while leaving legacy behavior unchanged by
default.

Do not automatically retry after an emitting pass has diverged: output and user
side effects may already exist. In particular, do not call phase 3 a speculative
iteration and rerun it until it happens to agree. Stop with a useful diagnostic.

Final-only file saving is normal. Final-only byte emission is also accepted in
some current cases without intervening labels, as a probe demonstrates. A strict
layout-verification mode would reject that if it requires identical dry/final
layout. Decide and document the new mode's contract instead of imposing a blanket
"every branch and every directive must match" rule that rejects valid output-only
phase guards.

## Characterization Results

Invocation: `./sjasmplus --nologo --color=off --msg=war --raw=- -` with source on
stdin. Captured raw bytes and diagnostics separately. Nonzero exits below are
expected observations, not regressions introduced by this work.

| Case | Current result |
| --- | --- |
| Four-symbol forward EQU chain in reverse dependency order | Byte 00; final value warning and assertion failure |
| 25-symbol reverse EQU chain | Byte 00; still not propagated, assertion failure |
| `flip EQU 1-flip` | Byte 01; final drift warning, exit 0 |
| `drift EQU drift+1` | Byte 03; final drift warning, exit 0 |
| EQU references a never-defined symbol | Byte 00; final missing-label error |
| Numeric label first active in phase 2 through forward IF | Four bytes 01 C3 00 00; success, early forward-reference warning |
| Named label defined only in the initial branch | Definition later absent; `exist gone` remains true and byte 00 assembles |
| Smart-SMC label first active in phase 2 | Bytes 3E 01, but position-mismatch error |
| Lua ALLPASS increments persistent global | Counter/phase trace 1/1, 2/2, 3/3; success |
| Lua emits counter-sized DS, then ORG 0 | Three output bytes, final address zero; no symbol-consistency error |
| Reverse-ordered three-routine IFUSED chain | Nine bytes; final address drift warning, exit 0 |
| `DS (8-finish)&15` before `finish:` | Eight bytes; final address drift warning, exit 0 |
| `growth EQU (growth+1) <? 25` | Byte 03; final drift warning and assertion failure |
| DB guarded by `__PASS__ == 3` | Byte 07; success despite absent dry-pass emission |
| Device byte read controls another DB | Bytes 01 02; final label moves from 1 to 2 with warning |

### Reproducible Small Cases

Finite propagation beyond the current budget:

```asm
aa EQU bb
bb EQU cc
cc EQU dd
dd EQU 1
 db aa
 ASSERT aa == 1
```

An alignment-like oscillation, including the fixed-point-search caveat above:

```asm
 ORG 0
 DS (8-finish)&15
finish:
```

A bounded but slow self-reference (not a recommended source style):

```asm
growth EQU (growth+1) <? 25
 db growth
 ASSERT growth == 25
```

Persistent symbols after an inactive definition:

```asm
 IF gate == 0
gone: db 1
 ENDIF
gate EQU 1
 db gone
 ASSERT exist gone
```

Dry/final memory difference that extra dry iterations do not remove:

```asm
 DEVICE NOSLOT64K
 ORG 0
 db 1
 IF {b 0}
 db 2
 ENDIF
endlabel:
```

### Fixed-Point Models

The Python models used ordered whole-source sweeps for the EQU chain and scalar
recurrences for the other cases, starting after one discovery sweep:

| Model | Result |
| --- | --- |
| 25 symbols, `sym00 EQU sym01` through `sym23 EQU sym24`, then `sym24 EQU 1` | 25 settling sweeps including the unchanged confirmation; 26 dry traversals and one final traversal in the proposed schedule |
| `growth = min(growth+1, 25)`, discovery result 1 | 25 settling sweeps including confirmation |
| `flip = 1-flip` | Period 2 detected after two settling sweeps |
| `padding = (8-padding)&15`, discovery result 8 | Period 2; fixed points 4 and 12 exist but are not reached |
| `drift = drift+1` | Still changes at limit 64, last value 65 |

These establish useful test shapes and show why a cap must allow long finite
propagation. They deliberately do not model lookup placeholders, pages, scripts,
diagnostics, or file side effects. Do not treat these timings as a C++ prototype
benchmark.

## Implementation Options

### A. Fixed Extra Passes

Allow a chosen number of settling traversals, retaining final checks. Useful as
a short-lived developer probe once generation identity is fixed. It does not
detect convergence early, explain cycles, or guarantee that the chosen count is
enough. Repeated state and side-effect issues still apply. Not a complete answer
to the requested adaptive behavior.

### B. Adaptive Whole-Source Settling

Retain source-order evaluation and existing semantic handlers. Add generation
identity, candidate observation, bounded convergence, and final verification.
This is the recommended direction: it supports generated/conditional source
without building a separate static dependency language.

Costs are proportional to source size times settling traversals; scripts,
macro expansion, includes, and large INCBIN length handling need profiling. Keep
the first implementation straightforward before caching. Changes in source
selection and symbol membership must remain visible to the observer.

### C. Separate Previous/Current Symbol Environments

Make definition membership and generation boundaries explicit, while lookup can
still prefer fresh current definitions and fall back to previous ones. Cleaner
for absence detection, snapshot comparison, and late-defined duplicates than
overloading `updatePass` further. More invasive ownership changes: SIZEOF stores
pointers into symbols, lookup returns entry pointers, and macro/module fallback
mutates traits/usage. Preserve pointer lifetimes or redesign those interfaces.

This can complement B rather than replace it. A full previous-only evaluation
model would need separate compatibility justification.

### D. Dependency Graph / Worklist

Track expression dependencies and reevaluate only affected symbols or layout
regions. Promising for pure EQU chains; substantially harder for macro expansion,
text substitution, IFUSED/EXIST, Lua-generated source, include selection, device
mapping, and source-order DEFL. A comprehensive graph would need dependencies on
control flow and effects, not just labels. Not required to get useful N-pass
behavior; consider only after measurements show repeated whole-source cost hurts.

### E. Speculative Emission Or Full Constraint Solving

Simulate final memory during settling, stage every output, or search for stable
layouts outside the normal iteration trajectory. These address broader problems
but expand the semantic and side-effect surface enormously. Arbitrary Lua and
external commands cannot be rolled back generically. Do not couple these goals
to a first implementation of repeated logical pass 2.

## Suggested Staging And Verification

1. Add characterization tests for generation refresh, late/removed symbols, usage,
	 numeric flow/counts, smart-SMC, relocation tables, and final divergence. Keep
	 the legacy default unchanged; record which diagnostics are intentionally weak.
2. Separate logical phase from definition generation across all insertion paths.
	 Establish completed-traversal definition membership and preserve source-order
	 lookup. Test duplicate detection, DEFL resets, STRUCT labels, and generation
	 widths above 127 independently of any public N-pass option.
3. Add a read-only convergence observer to existing passes. Exclude bookkeeping
	 churn and include completed sizes/metadata; explain changes by source location.
	 Observation must not mark extra symbols used or evaluate expressions twice.
4. Prototype an opt-in bounded phase-2 loop; test finite chains requiring 20+
	 iterations, stable sources, cycles, drift, unresolved-zero states, and a clear
	 iteration-limit definition. Rebase numeric/SMC/relocation records deliberately.
5. Resolve diagnostics, BPLIST/open-file scheduling, scripts, absent-definition
	 visibility, and stable-input assumptions before presenting it as production
	 behavior. Keep the final phase single-shot and verify against accepted state.
6. Document logical PASS2/ALLPASS repetition and strict final-layout rules. Run
	 the full feature/example/C++ suite and supported-toolchain builds for runtime
	 changes, not merely the focused baseline used for this notebook.

Use existing test homes and fixtures where suitable:

* [Issue168_temporary_labels_for_all.asm](../tests/parsing/Issue168_temporary_labels_for_all.asm),
	[labels_extra_checks.asm](../tests/parsing/labels_extra_checks.asm),
	[defl_in_pass3.asm](../tests/parsing/defl_in_pass3.asm),
	[smc_label_smart.asm](../tests/parsing/smc_label_smart.asm).
* [ifused_test.asm](../tests/misc/ifused_test.asm),
	[ifused_in_module.asm](../tests/modules/ifused_in_module.asm),
	[forward_reference_errors.asm](../tests/misc/forward_reference_errors.asm).
* [predefined_pass.asm](../tests/define/predefined_pass.asm),
	[sizeof_label.asm](../tests/expressions/sizeof_label.asm),
	[sizeof_tags_sld.asm](../tests/expressions/sizeof_tags_sld.asm).
* [lua_pass.asm](../tests/lua_examples/trivial/lua_pass.asm),
	[relocation_temporary_labels_consistency.asm](../tests/relocate/relocation_temporary_labels_consistency.asm),
	[relocation_issue_with_max_count.asm](../tests/relocate/relocation_issue_with_max_count.asm),
	[relocation_mem_read.asm](../tests/relocate/relocation_mem_read.asm).

Add coverage for zero output side effects on non-convergence, BPLIST reopening,
Lua execution counts, changed input detection policy, page-only/size-only symbol
changes, removed trailing numeric labels, final-phase divergence, and unnamed
layout changes hidden by ORG. Include pipe and device modes. For Makefile builds,
clean after header changes before rebuilding/testing; dependency tracking is
incomplete, especially for the unit-test executable.

## How Close Is It?

The desired driver structure and much of per-pass reconstruction are already
present. Numeric labels and relocation are closer than an architecture built on
fixed first-pass records would be. A limited experimental repeated-settling loop
looks feasible without the parser refactor or a dependency-graph rewrite.

The important missing abstraction is a completed traversal with explicit identity,
defined/referenced state, observable layout effects, provisional diagnostics, and
controlled assembler-owned side effects. Named-label generations, smart-SMC
rebasing, BPLIST, stale definitions, and dry/final memory differences are concrete gaps,
not hypothetical polishing. The production feature is therefore a cross-cutting
change, even if the driver diff is small. It is credible as an independent future
project; it is not yet demonstrated to be a small pre-release enhancement. Shared
Lua lifetime itself is accepted; only its logical-stage scheduling and effect
contract need to remain consistent, not hidden or made transactional.