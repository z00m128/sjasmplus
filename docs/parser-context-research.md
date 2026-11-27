# Parser Context Research

Research notebook, 2026-11-02. This is not a syntax specification or a selected
implementation plan. The manual remains authoritative for supported syntax.

## Conclusions

The hunch is substantially correct: there are multiple partial source parsers,
not multiple independent expression or instruction grammars. The duplication is
mainly in source traversal, block recognition, and decisions about when to
substitute or interpret text. A common structural scanner and context-aware body
dispatch look worthwhile. A single unrestricted directive parser does not.

* #416 is reproducible in both active and inactive conditional branches. Similar
	raw-text termination problems are reproducible in repeat, macro, and structure
	collection. These are related ownership/ordering problems.
* `ParseDirective_REPT()` has a necessary purpose today: recognize repeat nesting
	while storing everything else unevaluated. Removing the function is not itself
	the useful simplification; sharing recognition without executing unrelated
	directives is.
* STRUCT conditionals need the conditional controller to preserve the enclosing
	body parser. Sharing keyword recognition alone will not provide that feature.
* The recommended direction is incremental: characterize behavior, separate
	structural scanning from substitution, then make active-body dispatch explicit.
	An explicit context stack is a possible later step, not a prerequisite.
* Do not promise that conditionals, macros, repeats, and Lua can all be freely
	composed. Some combinations need language decisions as well as implementation.

## Evidence And Scope

Inspected the current source, relevant manual chapters, existing feature tests,
the history of the repeat dispatcher, and the original
[#416 report](https://github.com/z00m128/sjasmplus/issues/416). The report describes
v1.24.0 on Windows; the findings below were also reproduced locally on Linux.

Built with `make -j8`. Small probes were supplied on stdin to
`./sjasmplus --nologo --color=off --msg=err -`, using Python's `subprocess.run`
with a five-second timeout per invocation. No parser code or test fixtures were
changed. This notebook records experiments, not permanent regression coverage.

Existing baseline, run sequentially with `make -j8 test TEST=<prefix>`:

| Prefix | Tests | Checks | Result |
| --- | ---: | ---: | --- |
| `parsing` | 54 | 67 | Pass |
| `misc` | 78 | 116 | Pass |
| `sjasmplus_regressions` | 20 | 29 | Pass |
| `lua_examples` | 34 | 38 | Pass |
| Total | 186 | 250 | Pass |

These passing suites do not disprove the bugs below. They establish useful
existing behavior and show that the small probes cover gaps in that baseline.
The full suite, other toolchains, and device-mode variants were not run.

## Current Control Flow

The important distinction is between acquiring text and interpreting it. Much of
the apparent parser complexity is actually recursive ownership of the source
cursor, global buffers, and listing state.

```text
OpenFile
	ReadBufLine(Parse=true)
		ParseLine
			PrepareLine
				[collecting repeat? store raw line, recognize repeat nesting, return]
				ReplaceDefine
			ParseLabel
			ParseMacro              [macro invocation or structure instantiation]
			ParseInstruction
				ParseDirective
				Z80::GetOpCode

IF-family directive -> dirIfInternal
	active:   ReadFile -> ReadLine -> raw terminator check -> ParseLineSafe
	inactive: SkipFile -> ReadLine -> raw IF nesting / terminator / LUA checks

MACRO -> CMacroTable::Add -> ReadFileToCStringsList -> ReadLineNoMacro
invoke macro -> CMacroTable::Emit -> stored lines -> ParseLineSafe

DUP/REPT/WHILE -> set up RepeatStack; subsequent PrepareLine calls collect
EDUP/ENDR/ENDW -> dirEDUP -> stored lines -> ParseLineSafe

STRUCT -> dirSTRUCT -> ReadLine -> raw ENDS check -> ParseStructLine
LUA    -> dirLUA    -> ReadLine(false) -> raw ENDLUA check -> Lua interpreter
```

`ParseLineSafe()` preserves the two substitution scratch buffers and `lp` around
recursive assembly. It is not a general save/restore of parser context.
`ReadLine()` chooses stored macro/repeat lines while `lijst` is active, otherwise
file input. `ReadLineNoMacro()` deliberately bypasses that choice.

### Inventory Of Source Consumers

Links identify owning implementations, rather than unstable line numbers.

| Mode / owner | Acquisition and recognition | Interpretation / special behavior |
| --- | --- | --- |
| Normal file, include, stdin: [OpenFile, ReadBufLine](../sjasm/sjio.cpp) | File buffering; logical lines/colon segments | Ordinary line parser; stdin logged for later passes; include saves/restores input state |
| Ordinary active line: [PrepareLine, ParseLine](../sjasm/parser.cpp) | Receives one logical line | Substitution, labels, macro/structure invocation, directives, CPU instructions; repeat capture takes priority |
| Active IF branch: [ReadFile](../sjasm/sjio.cpp) | `ReadLine()`; raw ELSE/ELSEIF/ENDIF check before normal parsing | Recurses into normal parsing; bypasses terminator recognition while a repeat body is being collected |
| Inactive IF branch: [SkipFile](../sjasm/sjio.cpp) | `ReadLine()`; IF-family nesting counter; raw ELSE/ELSEIF/ENDIF | No ordinary substitution or expression evaluation; special nested loop skips LUA bodies |
| Macro definition: [CMacroTable::Add](../sjasm/tables.cpp), [ReadFileToCStringsList](../sjasm/sjio.cpp) | File-only reader; optional-dot ENDM check | Stores raw lines with positions, without body substitution; toggles colon splitting around detected LUA/ENDLUA |
| Macro expansion: [CMacroTable::Emit](../sjasm/tables.cpp) | Stored lines, no fresh file-level splitting | Installs macro arguments/local-label namespace, restores caller state; invokes ordinary parser |
| Repeat collection: [PrepareLine](../sjasm/parser.cpp), [ParseDirective_REPT](../sjasm/directives.cpp) | Stores raw lines; skips possible label; restricted directive table | Only repeat open/close nesting is acted on; nested counts/conditions deferred |
| Repeat replay: [dirEDUP, shouldRepeat](../sjasm/directives.cpp) | Stored lines via `lijstp`; nested consumers also use `ReadLine()` | Ordinary parser; optional index label; WHILE expression/guardian checked per iteration |
| Dot repeater: [ParseDirective](../sjasm/directives.cpp) | Copies remainder of current logical line | Re-enters `ParseLineSafe()` N times; not a multiline collector and not a repeat nesting opener |
| Structure definition: [dirSTRUCT](../sjasm/directives.cpp), [ParseStructLine](../sjasm/parser.cpp) | `ReadLine()`; raw optional-dot ENDS check | Substitutes active member lines; separate member-label grammar and member dispatcher; no ordinary conditionals/macros |
| Structure member/init continuation: [GetStructText](../sjasm/reader.cpp), [CopyMembers, emitmembs](../sjasm/tables.cpp) | `PrepareNonBlankMultiLine()` can consume more logical lines inside braces | Calls `PrepareLine()`, not full statement parsing; owns continuation grammar until closing brace |
| Inline Lua: [dirLUA](../sjasm/lua_sjasm.cpp) | `ReadLine(false)` disables file colon splitting; bare ENDLUA check | Collects foreign-language text, executes on selected passes; no ordinary body substitution |
| Lua in skipped conditional: [SkipFile](../sjasm/sjio.cpp) | Extra read loop until bare ENDLUA | Avoids interpreting Lua IF/ELSE as assembly nesting, but uses default `ReadLine()` colon policy |
| Lua-generated assembly: [parse_line](../sjasm/lua_sjasm.cpp) | Injects text directly into `line`, without file reader | `sj.parse_line` / `_pl` parse labels; `sj.parse_code` / `_pc` disable labels; normal parser otherwise |
| Lua expression calculation: [lua_sj_calc](../sjasm/lua_sjasm.cpp) | Direct substitution and expression parsing | Explicitly isolates/restores `comlin` and scratch buffers; no statement/block traversal |
| Included Lua: [dirINCLUDELUA](../sjasm/lua_sjasm.cpp) | Lua loads a separate file directly | Runs on pass 1; outside the assembly line/block parser |

The normal directive dispatcher, CPU dispatcher, and STRUCT member dispatcher are
different semantic grammars. Expression parsing is substantially shared already.
Do not count every expression helper as another source-context parser.

### Differences Hidden Behind Similar Names

* `getinstr()` recognizes a mnemonic, rejects a trailing colon (a label), and
	normalizes case with `--syntax=i`. Directive tables register lowercase and
	uppercase spellings, with and without a dot.
* `cmphstr()` advances its pointer on success and checks token termination. It
	accepts all-lowercase or all-uppercase words, not mixed case, independently of
	`--syntax=i`. Whitespace and comment starts are valid token boundaries; a colon
	is not. Most raw block scanners use it directly.
* Active IF terminators are tested at first nonblank position, with optional dot,
	regardless of `--dirbol`. `SkipFile()` also skips a leading label when `--dirbol`
	is off, using a different predicate from repeat collection. The existing
	`Issue138_if_vs_label` test documents remaining numeric-label limitations.
* Macro collection and STRUCT termination accept an optional dot. Inline and
	skipped Lua termination check bare ENDLUA. Macro collection's LUA colon-policy
	toggle also accepts the optional dot because its pointer was advanced earlier.
* Ordinary macro invocation can shadow directives; `@` inhibits expansion.
	Raw terminator recognition does not run macro lookup first. A shared dispatcher
	must not silently change this precedence.
* Substitution can produce an opening IF parsed by the ordinary dispatcher, but
	a generated ENDIF is not a terminator for `ReadFile()` (confirmed below).
	Unifying recognition after expansion would therefore change existing behavior.

## Why Comments Are Difficult Here

There are two distinct nested-comment counters:

1. `blockComment`, private to [sjio.cpp](../sjasm/sjio.cpp), advances while the file
	 reader copies source. It prevents colon splitting and label handling inside
	 comments. Comment text is preserved, not removed. Quotes and single-line
	 comments affect how this reader scans. It resets when opening a file.
2. `comlin`, used by [ReplaceDefineInternal](../sjasm/parser.cpp), advances when
	 a line is substituted. That function removes comments as well as expanding
	 macro arguments/DEFINE/DEFARRAY and handling glue. It can rescan generated
	 text through multiple substitution iterations.

These counters operate on different streams at different times. Macro/repeat
capture advances the file reader without ordinarily advancing substitution;
replay substitutes stored lines without passing through the file reader again.
Inactive branches mostly do neither substitution nor `comlin` maintenance.

`ReadFile()` recognizes a closing conditional before filtering its line through
substitution, even if an earlier active line already opened `comlin`. `SkipFile()`
recognizes conditional nesting on raw text and never filters ordinary skipped
lines at all. A keyword after `;` or `//` is not at the scanned position, so it is
ignored; a keyword at the beginning of a later line inside `/* ... */` can match.
This explains #416 without assuming a conditional-expression defect.

Simply checking `comlin` cannot repair the skipped path or raw collectors. Simply
checking the file reader's final `blockComment` cannot identify live text before
an opener or after a closer on the same line, and does not cover stored replay.
A useful scanner needs incoming lexical state and live spans/events, not just
the outgoing comment depth.

Nor is `ReplaceDefine()` a safe universal lexer. Calling it while skipping can
evaluate DEFARRAY indices and report errors from deliberately invalid source;
calling it while capturing can freeze values needed at expansion time. Advancing
the existing comment counter twice could also consume comment delimiters twice.

Lua adds another boundary: `ReadLine(false)` disables colon splitting, not the
file reader's assembly-oriented quote/comment handling. Lua strings/comments must
not acquire assembly meaning merely because an enclosing block is being scanned.
Full correctness for markers inside Lua long strings/comments would require a
defined sentinel rule or Lua-aware lexical treatment, not another assembly flag.

## Experiments

The initial 21 probes used the rebuilt release executable. Exit 0 means the included
address/size assertions passed where present; exit 1 means assembler errors, not
a crash. These are observations of current behavior, not all desired semantics.

| Probe | Observed result |
| --- | --- |
| Active `IF 1`, block-comment line `else`, then real ELSE | Error: one ELSE only expected |
| Inactive `IF 0`, block-comment prose starting `if` / `else` | Error: No ENDIF |
| Same conditional keywords after `;` and `//` | Pass; only active byte counted |
| IF/ELSE/ENDIF inside STRUCT | STRUCT Unexpected errors; both members added, size assertion fails |
| ENDR on a line inside a comment in DUP body | Premature repeat end; real EDUP reports end without repeat |
| ENDM on a line inside a comment in macro body | Premature macro end; subsequent real ENDM errors |
| ENDS on a line inside a comment in STRUCT body | Premature structure end; subsequent real ENDS errors |
| Macro `repeatX` emits one byte; `DUP 2` contains ` .34 repeatX` | Pass; address 68 |
| `DUP 0` body contains indented END | Pass; following byte assembled |
| Beginning-of-line END with `OPT --dirbol` | Pass; treated as label, following byte assembled |
| Inactive branch contains nonsense and nested `IF unknown / 0` | Pass; no inactive-expression errors |
| Inactive branch contains macro text with balanced IF/ENDIF | Pass; skipped scanner counts IFs without collecting macro |
| Active IF, commented ENDIF, then real ELSE/ENDIF | Stray ELSE/ENDIF and final address assertion errors |
| Active IF, live ENDIF after `/* hidden */` on same line | Stray ENDIF followed by No ENDIF |
| Inactive IF with `Else` / `Endif` and `--syntax=i` | No ENDIF; raw scanner bypasses case option |
| Inactive IF contains Lua `if ... else ... end` | Pass; special Lua skip loop shields it |
| Repeat body contains ENDR line in Lua long string | Premature repeat end; Lua and unmatched-terminator errors |
| Macro body contains ENDM line in Lua long string | Premature macro end; Lua and unmatched-terminator errors |
| DEFINE produces ENDIF inside active IF | Stray ENDIF followed by No ENDIF |
| DEFINE produces BYTE inside STRUCT | Pass; size 1, assembly address unchanged |
| Outer `DUP 2, idx`, nested `DUP idx+1` | Pass; address 3, proving nested evaluation is deferred |

The old `.34 repeatX` / END note is not a reproduced bug in the forms above.
These probes are not exhaustive proof that either construct is safe in every
context. END-at-column-zero is also explicitly documented and already tested.

### Small Reproducers

For each snippet, use the stdin command above. The first currently produces
`[IF] one ELSE only expected`; correct assembly should reach address 1.

```asm
 IF 1
 db 1
 /*
 else
 */
 ELSE
 db 2
 ENDIF
 ASSERT $ == 1
```

The skipped-path version currently reports `[IF] No ENDIF`:

```asm
 IF 0
 /*
 if prose
 else prose
 */
 db 9
 ELSE
 db 2
 ENDIF
 ASSERT $ == 1
```

To reproduce the other collectors, put an ENDR, ENDM, or ENDS line between
`/*` and `*/` inside its respective block, followed by a live member/instruction
and the real closing directive. Each collector recognizes the commented marker.

This valid deferred-repeat example is a useful protection against eager parsing:

```asm
 DUP 2, idx
 DUP idx+1
 db 1
 EDUP
 EDUP
 ASSERT $ == 3
```

STRUCT conditionals are a proposed extension, not currently documented syntax:

```asm
 STRUCT S
 IF 1
x BYTE 1
 ELSE
y WORD 2
 ENDIF
 ENDS
 ASSERT S == 1
 ASSERT $ == 0
```

## Why The Repeat-Only Dispatcher Exists

`DirectivesTable_dup` contains DUP, REPT, WHILE, EDUP, ENDR, ENDW, and deprecated
ENDM, including their dotted/case variants. `PrepareLine()` stores the original
line first, then uses that table while `RepeatStack.top().IsInWork` is false.

Nested openers increment `Level` without evaluating their arguments. A closer
decrements nesting or starts replay of the completed outer block. Only replay
runs substitutions and ordinary assembly. A nested count can therefore depend on
the outer iteration index, or definitions changed during preceding replayed lines.
WHILE has its own saved expression and iteration guardian.

Replacing this call with unrestricted `ParseDirective()` would execute unrelated
directives during capture, potentially emit bytes, start a macro/Lua collector,
stop assembly with END, or expand the dot repeater before replay. A shared table
with classified, non-executing lookup could replace the separate table; invoking
the existing full dispatcher cannot.

History gives two useful boundaries:

* `491a63a` already has `ParseDirective_REPT()` in the imported source. Its original
	design rationale is not recoverable from that commit alone.
* `6621e4a` (2022-08-30, fix #192) added label skipping and the `--dirbol` branch
	around repeat-only dispatch, with `nested_dup_with_label` regression coverage.
	That is demonstrated compatibility behavior, not redundant code to remove.

`dirElseCheckLiveDup()` also explicitly rejects conditionals that cross a repeat
boundary, and stops replay to recover. This agrees with the intended clean-nesting
principle below; a new block stack must not accidentally accept cross-block
closures.

## Maintainer Guidance

Clarifications from discussion on 2026-11-02. These are intended design principles
for this research, not claims that the manual already formally specifies them or
that the current implementation consistently enforces them.

### Clean Hierarchical Nesting

Blocks of different types should nest without crossing. A STRUCT opened inside a
conditional branch must close in that same branch. A conditional selecting STRUCT
members must end before ENDS; likewise, a conditional inside a repeat must close
before the repeat does. Closing an enclosing block from inside an unfinished
inner block is not a feature to support, even if a particular execution path could
be made to work. A branch-local opener cannot be paired with a closer in another
branch. This principle applies broadly to the assembly block constructs, not only
STRUCT and repeats.

Lua inside a macro fits this hierarchy: ENDLUA precedes ENDM. Input origin and
execution/capture policy remain separate implementation concerns; clean nesting
does not imply eagerly parsing deferred bodies or rejecting arbitrary inactive
instruction text. Includes and expansion-source boundaries still need their own
source-lifetime rules; this principle is not a new blanket per-file restriction.

Prefer diagnostics identifying the unexpected closer, the still-open inner block,
and its opener location. Detect violations at the owning boundary rather than
letting an inner reader consume unrelated caller source and eventually report a
misleading missing terminator. This is a target diagnostic contract, not current
behavior demonstrated for every construct.

### Practical Mixed-Language Limits

Ordinary reasonable use, including Lua inside macros, should work without obscure
traps. A fully compatible combined assembly/Lua parser that understands every
string, comment, generated marker, and adversarial combination is not a goal in
itself. Limited, predictable sentinel rules are acceptable; meaningful diagnostics
are preferable when users accidentally encounter a limit. Intentionally ambiguous
or pathological constructions do not justify disproportionate parser machinery.
Do not treat every Lua long-string marker probe in this notebook as a commitment
to support it through a full Lua-aware lexer.

### Optional JavaScript And Opaque Script Blocks

A possible optional JavaScript engine is an architectural consideration, not a
committed feature or a runtime-selection task. Some users are fluent in JS rather
than Lua; Lua-like assembly automation through JS could make scripting more
accessible. Parser improvements should make adding such an engine easier, without
requiring another collection of language-specific assembly scanning loops.

The intended model is simple: recognize a script opener, collect text until its
reserved end-marker line, then pass the payload to the selected runtime when
execution is appropriate. The assembler owns the envelope, source attribution,
and execution policy; the runtime owns the script grammar and syntax errors.
No fully hybrid assembly/Lua/JS parser is an aspiration of this work.

The shared mechanism should support these properties:

* Enter opaque-text handling before assembly lexical transformations. Preserve
	physical script lines, colons, quotes, comments, and whitespace; do not perform
	assembly substitution or backslash line continuation on the payload. This is a
	target contract, not a description of today's `ReadBufLine(false)` behavior.
* Recognize the envelope consistently during execution, inactive-branch skipping,
	macro/repeat capture, and replay. Enclosing collectors must not interpret IF,
	ENDM, or ENDR inside the payload as assembly structure. Capturing or skipping
	does not run the script or freeze expansion-time state.
* Describe script envelopes independently of runtime implementation: opener,
	closer, directive spelling policy, and payload handling. An eventual engine
	should supply execution/bindings, not another assembly block scanner. No new
	JS directive names, engine dependency, or public API are selected here.
* Keep envelope recognition separable from engine initialization. A future design
	can then skip a disabled engine's block without loading it and issue a clear
	unsupported-engine diagnostic if execution is requested. Exact disabled-build
	behavior and pass-selection syntax remain feature-design decisions.

JavaScript illustrates why assembly lexical rules must not leak into payloads:
template literals can span lines and contain interpolation, regular-expression
literals contain syntax unlike assembly strings, colons are ordinary language
syntax, and semicolons are not comments. Lua has its own different long-string and
comment rules. These are reasons to preserve opaque text, not to implement either
language's lexer in sjasmplus.

Define the sentinel contract precisely when implementing this: where a marker
may occur on a line, permitted trailing text, case and leading-dot equivalence,
and what users must avoid or how they can escape a collision. A marker-shaped
line inside a multiline script literal can still terminate a text-only collector.
Clean nesting does not remove that ambiguity; reserving the marker is an accepted
practical limitation. A configurable delimiter or escape could be considered if
ordinary use demonstrates a need, not introduced speculatively.

Likewise, while in opaque text, an apparent enclosing closer cannot reliably be
diagnosed as a nesting mistake rather than valid script content. Missing-sentinel
diagnostics should identify the script opener and source boundary; stronger
diagnostics are best effort and must not require parsing the foreign language.
Exercise the shared collector with script-like text even without a JS runtime,
including template literals, regex-like text, colons, assembly-looking keywords,
and sentinel collisions under the documented contract.

### Dotted Directive Equivalence

In ordinary directive positions, a directive's bare and leading-dot forms should
behave equivalently, including block terminators recognized by special collectors.
Missing dot support there is a bug candidate, not an intentional context policy.
This does not turn a label position into a directive position or override the
normal indentation/`--dirbol` rules.

The known deliberate exception is END/.END at the beginning of a line, even with
`--dirbol`: preserve its label interpretation, particularly for the popular local
label `.end`. Do not generalize that exception to unrelated closing directives.

Code inspection and follow-up probes confirm a small current-fix candidate:
`dirLUA()` and the Lua loop inside `SkipFile()` recognize bare ENDLUA but not
`.ENDLUA`. Macro collection's
colon-policy toggle already allows either form, making the paths inconsistent.
Ten follow-up stdin probes compared the two spellings in direct PASS3 execution,
non-executing Lua passes, an inactive conditional branch, macro replay, and repeat
replay. Bare ENDLUA passed all five; `.ENDLUA` failed all five. Direct/replayed
cases reported an unexpected end of Lua and Lua syntax errors; inactive paths
swallowed the enclosing conditional terminator and reported No ENDIF.

A minimal reproducer is `LUA PASS3`, `local value = 1`, `.ENDLUA`, each on its
own indented line. Replacing `.ENDLUA` with ENDLUA makes it assemble successfully.
Turn these comparisons into focused regression fixtures before fixing the two
consumers. In `dirLUA()`, changing
recognition also requires excluding the leading dot from collected Lua text:
its current `lineLen` calculation subtracts only the six letters of ENDLUA.
Merely advancing past the dot before `cmphstr()` would leave a stray dot in the
script. This is separable from the larger refactor and from #416's comment fix.

## Issue #120: INCLUDE During Macro Expansion

Follow-up research, 2026-11-19, on
[#120](https://github.com/z00m128/sjasmplus/issues/120). The title mentions Lua
and modules, but the author's September 2021 clarification isolates the remaining
use case: a macro includes unchanged third-party assembly, whose ordinary `.local`
labels should retain their normal main-label scope instead of becoming
macro-instance labels. INCLUDE already executes during expansion; the missing
feature is not collecting or executing the INCLUDE directive itself.

### History And Disposition

* The August 2020 discussion proposed adding module/main-label components to
	macro-local names, or separating ordinary and macro-local label syntax. Current
	`ValidateLabel()` still builds ordinary macro-local definitions from
	`macrolabp + ">" + name`, without those components. The proposed naming change
	was not implemented merely by fixing later module lookup bugs.
* [#84](https://github.com/z00m128/sjasmplus/issues/84) was closed by
	[`903d430`](https://github.com/z00m128/sjasmplus/commit/903d430f311971d65daee61db97758515f6e3737)
	(2021-07-19): `@.label` explicitly defines an ordinary local label inside a
	macro, following sjasm 0.42 syntax. The March 2021 suggestion involving `!`
	is not the implemented spelling. See
	[local_labels.asm](../tests/macros/local_labels.asm). This helps editable macro
	source, not an arbitrary unmodified include.
* In September 2021 the author distinguished changing INCLUDE implicitly from an
	explicit mode switch before INCLUDE. The maintainer was reluctant to change
	INCLUDE implicitly, but left the explicit switch open. In March 2022 it was
	deferred because switching label behavior was too entangled with the internals.
* The August 2024 request to document the limitation has been completed:
	[`e05471a`](https://github.com/z00m128/sjasmplus/commit/e05471a34173c5ee832387d577db4ceead088da2)
	(2024-09-01) added the macro-chapter warning. The current INCLUDE entry also
	warns against mixing includes and block contexts, added by
	[`2c01480`](https://github.com/z00m128/sjasmplus/commit/2c01480f0bcc4f3ee8788a84afdb915347d4d0d1)
	(2025-03-09) for [#263](https://github.com/z00m128/sjasmplus/issues/263).
	Do not open a duplicate "document unsupported macro INCLUDE" task.
* [#264](https://github.com/z00m128/sjasmplus/issues/264), fixed by
	[`1736533`](https://github.com/z00m128/sjasmplus/commit/17365332e9ba7b5f9bda85788b1bc2e576d730af)
	(2025-03-10), made ordinary locals preserve their main label's module/global
	prefix. This does not change `.local` into an ordinary local inside a macro.
* [`c6dd679`](https://github.com/z00m128/sjasmplus/commit/c6dd6799fdb4a51aca964d7beb35f924693541a1)
	(2025-04-26), "Fix local labels inside macros in modules", is a later lookup
	fix, not implementation of the requested include-label mode. Its existing
	[regression fixture](../tests/sjasmplus_regressions/local_labels_1.21.0_regression.asm)
	covers lookup from a macro and resetting the ordinary-local prefix at ENDMODULE.
* Allowing the same macro name to be defined independently in different MODULE
	namespaces is a separate proposal, not the clarified #120 request. Macros
	currently use one name-keyed table and the manual requires unique names.
	Maintainer disposition: will not implement in v1.x; not committed for v2.x.
	Do not conflate this with labels defined by a macro in different modules.

### Why Source Ownership Matters

The controlling paths are [CMacroTable::Add/Emit](../sjasm/tables.cpp),
[dirINCLUDE](../sjasm/directives.cpp), and
[IncludeFile/OpenFile/ReadLine](../sjasm/sjio.cpp):

1. Definition stores the INCLUDE line as raw text. Expansion substitutes it and
	invokes the ordinary directive handler, which opens and assembles the file.
2. `IncludeFile()` saves file buffering and stdin state, but does not suspend
	`macrolabp`, macro arguments, or the stored-source cursor `lijst/lijstp`.
	Consequently included statements inherit macro label/substitution context.
3. `OpenFile()` initially drives the file reader directly. Nested consumers such
	as IF and LUA instead call `ReadLine()`, which prefers `lijstp` whenever
	`lijst` is active. Thus a block opened in the included file can read the
	remaining macro body rather than its own file. Macro definition collection
	uses `ReadLineNoMacro()`, illustrating the inconsistent source selection.

The probes below confirm this distinction: a plain included instruction works
during macro replay, but an included IF body can consume caller expansion lines
instead of included lines. A balanced IF entirely inside the include, compared
with the same include outside a macro, distinguishes this reader issue from both
label-policy changes and intentionally crossing block boundaries.
The architectural requirement is separate input ownership and semantic label
policy, not simply clearing all "inside macro" state around an include: that
would also affect argument substitution, nested macros, and caller restoration.

### Current Reproductions

Built with `make -j8`; probes used the release `./sjasmplus` with
`--nologo --color=off --msg=err`, a five-second timeout, and address assertions
where applicable. The original ZIP was downloaded and extracted outside the
repository. Its main file defines a Lua function on PASS1, calls it from a macro's
ALLPASS Lua block, and injects two MODULE/INCLUDE sequences through `_pl()`.
The included source is only:

```asm
MyLabel
 ld a,a
.asd
 ld c,b
```

The unmodified attachment still reports `[LUA] Duplicate label: 0>asd`.
Removing Lua and putting the two MODULE/INCLUDE sequences directly in the macro
also reproduces the collision. There is no need to change Lua function lifetime
or introduce module-scoped macro definitions to explain it.

Additional temporary probes compared the same included bodies in different
contexts:

| Included body / caller | Result |
| --- | --- |
| Plain `db 1`, direct or in macro | Pass |
| Balanced `IF 1 / db 1 / ENDIF`, direct | Pass |
| Same IF body, macro with INCLUDE as its last body line | No ENDIF, then stray ENDIF |
| Same IF body, macro with `db $EE` after INCLUDE | Same failure; IF reads the macro tail |
| Same IF body, INCLUDE during `DUP 1` replay | No ENDIF and repeat-boundary/stray-ENDIF errors |
| Same IF body, INCLUDE inside direct `IF 1` | Pass; the manual's broad warning is not a claim that every combination fails |
| Balanced ALLPASS Lua emitting `db 1`, direct | Pass |
| Same Lua body, INCLUDE in macro with trailing `db $EE` | Unexpected end of Lua; Lua tries to parse macro-tail assembly |
| `DUP 2 / db 1 / EDUP`, direct or included from macro | Pass in this small case; not general block-composition support |
| Two modules each defining `MyLabel` and `.asd`, direct | Pass |
| Same two modules, included from one macro expansion | Duplicate `0>asd` |
| Replace `.asd` with `@.asd` in that include | Pass inside macro; invalid label outside macro |
| Define macro `duplicate` in each of two modules | Duplicate macroname, as documented |

Minimal source-ownership reproducer, with two files (the names below are proposed
fixture names, not checked-in tests):

```asm
; main.asm
 MACRO wrapper
 INCLUDE "body.asm"
 ENDM
 wrapper
 ASSERT $ == 1

; body.asm (separate file)
 IF 1
 db 1
 ENDIF
```

Replacing the macro definition/invocation with just `INCLUDE "body.asm"` passes.
This is the already reported [#263](https://github.com/z00m128/sjasmplus/issues/263),
closed as not planned in March 2025, including its follow-up about REPT. Treat it
as related deferred parser work, not a newly discovered independent ticket.
Its link to [#261](https://github.com/z00m128/sjasmplus/issues/261) does not make
repeat-index label collisions another unresolved #120 item: that diagnostic bug
was fixed by `d0c9ca4`, with existing `issue261_dup_duplicate_label` coverage.

Existing baselines, run sequentially, both passed:

| Command | Tests | Checks |
| --- | ---: | ---: |
| `make -j8 test TEST=macros` | 27 | 42 |
| `make -j8 test TEST=sjasmplus_regressions` | 20 | 29 |

These are research probes, not new permanent regression fixtures. No runtime code
was changed. The full suite, other toolchains, device mode, and arbitrary nested
include/macro combinations were not tested in this follow-up.

### Suggested Issue Split

Two distinct follow-ups remain worth tracking. Either narrow #120 to the second
one and link the first, or replace it with focused issues and retain backlinks.
This notebook does not create, reopen, or close GitHub issues.

1. **Preserve input ownership when INCLUDE runs during stored-source replay.**
	Existing report: #263, closed as not planned; carry it into the parser-context
	work or explicitly supersede it rather than silently duplicating it.
	A block entirely inside an included file must consume that file's text, return
	to the correct macro/repeat cursor, and leave the caller tail assembled once.
	Start with IF and Lua, then characterize nested includes and stored replays.
	Keep label behavior and expansion-time substitution unchanged. Test exact
	bytes, errors and source traces, EOF recovery, and no fall-through into caller
	source. Clean hierarchical nesting still applies; this is not permission for
	an IF opened in one input to steal a closer from another.
2. **Design an explicit, scoped ordinary-local label policy for macro-reachable
	source.** This is #120's September 2021 request, still unimplemented. Preserve
	current behavior by default; do not make every INCLUDE silently escape macro
	scope. No switch spelling or implementation is selected. Before implementation,
	decide whether the policy belongs to an include operation or a surrounding
	scope, how definitions and references agree, how nested macros/includes inherit
	it, and what is restored on return/error. Preserve argument substitution and
	macro-instance state independently. Acceptance examples should include the
	original unmodified third-party file in two modules, ordinary references inside
	it, repeated macro invocations, nested macros, and restoration afterward.
	`@.label` is an existing explicit definition escape, not a transparent source
	rewrite: it is invalid outside macro expansion and cannot solve the unchanged
	third-party-file requirement. This remains a design question, not a v1.x promise.

Adding module/main-label components to every macro-local name is an alternative
label design, not an additional prerequisite for those two items. Likewise, a
separate macro-local prefix is already recorded under possible incompatible 2.x
changes in [TODO.txt](../TODO.txt). Avoid opening overlapping syntax proposals as
if each were an independently required fix. Module-scoped duplicate macro names
remain explicitly outside this work and rejected for v1.x.

## What STRUCT Conditionals Actually Need

`ParseStructLine()` substitutes text, parses member labels, then interprets member
types through `GetStructMemberId()`. BYTE/DW/BLOCK/ALIGN here build a structure
description using `st->noffset`; they are not ordinary output directives.
`dirSTRUCT()` eventually calls `deflab()` to publish the structure/member symbols.

Merely allowing IF through `ParseDirective()` would make `dirIfInternal()` call
`ReadFile()`, which parses active lines as normal assembly. Members could emit
bytes or define ordinary address labels instead of updating the structure.

A shared conditional controller should retain the caller's active-line handler:
normal source dispatches to ordinary assembly; a structure dispatches to its
member parser. A context frame or scoped handler must survive recursive IFs and
restore on every exit. The controller must see filtered structural markers before
the body-specific label parser consumes them. Shared preparation must not then
substitute the same line again or advance comment state twice.

Even with that mechanism, settle these semantics explicitly:

* Initially support only existing IF-family controls and members, or also macros,
	repeats, DEFINE, INCLUDE, ASSERT, and Lua? Do not enable all ordinary directives
	by accident. Macro/repeat replay currently hardcodes the normal parser too.
* Does `$` remain the assembly address, as now, or denote the member offset? Keep
	current expression semantics unless a separate extension is specified.
* Member symbols are published at completion. Conditions involving earlier
	members, IFUSED without an argument, forward references, or pass-dependent
	sizes need explicit tests and documented meaning; they are not free benefits.
* ENDS while a member-selecting IF is still open violates clean nesting. Diagnose
	the boundary error rather than consuming ENDS as a member or leaking out into
	the outer source; the remaining design question is detection and recovery.
* Which member labels exist when a branch is inactive, and how are listings and
	repeated definitions handled consistently across all three passes?

## Design Alternatives

### A. Keep Consumers, Fix Their Scanners

Introduce a narrow comment-aware structural recognizer and use it in the current
loops. Keep recursive control flow, stored bodies, and substitution timing.

Benefits: lowest blast radius, directly addresses #416 and sibling collector
bugs; straightforward regression-driven work. No need to migrate expression or
instruction parsing. It can be an endpoint if larger cleanup offers little gain.

Costs: ownership remains scattered. STRUCT conditionals still need explicit
body dispatch; Lua payload handling and duplicate lexical state still need a
coherent contract. Copying another local comment loop into every consumer would
not achieve even this option's intended sharing.

### B. Shared Scanner And Context-Aware Dispatch

Separate source acquisition, lexical visibility, structural classification, and
semantic handling. Keep existing directive handlers and recursive block readers
initially. A small context identifies body grammar and execution/capture/skip
policy; a shared scanner produces block events without executing directives.

Benefits: central fixes for comment visibility and keyword recognition; preserves
tolerant skipping and raw capture; active IF branches can retain STRUCT handling.
This is the preferred direction, built in increments rather than one rewrite.

Costs: raw versus substituted recognition is a compatibility decision. File and
stored input must share lexical behavior without processing comments twice.
Recursive consumers still need clear bounds and scoped state restoration.
Avoid a long parameter list of booleans; use named modes with explicit policies.

For #120/#263, sharing structural recognition alone is insufficient. Source
acquisition must also support nesting such as
`file -> macro replay -> file -> macro replay -> file`, including repeat replay.
Each nested input suspends its caller's cursor and resumes it on return; block
readers must consume the current input, not prefer any active macro globally.
This can be introduced with scoped recursive input ownership or an input stack;
it does not require adopting option C's single event driver. Keep this requirement
separate from any explicit ordinary-local label policy.

Illustrative contracts, not proposed public APIs:

```text
nextSourceSegment()                  -> raw text + source position + origin
scanVisibleStructure(raw, lexState)  -> marker + argument offset + live spans
consume(context, segment, marker)    -> continue / close-owning-block / stop
prepareActiveLine(context, segment)  -> one substituted active line
dispatchActiveBody(context, line)    -> assembly or structure-member grammar
```

Classification is non-mutating with respect to symbols/output; advancing lexical
state is explicit. Preserve original text for capture/listings and defer semantic
expansion. Do not equate a physical source line with a colon-separated segment.

### C. One Driver With Explicit Context Frames

Replace recursive read loops with an event driver and stack frames for body
grammar, conditional state, capture/replay, and foreign text. Frames record opener
positions and valid closers; an input stack handles files and stored expansions.

Benefits: makes source ownership and boundary errors visible; fewer hidden reads;
provides a natural place to preserve the enclosing STRUCT body handler.

Costs: larger flow change. Capture is not execution, and replay is another input
origin, so a flat `enum Mode` is insufficient: conditional state, input origin,
and body grammar compose. Must migrate listing order, source traces, EOF behavior,
include restoration, macro locals, repeat recovery, and re-entrant Lua callbacks.
Likely a useful destination only if option B still leaves concrete complexity.

### D. Tokenize Or Build A Block Tree Before Assembly

Represent blocks explicitly and interpret them with different body handlers.

Benefits: explicit nesting, possible tooling/introspection, less repeated keyword
classification. An immutable raw representation can simplify source attribution.

Costs: a conventional preprocessing/AST pass conflicts with sjasmplus's per-line
substitution, invalid inactive text, changing defines, generated instructions, and
iteration-dependent counts. A fully parsed tree would reject source currently
tolerated in skipped branches. A lossless raw block tree might work, but still
needs policies for generated block markers and opaque Lua. More storage and new
invalidation/lifetime problems, without evidence it is necessary for this task.

### E. Route Everything Through ParseLine With A Directive Allowlist

Attractive superficially, but not recommended in isolation. `PrepareLine()` already
substitutes before directive dispatch; labels, macros, output, and nested source
consumers have side effects. An allowlist after that point is too late for raw
capture or skipped nonsense. Moving recognition ahead of those stages effectively
turns this option into B, with policies that should be explicit rather than hidden.

### Diagnostic Origin And Source Text

Make expansion diagnostics useful without editor error parsing. Today
[`initErrorLine()`](../sjasm/io_err.cpp) selects one `^ emitted from here`
location from `sourcePosStack`. Preserve the primary location and existing trace
attribution, and aim to show the relevant original source line alongside the
trace location when that text is available.

Scoped parser/input contexts offer a natural place to carry linked provenance:
where this text was defined or generated, and which caller, include, or replay
brought it into the current input. A diagnostic can walk those links back to
the originating source without reconstructing the chain from nesting counters.
Walk source origins, not every grammar frame: an IF or STRUCT frame need not
introduce a new origin. This works with scoped recursive contexts as well as an
explicit stack; displaying the full chain is a separate formatting decision.

Keep original text or a stable reference to it rather than using the current
substituted line buffer. In a macro, distinguish the body line from the call
site; for assembly generated by inline Lua, distinguish the generated text from
the script location. If no original line is available for a frame, report its
known location without inventing text. Characterize nested includes, macro and
repeat replay, colon-separated segments, and inline Lua before changing the
trace format. This is a side goal, not a prerequisite for the parser refactor.

## Non-Negotiable Boundaries And Open Decisions

* Source origin is not semantic context: a STRUCT can be read from a macro, a
	conditional from a repeat, and Lua can inject assembly while holding an outer
	line. Store these dimensions separately.
* Nested file and stored-source inputs must suspend and resume in the correct
	order. While assembling an include from a macro, its IF/Lua readers must read
	the include, not the suspended macro tail. Preserve the caller's cursor,
	arguments and label policy independently; normal return and error recovery
	must not accidentally consume or replay caller lines.
* Preserve macro arguments, macro-local namespaces, include predefined values,
	repeat index updates, WHILE guardian/evaluation timing, `IsRunning`/END, and
	pass-specific diagnostics. No eager evaluation during capture or skip.
* Preserve line/column positions, error expansion traces, listing order and
	skipped/expanded markers, EOL warning-suppression comments, SLD comment tracking,
	and SIZEOF source-block boundaries. These are externally visible behavior.
* EOF of a stored expansion must not fall through into the caller's file.
	`PrepareNonBlankMultiLine()` already guards one such boundary. Define ownership
	for continuations, conditionals, includes, and abnormal exits consistently.
* Decide whether structural markers are recognized before substitution, after
	substitution, or by distinct rules for execution/capture/skip. Preserve known
	rules first; treat normalization as an intentional compatibility change.
* Generated comment delimiters and iterative substitutions mean raw lexical
	visibility and expanded lexical visibility are not identical. Retain the
	existing expansion behavior until its replacement has dedicated coverage.
* Define malformed skipped-text tolerance. Ignoring invalid instructions and
	undefined expressions is required; tracking an unclosed block comment can still
	change where a skipped branch ends. Do not demand a full valid token stream.
* Decide whether macro/repeat definitions in inactive branches shield their own
	conditional-looking text. Today `SkipFile()` only shields Lua explicitly.
	Adding shielding can change tolerated unbalanced constructions.
* Define practical foreign-language sentinel behavior under the guidance above.
	Recognizing ENDLUA inside Lua long comments/strings is a different problem from
	assembly block comments. Bare/dotted equivalence in ordinary use is required;
	full Lua parsing is not justified merely to centralize assembly keyword checks.

## Suggested Sequence And Tests

Small independently tested fixes for clear syntax inconsistencies, such as dotted
ENDLUA recognition, need not wait for this architectural sequence. Keep them
separate from broad compatibility changes or mixed-language parsing extensions.

1. Add focused regression fixtures for #416 before changing runtime behavior.
	 Cover active/inactive branches, ELSE/ELSEIF/ENDIF and nested IF-family forms,
	 nested comments, and `;`/`//` controls. Check emitted bytes as well as errors:
	 the report includes wrong-branch assembly, not merely misleading diagnostics.
2. Characterize the sibling collector failures separately: commented repeat,
	 macro, STRUCT terminators; Lua payload markers; comment close followed by live
	 marker on the same line. Do not require fixing all of them in one patch.
3. Extract non-executing structural recognition and an explicit lexical-state
	 contract; retain existing block-reader loops first. Test file versus stored
	 input and ensure comments advance once per relevant traversal.
4. Make active-body dispatch context-aware, then add STRUCT conditionals as a
	 separate feature. Assert structure size, member existence/offset/defaults,
	 unchanged assembly address during definition, and correct instantiated bytes.
	 Keep unsupported directives rejected; diagnose crossing ENDS/ENDIF boundaries.
5. Address nested input ownership as a separate increment (#120/#263). Cover
	`file -> macro replay -> file -> macro replay -> file` and repeat replay,
	with balanced IF/Lua blocks in included files. Assert exact bytes and that each
	caller tail resumes once, with correct source traces and bounded EOF/error
	recovery. Keep default label/substitution rules unchanged; a label-policy
	extension is separate. A shared scanner alone does not meet this goal.
6. Reassess an explicit driver/context stack only after these changes expose the
	 remaining complexity. Do not migrate expression/CPU parsing merely for symmetry.

Coverage dimensions for those stages:

| Dimension | Cases |
| --- | --- |
| Input | File, include, stdin, macro replay, repeat replay, Lua injection |
| Conditional | True/false, nested, ELSEIF chains, every IF-family opener; no evaluation of inactive expressions |
| Recognition | Indented/BOL, `--dirbol`, labels/colon/numeric labels, optional dot, upper/lower/mixed case, `--syntax=i`, keyword prefixes |
| Comments | Nested blocks, quotes containing delimiters, EOL comments, close/open on same line, live marker after close, unterminated blocks |
| Capture/replay | Zero repeats, nested index-dependent counts, changing DEFINE values, deprecated ENDM, dot repeater, malformed nested counts |
| Lua | Direct and stored bodies, method-call colons, long strings/comments containing assembly markers, skipped/pass-selected execution |
| Structure | Plain members, nested structures and brace continuations, IF nesting, forward/member references, allowed/rejected commands |
| Recovery | EOF, missing/wrong closer, END, crossing repeat boundaries, no accidental read beyond expansion |
| Observable output | Exact bytes, symbols/offsets, pass stability, listings, diagnostic positions/traces, suppression comments and SLD |

Use the existing test homes and helpers rather than creating a parallel harness:

* [comments.asm](../tests/parsing/comments.asm),
	[dot_repeat.asm](../tests/parsing/dot_repeat.asm),
	[while.asm](../tests/parsing/while.asm).
* [if_dup_if_nesting.asm](../tests/parsing/if_dup_if_nesting.asm),
	[if_dup_if_nesting2.asm](../tests/parsing/if_dup_if_nesting2.asm),
	[Issue146_conditional_dup_crash.asm](../tests/parsing/Issue146_conditional_dup_crash.asm),
	[rept_crash_fix.asm](../tests/parsing/rept_crash_fix.asm).
* [Issue138_if_vs_label.asm](../tests/parsing/Issue138_if_vs_label.asm),
	[nested_dup_with_label.asm](../tests/sjasmplus_regressions/nested_dup_with_label.asm).
* [dir_end.asm](../tests/misc/dir_end.asm),
	[dir_end2.asm](../tests/misc/dir_end2.asm),
	[dir_if_ifn.asm](../tests/misc/dir_if_ifn.asm),
	[struct_test.asm](../tests/misc/struct_test.asm).
* [lua_colons_inside_macro.asm](../tests/lua_examples/lua_colons_inside_macro.asm)
	and the Lua parse-line/parse-code tests under
	[tests/lua_examples/trivial](../tests/lua_examples/trivial).

Permanent tests should follow the existing assembler fixture conventions: binary
comparisons for successful byte-producing cases; expected listings for errors and
source attribution. Extend focused suites first, then run `make test` for a runtime
refactor. After any header changes, clean before Makefile builds/tests because
header dependency tracking is incomplete. Exercise pipe and device modes where
emission, addresses, or memory-dependent expressions are affected.

## Assessment

The current complexity is not all accidental: deferred raw text, tolerant skipped
branches, distinct STRUCT semantics, foreign Lua text, and three-pass evaluation
really do require different policies. What appears avoidable is repeating raw
keyword checks and hiding source/body ownership inside recursive directive calls.
Centralizing that layer offers a credible simplification. It will not make every
context equivalent, and preserving those differences is part of the design, not
a failure to achieve one parser.