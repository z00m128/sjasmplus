# STRUCT Union Research

Research note, 2026-11-20. Proposed syntax below is illustrative, not supported syntax.

## Request And Layout

[#223](https://github.com/z00m128/sjasmplus/issues/223) asks for a C-style union. It
does not specify syntax, initialization, or alignment. The maintainer reply asks
for syntax that fits existing features and notes that the implementation may need
refactoring. This is a question about reusable layouts, not a request for a
runtime tag, automatic type checking, or C ABI compatibility.

For `x BYTE`, overlapping `y BYTE` and `z WORD`, then `a BYTE`, the offsets are
`x=0, y=1, z=1, a=3`, and the structure size is 4. A rollback block saves its
entry offset and starts each alternative there. At close it advances to the
furthest alternative end, not the last alternative's end or the sum. Explicit
padding counts toward that end. There is no implicit alignment merely because a
field is a `WORD`.

## What Works Today

The [STRUCT manual](documentation.xml#L4371) describes sequential fields,
composition from already defined structures, and label-only instances at a
designated address. A label-only member already aliases the next storage member:

```asm
    STRUCT Record
x   BYTE $11
y
z   WORD $3322
a   BYTE $44
    ENDS

rec Record
    ASSERT rec.y == rec.z
    ASSERT rec.a == rec + 3
    ASSERT SIZEOF rec == 4
view Record = $8000
    ASSERT view.y == $8001 && view.z == $8001
    ASSERT $ == rec + 4
```

This gives one canonical initializer (`z` here), not a typed `y` initializer.
For larger views, define each as its own `STRUCT`, reserve the maximum size once,
then bind both types at that address with `left LeftView = buffer` and
`right RightView = buffer`. This works without new syntax but requires manual
size accounting and separate instance names.

## Definition Syntax Options

**Explicit rollback block.** For example:

```asm
    STRUCT Record
x   BYTE
    UNION
y   BYTE
    NEXTU
z   WORD
    ENDU
a   BYTE
    ENDS
```

`NEXTU` allows a multi-field alternative without a helper type. An anonymous
block exports `Record.y` and `Record.z`; a later named form such as
`payload UNION` could export `Record.payload.y` and `Record.payload.z`.
This directly expresses the mixed layout, but adds three body tokens and
requires balancing and error recovery. Restrict markers to the opcode column:
column-one `UNION` can already be a member label, and an opcode can already name
a user-defined structure. Check collisions before deciding keyword precedence;
a dot prefix alone does not make that check unnecessary.

**Named union type.** `UNION Payload` ... `ENDU` could use the same structure
table and layout engine, with each direct member an alternative. `payload Payload`
in another structure would yield `Record.payload.y` and `Record.payload.z`.
Use a previously defined structure for a multi-field alternative. This is a
compact C-like form and existing composition is sufficient for nesting, but a
named-type-only design makes one-off overlays verbose and changes their label
paths. `STRUCT Payload, UNION` would collide with the existing offset-expression
slot (including a symbol named `UNION`); a distinct keyword or an unambiguous
modifier is preferable. If inline groups also exist, document clearly that the
type form separates alternatives by member and the inline form by `NEXTU`, or
use `NEXTU` in both forms to keep one grammar at the cost of more lines.

**General cursor control or aliases.** `OFFSET <expr>` inside `STRUCT` could
express arbitrary partial overlap, unlike unions whose alternatives start
together. It requires rules for holes, backward writes, and high-water size.
An `ALIAS`/`VIEW` operation that exports sublabels over one owning field avoids
write conflicts and can solve register maps or reinterpretation, but does not
provide independent initializers. Prefer this narrower model over a general
offset reset if reuse of existing storage is the only goal.

Precedents: [RGBDS](https://rgbds.gbdev.io/docs/v0.9.4/rgbasm.5#Allocating_overlapping_spaces_in_RAM)
uses `UNION` / `NEXTU` / `ENDU` for allocation blocks, including nested groups,
not competing initialized data. [ca65](https://cc65.github.io/doc/ca65.html#s15)
uses `.UNION` / `.ENDUNION` for named or anonymous layouts and `.TAG` for
allocation, without typed instance initialization. Neither settles sjasmplus's
initializer rules.

## Initialization And Implementation

- **Reserve only:** lower the group to one `BLOCK` plus labels for every view.
  The group consumes no initializer slot; the next normal field still does.
  Reject explicit alternative defaults or overrides rather than silently dropping
  them. Unfilled `BLOCK` preserves device memory, so choose and document whether
  the union reserves or zero-fills, and check raw output separately.
- **One fixed owning alternative:** lower a declared default branch plus tail
  padding, export labels for all branches, and only accept initializers for the
  owner. Streaming remains simple, but changing owner can change the positional
  initializer shape. Avoid picking the longest branch implicitly.
- **Select one alternative per instance:** a grouped slot such as
  `rec Record {$11, {z => $3322}, $44}` could select by name, or a numeric selector
  could be shorter but sensitive to reordering. Define omission (explicit
  default, first branch, reserve, or error), tail padding (zero or preserve), and
  whether embedding can override the branch/defaults. Reject conflicting
  selectors; do not emit or record relocations for inactive alternatives. All
  view labels remain available regardless of selection. The example is a grammar
  sketch: recognize `=>` in the union slot before parsing branch values as
  expressions. Avoid `:`: `ReadLine` splits on colons outside strings and
  comments before initializer parsing, even inside braces. Test the grouped
  syntax with `TEXT` and existing multiline initializers.

The [body reader](../sjasm/directives.cpp#L1805) owns `ENDS`; ordinary body
lines go through [substitution and label/member dispatch](../sjasm/parser.cpp#L1257).
Keep inline group handling in that context rather than dispatching arbitrary
directives. Decide how marker recognition interacts with substitution, comments,
and the existing raw `ENDS` check; see [parser context research](parser-context-research.md).

[`AddMember`](../sjasm/tables.cpp#L1150) appends a member and advances `noffset`;
[`CopyMembers`](../sjasm/tables.cpp#L1182) flattens composed members and handles
initializer overrides, while [`emitmembs`](../sjasm/tables.cpp#L1342) emits in
list order. Rewinding `noffset` would fix label placement but not either walk.
For reserve-only or fixed-owner unions, lower to a normal linear emit list with
separate label offsets. For selectable unions, retain a group node with branch
sequences, extent, and default choice; preserve it through composition and
walk just the selected branch before emitting padding. A flat list with branch
markers is possible but makes both walks track nested branch boundaries. Avoid
rewinding the output stream: device writes, listings, relocation, and raw
output must agree without last-writer-wins behavior. The [label-only instance
path](../sjasm/tables.cpp#L1498) should still need no branch selection.

## Suggested First Scope

Prefer the explicit inline rollback block if one-off mixed layouts are the main
use case. Start with reserve-only unless a real example needs typed instance
initialization; add a named shortcut only if reusable standalone unions warrant
it. Compose predeclared types for nesting initially; defer inline nesting and
arbitrary offset resets. Decide whether `ALIGN` inside alternatives is initially
rejected or uses the existing structure-relative padding rules, with alignment
checked for all views, not only the emitted one. Keep the existing initial
offset as a prefix reservation, not part of an alternative.

First feature tests in `tests/struct/`: put the longest branch first and last;
assert offsets, both `SIZEOF` forms, and the next field/address; compare exact
raw bytes and device-memory preservation; test a composed type, a designated
address, and malformed markers without consuming the next definition. If adding
selection, also cover defaults, nesting of initializer braces, and relocation
at the actual emitted field position with no entries from inactive branches.