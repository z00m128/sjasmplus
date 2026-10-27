# Integer argument parsing cookbook

This is a maintainer's guide to `getIntArguments` in
[parser.h](../sjasm/parser.h), not a change to assembler syntax. The helper is
best suited to a bounded, comma-separated tail of integer expressions, with
required arguments followed by optional arguments.

## Start with the grammar and defaults

For `<filename>,<address>[,<length>]`, parse the filename separately, consume
its separator, then describe the numeric tail in two matching arrays:

```cpp
const std::filesystem::path filename = GetOutputFileName(lp);
aint args[] = {0, 0};
const bool optional[] = {false, true};
if (!comma(lp) || !getIntArguments<2>(lp, args, optional)) {
	Error("Expected <filename>,<address>[,<length>]", bp, SUPPRESS);
	return;
}
const aint address = args[0], length = args[1];
```

- Initialize every element: omitted arguments retain those values.
- Use `aint` arrays, not `int` arrays or vectors. Both array sizes must match
  the template argument; the compiler checks this.
- Use a required prefix and optional suffix: `{false, false, true, true}`.
  The helper does not validate the mask. `{false, true, false}` is unsafe:
  omission of the second argument can report success without requiring the third.
- Keep defaults close to the mask. Named references or const copies help when
  several subsequent checks would otherwise use unexplained indices.
- Keep filename, string, keyword, and mode parsing outside the helper.
- Validate ranges separately, before performing the operation.

The helper consumes separators *between* numeric arguments, not the separator
before the first argument. Preserve the caller's choice of `comma` versus
`anyComma`: `comma` refuses adjacent `,,`, whereas `anyComma` consumes one comma.
These functions also skip whitespace.

## Recipes for legacy code

| Legacy pattern | Replacement | Important condition |
| --- | --- | --- |
| Repeated comma/expression checks for a fixed tuple | One call with an all-false mask | Preserve error gating and execution guards. |
| Nested `if (comma(lp))` for optional trailing numbers | Initialized defaults and a trailing-true mask | An explicit separator still requires an expression. |
| Parse a temporary value, then assign each destination | An `aint` array, optionally followed by named aliases | The helper already assigns an element only after its expression succeeds. |
| Parse strings, then a fixed numeric tail | Keep string parsing; convert only the numeric tail | Do not absorb branches that select different grammars. |
| A sentinel default passed to a writer | Initialize the corresponding element to that sentinel | Check whether the same explicit value is legal. |

Do not grow an abstraction around a single number merely for consistency.
Two arrays and a template call usually make a one-expression directive longer.

## What success and failure actually mean

`getIntArguments` uses `ParseExpression`, not
`ParseExpressionNoSyntaxError`. Expression parsing can itself report errors and
affect expression/relocation state. A migration must not silently change those
diagnostics or move a relocation check to a different expression.

| Input at the numeric tail | Mask | Result |
| --- | --- | --- |
| `123` | `{false, true}` | Success; second value keeps its default. |
| `123,456` | `{false, true}` | Success; both values assigned. |
| empty | `{false, true}` | Failure: first argument required. |
| `123,` | `{false, true}` | Failure: second expression missing. |
| `123,456,789` | `{false, true}` | Failure; the excess separator is consumed, not `789`. |
| `123,,456` | `{false, true}` | Success with `,,456` unconsumed: `comma` refuses the double comma. |
| `123 unexpected` | `{false, true}` | Success with trailing text unconsumed. |
| empty or an unparseable first expression | `{true, true}` | Reports success on first-expression failure; not a strict absence check. |

Success is therefore **not** proof that the complete tail was consumed. For a
directive owning the entire remainder of the line, check it before side effects:

```cpp
if (!getIntArguments<2>(lp, args, optional) || !SkipBlanks(lp)) {
	Error("Invalid numeric argument tail", bp, SUPPRESS);
	return;
}
```

`SkipBlanks` returns true at end of input. Only use this check where the entire
tail belongs to these numbers, not where another syntactic component follows.
Do not assume the assembler's eventual "Unexpected" diagnostic prevents writes:
it can run after the directive's action.

Failure is not transactional: earlier array entries can be assigned, `lp` can
advance, and parser diagnostics/state changes are not rolled back. Discard the
result on failure; do not use it to perform a partially specified operation.
An all-optional group also needs an explicit absence/presence policy at the
call site if malformed first expressions must not count as omission.

## Preserve passes and failure paths

Before converting a directive, answer these questions locally:

1. Does it parse on every pass, or skip the complete tail on early passes?
2. Are range checks early-pass checks, final-pass checks, or gated by `exec`?
3. Does failure return, disable execution, skip to EOL, or restore a pointer?
4. Does checking the first value have to precede parsing the second one?
5. Is omitted distinct from an explicitly supplied sentinel value?
6. Can parsing additional arguments itself report errors or change parser state?

Keep the existing pass/device guard in place. Replacing a loop need not add an
early return: `SAVEDEV` retains its `exec = false` failure path and its existing
final-pass-only validation/writing block.

Separating syntax from range validation may change which error wins when several
arguments are bad. Record this intentionally rather than claiming byte-for-byte
diagnostic compatibility for every malformed input.

## Lessons from SAVEBIN and issue #398

[Issue #398](https://github.com/z00m128/sjasmplus/issues/398) concerned the
undocumented optional length: supplying only the start address saved through the
end of RAM. [Commit 20e8c0a](https://github.com/z00m128/sjasmplus/commit/20e8c0a2e92b8a0e2c4de227802b86134e05a60c)
did more than replace parsing: it documented the default, introduced negative
start/end semantics, updated `SaveRAM`, and added binary regression checks.
Those changes explain why its total diff is not a measure of template savings.

Its `{0, 0}` defaults and `{false, true}` mask make the intended arity explicit.
That caller is an example, not proof that the helper is a strict full-line
validator: the partial-consumption cases above still apply.

For this batch, `SAVEHOB` uses length default `0` instead of the old internal
`-1`. `SaveHobeta` normalizes either value to `0x10000 - start`, and explicit
zero was already legal. This keeps all explicit negative lengths invalid without
adding an "argument supplied" flag. Binary tests compare omitted, zero, explicit,
and forward-referenced lengths.

## directives.cpp migration audit

| Directive or group | Assessment |
| --- | --- |
| `SAVEHOB` numeric tail | Converted: required start, optional length. Keeps string parsing and final-pass/device guard. Removes nested parsing and an always-true `exec`. Requires complete-tail consumption before writing. |
| `SAVEDEV` | Converted: three required integers. Keeps the execution guard and final-pass range checks. The main maintenance gain is an explicit tuple contract rather than a large line-count reduction. |
| `SAVEBIN`, `SAVE3DOS`, `SAVEAMSDOS`, `SAVEHEX`, `DEFDEVICE` | Already use the helper; not migration candidates. Their masks/defaults still deserve independent review when changing their syntax. |
| `INCBIN`, `INCHOB`, `INCTRD` | Not drop-in conversions: support omitted interior offsets (`file,,length`). Some also validate/skip on failure before file access. The helper cannot express these holes. |
| `SAVETRD` | Potential later tail conversion, but not a first batch: replace/add modes, deferred invalid-address handling, and mode-dependent autostart parsing affect early exits and diagnostics. |
| `SAVETAP` | Potential later branch-local conversions; BASIC/CODE/HEADLESS and snapshot forms have different strings, defaults, optional tails, and interleaved validation. Not one uniform numeric tuple. |
| `DISP` | Two numbers, but relocation validation must refer to the first expression and precedes optional-page processing. Moving parsing ahead of it is not a mechanical replacement. |
| `MMU` | Mixed grammar: slot ranges/options, commas, optional address, and ordered validation. Retain specialized parsing. |
| `ORG`, `DEVICE` | First argument establishes context for the second (address/page or device ID/RAMTOP). Little benefit without changing validation order or grammar. |
| `END`, `HEXEND`, `SAVESNA` | One optional number, with fallback, pointer restoration, or source-of-default warnings. More bookkeeping than benefit. |
| `DB`/`DW`/`D24`/`DWORD`, `BLOCK`, repeat/conditional directives | Variable-length data, strings, relocation/emission bookkeeping, or block-control grammar. Not bounded integer tails. |
| Other single-expression or nonnumeric directives | Keep their direct parser calls. |

The converted directives intentionally reject excess single-comma arguments before
writing. `SAVEHOB` also rejects leftover text before writing; syntax/range error
precedence on multiply-invalid inputs can differ. Existing regression listings
were unchanged before adding cases; new cases pin these stricter failure paths.

## Focused verification

Cover required-prefix omissions, each optional truncation, explicit defaults,
trailing commas, double commas/empty slots, malformed expressions, extra
arguments, range boundaries, forward references, and the device/pass guards.
Compare output bytes, not just successful assembly.

```sh
make -j8 test TEST=devices/save
make test TEST=sjasmplus_regressions/custom/trd
```

Run these sequentially: the feature runner clears a shared scratch directory.
Keep binary-comparison `.cli` tests separate from `.lst` tests: the runner's
listing comparison replaces the CLI exit status.