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

An opt-in rollout preserving the existing three-pass default is this notebook's
conservative recommendation, not settled maintainer policy: issue #63 explicitly
considers making N-pass the default. No command-line syntax, default iteration
limit, version target, or detailed compatibility policy is selected here.
Supporting 20+ settling iterations is reasonable; guaranteeing that arbitrary
programs converge is not. Provide a command-line override for the settling limit;
its syntax and default remain undecided. Keep this independent of the larger
[parser-context refactor](parser-context-research.md).

Maintainer decisions, 2026-11-19: forward ordinary-symbol dependencies, including
those changing conditional source selection, loops, structures, and substitutions,
are intended benefits of N-pass. Preserve accumulated usage rather than pruning
stale uses. Mutable variables require assignment before use within each traversal;
their values must not carry across traversal boundaries. Device declarations and
discovery-only metadata must be resolved during discovery, not postponed through
settling. These decisions refine the research direction, not current behavior.

## Earlier Design Notes: Issue #63

Reviewed [N-pass assembling, issue #63](https://github.com/z00m128/sjasmplus/issues/63)
on 2026-11-04. The issue opened on 2019-08-11; the substantive follow-up design
comments are from 2022-05-12. Its v2.x milestone is historical planning context,
not a release commitment made by this notebook.

The original checklist contributes these architectural intentions:

* Group global state by lifetime across three-pass and N-pass assembly.
* Consider nested assembly contexts and C++ scope-based restoration for includes,
	nesting, and substitution, replacing manual save/restore where appropriate.
	This connects to the parser-context research; it is an architectural direction,
	not proof that the full parser refactor must precede an N-pass prototype.
* Make output-producing work depend on the final phase, not a physical traversal
	number, and explicitly establish that a pre-final baseline has been completed.
	An accepted-baseline state/guard expresses this more reliably than testing that
	some iteration counter has reached a particular number.
* Revisit temporary-label sequences that change inside IFUSED, which was already
	identified as an N-pass compatibility concern. Maintainer clarification on
	2026-11-04: the later numeric-label refactor is considered sufficient for that
	original concern, with no further subsystem work currently identified. The
	unchecked historical item is stale bookkeeping, not evidence of an outstanding
	defect. Use the implementation as a model for other state lifecycles; the wider
	N-pass controller/convergence contract remains separate.

The 2022 refinement is essentially the current proposed model: repeat pass 2,
promoting a nonmatching result to the next baseline; never repeat the emitting
pass 3. Two policy differences from the conservative proposal here must remain
visible:

* The issue allows discovery's result to be the first candidate baseline. A match
	with the first pass 2 could therefore finish in three traversals; typical larger
	projects were expected to need four. This notebook instead proposes two matching
	logical-pass-2 results, giving a four-traversal minimum. Whether a sound
	discovery-to-settling fast path is worthwhile remains a design choice; the issue
	does not specify which state comparison would establish its safety.
* The issue explicitly rejects requiring the old three-pass mode as the default,
	on the basis that `__PASS__` remains 2 during retries. That supports the present
	cooperative-script model: counting traversals externally is possible but does
	not invalidate the design. Keep default adoption separate from any temporary
	opt-in development/rollout strategy.

The issue's estimate of a large build increasing from about 2.5 to 3.0 seconds is
an illustrative expectation, not a benchmark. Measure real projects before using
it as a performance claim.

Most importantly, memory-driven layout is explicitly outside the intended model:
reading final emitted code is useful for checksums and other post-processing,
but code sizes and label values should already be settled before final emission.
If generated code must be read to decide the layout of new code, use separate
assembly stages with intermediate binary files. The dry/final-memory probes below
are therefore scope boundaries and diagnostic cases, not missing capabilities
that N-pass support must implement. Full memory simulation or constraint solving
is not implied by the issue.

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
| Mutable DEFL/`=` symbols | Values currently survive pass boundaries in the named-symbol map | Invalidate values between traversals; preserve assignment-before-use and relevant metadata |
| Usage flags and SIZEOF traits/data | Usage accumulates during non-final passes; SIZEOF tracking pointers are temporary until source boundaries | Preserve accumulated usage; compare completed sizes, not temporary tracking pointers |
| Numeric labels: [CTemporaryLabelTable](../sjasm/tables.cpp) | Previous and current ordered vectors | Strong starting pattern; compare complete sequences before final emission |
| Smart-SMC: [ParseLabel](../sjasm/parser.cpp), [resolveRelocationAndSmartSmc](../sjasm/sjio.cpp) | Positions collected in pass 1; offsets refreshed later | First-pass flow remains an anchor; needs a rebasing policy for adaptive settling |
| Relocation: [Relocation::InitPass](../sjasm/relocate.cpp) | Current offsets copied to previous; table count refreshed, current cleared | Already iterative in shape; compare ordered contents/count and audit persistent flags |
| Devices: [InitPass](../sjasm/sjasm.cpp), [devices.cpp](../sjasm/devices.cpp) | Recreated each pass; single-DEVICE global-device heuristic uses preceding pass | Require discovery-resolved declarations/arguments; still observe layout-relevant page/MMU state |
| DEFDEVICE definitions: [dirDEFDEVICE](../sjasm/directives.cpp) | Accepted on pass 1; retained until cleanup | Keep discovery-only; reject unresolved arguments and definitions first reached later |
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

For ordinary labels and EQU, preserve current source-order evaluation: a reference
may see a fresh definition earlier in this traversal or a previous-traversal
definition later in the source. Mutable variables are the exception below.
A strict previous-only double-buffered evaluator is another possible language
model, but would alter propagation order; it is not merely an implementation
detail of adding snapshots.

### Mutable Variables Are Traversal-Local

DEFL and `=` express ordered assignments, not forward constant definitions. Each
traversal, including final emission, starts with their values undefined. Reads
require a preceding assignment in that traversal; falling back to the previous
traversal's last assignment is forbidden. Use EQU for a value defined later.
EQU remains single-definition within a traversal, while its value may change
between settling traversals.

An assignment RHS may depend on forward ordinary labels/EQU and settle over
multiple traversals. Mutable operands, however, must already have been assigned
in the current traversal. A preceding assignment whose RHS is still unresolved
does not make the expression resolved: retain unresolved-expression information
through assignments and aliases, rather than treating a numeric placeholder as
proof of validity.

```asm
count = finish-start     ; allowed forward ordinary labels
index = 0
index = index+1          ; allowed current-traversal value
copy = laterVariable    ; invalid: no preceding assignment to this variable
laterVariable = 7
```

Invalidating mutable values at a traversal boundary enforces this rule even
after many retries: an unconditional read before assignment stays unresolved,
whereas a forward ordinary-label dependency can eventually resolve. A read in a
branch that disappears before settling need not invalidate the accepted source.
Record unresolved reads even if a later assignment overwrites the same symbol;
end-of-traversal maps alone cannot establish assignment-before-use. Apply this
also to `alias EQU laterVariable` before that variable's assignment: neither a
cached alias value nor an end-of-traversal definition repairs the earlier read.

Physical erasure is not required. Current-generation validity can invalidate the
value while retaining symbol identity, accumulated usage, and diagnostic/type
metadata. `CLabelTable` uses `std::map` and already exposes `Remove`. Insertion
and tree rebalancing preserve pointers to existing entries; erasure invalidates
only pointers to the erased entry. SIZEOF's open-label stack is temporary:
boundaries compute sizes and pop pointers, and tracking is rebuilt each pass.
DEFL/EQU/SMC entries are excluded from tracking. Removing mutable entries, or
previously tracked ordinary entries after tracking has closed, therefore does
not inherently threaten SIZEOF. No SIZEOF ownership redesign is needed for such
pass-boundary removal. If adding general end-of-pass erasure, explicitly drain
any residual tracking first: malformed nesting currently has a defensive flush
before the next source. Preserve usage separately if entries are recreated.
Keep final-traversal values available for symbol/debug dumps until their
consumers finish. Compare mutable assignment/read events for convergence, not
an intentionally emptied post-invalidation map.

This is the intended N-pass policy. The value-lifetime correction is also an
independent candidate for current v1.x three-pass assembly, described below;
it does not require an N-pass controller or a symbol-table redesign.

## Forward Dependencies: Include And Exclude

| Construct | Intended N-pass policy |
| --- | --- |
| Ordinary labels and EQU chains | Allow forward dependencies and propagation up to the configurable settling limit |
| STRUCT initial offset, member sizes/defaults | Lift the unresolved-offset error; rebuild and settle structure symbols/layout |
| DUP/REPT counts | Lift the unresolved-count error; allow expansion and label sequences to change while settling |
| WHILE and IF/IFN/ELSEIF conditions | Lift forward-reference warnings for settling source; allow changes to parsed/assembled lines and layout |
| IFUSED/IFNUSED | Preserve accumulated uses; allow recursive growth, without dead-code pruning |
| DEFARRAY indices and substitutions depending on ordinary labels | Allow delayed substitution and substantial source changes; require eventual stability |
| DEFL/`=` values | No previous-traversal fallback; require preceding assignments to mutable operands |
| DEFDEVICE and DEVICE arguments | Require discovery-time resolution; do not solve declarations through extra passes |
| Discovery-only metadata | Require complete resolution in discovery; preserve its phase boundary |

Unresolved expressions use numeric placeholders, normally zero, during
provisional evaluation; this is not successful resolution. Conditions and loop
controls still unresolved in final emission are treated as zero with hard error
diagnostics on stderr; an unresolved STRUCT initial offset likewise uses zero
and reports an error. For compound conditions, do not let an unresolved operand
accidentally make the condition true through arithmetic on its zero placeholder.
Track unresolved state independently of numeric equality. Stable unresolved
source is invalid, not a reason to spend every remaining iteration repeating the
same failure. Diagnose it by final validation, and always diagnose unresolved
reads encountered in pass 3, including final-only source.

Late source selection can introduce new named/numeric labels and smart-SMC sites;
settling must rebase these records, not forbid the controlling forward reference.
This does not make macro names, STRUCT type names, or DEFINE/DEFARRAY declarations
available before their source-order definitions. That would require a separate
definition-discovery policy. Forward numeric indices into an already defined
DEFARRAY are in scope; forward textual declarations are not implied.

Delayed substitution may temporarily expose malformed assembly and EARLY
warnings/errors even when later traversals produce valid source. Do not ban
forward indices to avoid this. Distinguish such provisional diagnostics where
practical; remaining cases need characterization and an explicit diagnostic
policy, not a promise that every eventually valid generated source is already
handled without early diagnostics. Actual fatal I/O and resource failures remain
hard failures.

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
	traits, relocatability, computed sizes, and accumulated usage bits.
* Complete numeric-label sequence: identity/order, values, relocation flags, and
	count, including removed trailing entries and internal DP helper labels.
* Smart-SMC positions/order and resolved offsets; relocation table contents/count.
* Layout effects: instruction/data/reservation lengths, ORG/DISP transitions,
	device/page/MMU state and wrapping where these affect addressing.
* Definition and expression-read events where end-state values conceal different
	intermediate DEFL values, lookup targets, or flow relevant to layout.
* Required unresolved references and deferred failures, separately from equality,
	including mutable reads before assignment and unresolved assignment dependencies.

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

No additional temporary-label redesign is currently identified. The following
are integration requirements for the N-pass controller/observer, not a claim that
the existing subsystem needs another refactor: retain its previous/current
rebasing, let settling differences request another iteration, and compare the
entire finished sequence. An omitted suffix has no `InsertRefresh()` call to
announce its absence. Observe relocation metadata and DP's negative internal
helper IDs as well as user-written positive numeric labels; keep final-phase
diagnostics tied to the accepted penultimate baseline.

Smart-SMC differs: pass 1 builds `smartSmcLines`; later phases index that original
position sequence and reuse/update resolved offsets. A source location becoming
active only in pass 2 currently produces a mismatch even if pass 3 repeats it.
Adopt a previous/current-record model for settling so these late-active sites can
settle too. Do not describe numeric-label flexibility as already applying to
smart-SMC in the current implementation.

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

Preserving sticky uses is the selected policy. Include usage bits in convergence
so reverse-ordered and recursive usage trees can grow across settling traversals.
Do not recompute reachability or prune stale dependencies when active branches
change. Users must organize source to avoid unwanted retention, particularly
with IFNUSED and conditional references. General conditional assembly remains
non-monotone even though accumulated usage only grows.

SIZEOF mutates symbol sizes at source/block boundaries rather than only when a
label is inserted. Snapshot after those boundaries are finalized and verify no
tracking-stack state leaks across iterations. Structure definitions are rebuilt,
but their size/member symbols participate in the persistent symbol lifecycle.

DEVICE instances are recreated; the global-device detector may change the next
pass's starting device based on discovery's directives. Dry passes track device
mapping and addresses, including INCBIN page stepping, without backing RAM.
Only final emission allocates and initializes RAM. Require DEFDEVICE declarations and DEVICE
selection/arguments to be resolved during discovery. Do not support declarations
first made meaningful by later settling; diagnose them instead. This does not
require DEVICE to appear only once or forbid existing source-order device
switching. Continue observing page/MMU mapping and addressing effects for layout
stability; the discovery-time rule is not a blanket ban on settling expressions
used by memory-mapping directives.

Memory-dependent layout is an accepted scope boundary, as clarified in issue #63.
`EmitByteNoListing()` updates
device RAM only in the final phase, and `MemGetByte()` returns zero in earlier
phases. Therefore dry phase-2 repetition does not make memory-dependent layout
converge to final execution. Preserve the requirement that layout is settled before
emission and diagnose prohibited final differences. Final-memory reads for checksums
or post-processing remain useful; layout depending on generated bytes belongs in
separate assembly stages. Simulating memory writes/reads during settling would be
a broader feature outside the intended N-pass work, not a prerequisite.

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

Separate hard errors from provisional settling issues. Never retry fatal I/O or
resource failures merely because another iteration is available. Syntax,
duplicate-definition, and missing-input diagnostics from an otherwise valid,
settled source remain errors; delayed substitutions or changing source selection
can expose provisional forms that need separate treatment. Lift the explicit
forward-reference restrictions/warnings listed above, rather than preserving them
as protection against layout changes. For retryable phase issues,
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
* Discovery-only configuration must be resolved in discovery; do not move it
	into settling merely to allow forward dependencies. The inventory below
	distinguishes it from later-phase output configuration.

### Discovery-Only And Related Metadata Review

Source inspection on 2026-11-19 identifies these explicit discovery-only paths;
not every output directive is discovery-only, nor does the current code always
diagnose unresolved numeric arguments at that boundary.

| Path | Current scheduling and reason visible in code | N-pass treatment |
| --- | --- | --- |
| LABELSLIST filename and virtual-label option | `dirLABELSLIST` records options only in pass 1; filenames go into output configuration | Keep discovery-only; unresolved option expressions must error there, not silently freeze zero |
| DEFDEVICE | Defines persistent device geometry/initial mapping only in pass 1 | Keep discovery-only; require fully resolved arguments |
| DEVICE | Runs in all passes; discovery drives global-device detection; only the final pass allocates RAM | Preserve execution/recreation and discovery-resolved arguments |
| SLDOPT COMMENT keywords | `SldAddCommentKeyword` collects keywords only in pass 1 | Preserve discovery-time collection; no numeric forward lookup involved; SWAPON/SWAPOFF are not discovery-only |
| INCLUDELUA | Loads/executes the file only in pass 1, sharing the persistent VM | Keep scheduling; file selection must be ready then, not discovered through retries |
| LUA PASS1 | Explicit user-selected discovery execution, not output metadata | Run once; do not replay to satisfy later forward dependencies |

Related paths to avoid misclassifying: BPLIST currently opens in pass 2 and needs
the accepted-baseline lifecycle described above; CSPECTMAP is final-only; EXPORT
can establish a default filename during parsing and `InitPass` opens the export
file on entry to final emission. Listing files may open before the pass loop or
on first source open, and SLD opens before final `InitPass`. These are distinct
owners, not evidence that all filenames require a pass-1 directive. Preserve
existing scheduling unless a particular owner needs an N-pass lifecycle fix.

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
pointers only while tracking open labels, lookup returns entry pointers, and
macro/module fallback mutates traits/usage. Keeping stable map entries or retiring
them after tracking closes is compatible with SIZEOF as implemented. Replacing
the owning map while pointers are live would require managing those lifetimes;
that is a property of the proposed replacement, not a current pointer-stability
defect or a prerequisite refactor.

This can complement B rather than replace it. A full previous-only evaluation
model would need separate compatibility justification.

The temporary-label pattern is worth prototyping for other traversal-owned
results: rebuild current definitions in source order and consult an optional
previous result for forward references. Discovery can use the same path with no
previous result, while remaining a distinct phase for tasks such as collecting
global DEVICE usage. Preserve sticky usage and assembly-owned state separately;
in particular, previous mutable values are not a forward-reference oracle.

Keeping two traversal results and moving or swapping the completed result into
the previous slot can avoid deep copies. It does not avoid rebuilding entries or
the cost of keeping two sets live; measure both against the in-place approach.
Only rotate after consumers of borrowed entries have finished. Equality can be
expressed as `current.layout == previous.layout` if `layout` is a completed,
semantic convergence result. Do not compare the entire working context, which
can include generation IDs, scratch state, and handles unrelated to settling.
This is a design option to explore early, not a decision to replace the table.

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

## Independent Work For Current Sjasmplus

The maintainer prefers shipping behavior-preserving refactors
in one or more v1.24.x maintenance releases before adding N-pass. This is a
sequencing preference, not a fixed release schedule or a reason to bundle
behavior changes with refactors.

### Reset Mutable Values Between Existing Passes

Make DEFL/`=` values undefined at the beginning of each pass, including pass 3,
so reading a mutable symbol before its current-pass assignment produces an
undefined-symbol error rather than consuming the preceding pass's final value.
Keep same-pass ordered reassignment and forward ordinary-label/EQU dependencies
on assignment RHSs. This is a value-visibility correction, not N-pass convergence
machinery. Start with the existing table and a small invalidation/removal API;
do not make a general table rewrite a prerequisite.

Preserve accumulated usage and symbol-kind information where needed. Distinguish
an invalidated entry from a real definition and permit the subsequent assignment
to define it normally. If erasing entries instead, retain any required metadata
separately. SIZEOF excludes mutable entries and does not obstruct this work.
Reset at pass entry, or equivalently between traversals, without deleting final
values before symbol/debug dumps. A direct read-before-assignment error must not
disappear merely because a later assignment overwrites that variable.

Verify initialized counters/reassignments, direct and aliased forward mutable
reads, mutable-to-mutable assignment RHSs, ordinary forward EQU/address RHSs,
pass-selected assignments, usage flags, and final symbol exports. Review existing
tests/examples for intentional cross-pass mutable state and document the behavior
change: use EQU for forward constants or explicit Lua state for deliberate
cross-pass scripting. Full unresolved-expression propagation remains part of
the broader N-pass diagnostic work, not a prerequisite for rejecting direct
forward mutable reads in the current assembler.

## Suggested Staging And Verification

1. Add characterization tests for generation refresh, late/removed symbols, usage,
	 numeric flow/counts, smart-SMC, relocation tables, and final divergence. Keep
	 the legacy default unchanged; record which diagnostics are intentionally weak.
2. Separate logical phase from definition generation across all insertion paths.
	 Establish completed-traversal definition membership and preserve source-order
	 ordinary-label lookup, with traversal-local mutable values. Test duplicate
	 detection, assignment-before-use, STRUCT labels, and generation
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
layout changes hidden by ORG. In particular, cover the selected forward policy:

* Forward STRUCT offsets/member sizes, DUP/REPT counts, WHILE and conditional
	conditions that change expansion/layout and eventually settle without fwdref
	diagnostics; missing symbols must still fail with final diagnostics.
* DEFARRAY forward indices changing instructions, definitions, and selected
	inputs, including provisional malformed text/EARLY diagnostics and non-convergence.
* Reverse/recursive IFUSED growth and deliberate retention of stale uses; no
	implicit pruning when branches change.
* Mutable assignment-before-use in every traversal, including pass 3; reject
	forward mutable reads even when their previous-pass value would be stable.
	Allow assignment RHSs with forward ordinary EQU/address dependencies; retain
	unresolved dependency status through aliases and overwritten assignments.
* Current-traversal mutable reset/count loops, retained usage metadata, and final
	symbol dumps after value invalidation is introduced. If general symbol retirement
	is added, verify SIZEOF tracking is closed before erasure, including malformed
	nesting recovery; ordinary map growth needs no pointer-stability fix.
* Discovery-only unresolved metadata/device arguments and declarations reached
	only later must fail; ordinary device switching/global-device initialization
	and page/MMU settling must continue to work.

Include pipe and device modes. For Makefile builds,
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
rebasing, BPLIST, stale definitions, and final consistency diagnostics are concrete gaps,
not hypothetical polishing. The production feature is therefore a cross-cutting
change, even if the driver diff is small. It is credible as an independent future
project; it is not yet demonstrated to be a small pre-release enhancement. Shared
Lua lifetime itself is accepted; only its logical-stage scheduling and effect
contract need to remain consistent, not hidden or made transactional. Likewise,
support for memory-driven layout is outside scope rather than a readiness gap.