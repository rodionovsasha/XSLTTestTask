# XSLT math numbering

`task3-1.0.xsl` numbers every `math` element in logical document order. A
`feature` contributes its `math` elements at the position of its matching
`featureAnchor`; it is not counted again at its physical position in
`featureGroup`.

All three stylesheets work for both namespaced and non-namespaced source XML:

- `task3-1.0.xsl` — XSLT 1.0;
- `task3-2.0.xsl` — XSLT 2.0;
- `task3-3.0.xsl` — XSLT 3.0.

The XSLT 3.0 variant uses the standard `shallow-copy` mode; all variants
produce the same result and enforce the same input contract.

## Stylesheet implementations

The 2.0 and 3.0 variants use the features of their declared standards rather
than workarounds for IDEA's inspections:

- Both use namespace wildcards such as `*:math` to match elements with or
  without a namespace, and explicit types for the debug parameter, document,
  feature, and calculated number.
- Both use the `math-by-feature-id` key to retrieve feature math directly.
  This avoids repeatedly walking feature subtrees when counting the math
  contributed by preceding anchors. Counting preceding nodes is still needed;
  this is not a single-pass or streaming transformation.
- The 2.0 variant uses XPath 2.0, an explicit `anchor` variable, and an identity
  template to copy nodes and attributes.
- The 3.0 variant uses XPath `let ... return` for the anchor, the standard
  `xsl:mode on-no-match="shallow-copy"` declaration, and `expand-text="yes"`
  for concise diagnostic messages.
- `@* except @number` preserves all attributes except the unqualified `number`
  being replaced, including namespaced attributes such as `prefix:number`.

IDEA may flag valid constructs in these stylesheets. The regression suites
run them using the bundled Saxon-HE 10.6. Saxon accepts newer constructs even
in stylesheets declaring version 2.0, so passing these tests alone does not
establish strict XSLT 2.0 compatibility.

## Input contract

- `featureAnchor/@features` contains one ID only. The plural attribute name is
  part of the source format; space-separated lists are deliberately rejected.
- Each anchor references exactly one `feature`, and each `feature` is
  referenced by exactly one anchor. Reusing a feature would require one output
  element to have multiple logical numbers, so the transform stops with an
  error instead of producing ambiguous output.
- A `feature` has a unique `id` attribute. `math` may occur anywhere inside a
  feature, including nested elements.
- Any existing unqualified `number` attribute on `math` is replaced.

## Run

The project includes [Saxon-HE 10.6](lib/Saxon-HE-10.6.jar), which supports
XSLT 1.0, 2.0, and 3.0. It is distributed under the Mozilla Public License
2.0. Java is the only required external dependency.

```sh
java -cp lib/Saxon-HE-10.6.jar net.sf.saxon.Transform \
  -s:task3_in.xml -xsl:task3-1.0.xsl -o:xml_out_1.xml

java -cp lib/Saxon-HE-10.6.jar net.sf.saxon.Transform \
  -s:task3_in.xml -xsl:task3-2.0.xsl -o:xml_out_2.xml

java -cp lib/Saxon-HE-10.6.jar net.sf.saxon.Transform \
  -s:task3_in.xml -xsl:task3-3.0.xsl -o:xml_out_3.xml
```

## Console logging

All three stylesheets log diagnostic messages by default. Pass `debug=false` to disable them:

```sh
java -cp lib/Saxon-HE-10.6.jar net.sf.saxon.Transform \
  -s:task3_in.xml -xsl:task3-3.0.xsl -o:xml_out_3.xml debug=false
```

Logging is enabled by default (`debug=true`). Messages use `xsl:message`;
Saxon writes them to stderr, separately from the output XML. They include the
start and successful completion of the transformation, plus the ID, enclosing
feature ID (empty for math outside a feature), and assigned number of each
`math` element. Messages follow processing order, so numbers need not be
ascending: features are numbered at their anchor positions.
Validation errors are always reported, regardless of `debug`.

## Example

Source XML:

```xml
<component>
  <sect1>
    <math id="c01-math-0001"/>
    <featureAnchor features="c01-fea-0001"/>
    <math id="c01-math-0002"/>
  </sect1>
  <featureGroup>
    <feature id="c01-fea-0001"><math id="c01-math-0003"/></feature>
  </featureGroup>
</component>
```

The logical order is `c01-math-0001`, `c01-math-0003`,
`c01-math-0002`; their numbers are therefore `1`, `2`, and `3`.

## Tests

```sh
tests/run-tests-xslt1.sh
tests/run-tests-xslt2.sh
tests/run-tests-xslt3.sh
```

Test scripts also enable debug logging by default. To disable it, set `DEBUG=false`:

```sh
DEBUG=false tests/run-tests-xslt1.sh
DEBUG=false tests/run-tests-xslt2.sh
DEBUG=false tests/run-tests-xslt3.sh
```

Output from deliberately invalid inputs is suppressed in both modes.

Each suite covers the supplied example, a section after `featureGroup`,
replacement of an existing number, namespaces, nested math in a feature, and
invalid multi-ID or unresolved anchors.

The 2.0 and 3.0 suites additionally cover multiple math nodes per feature,
feature storage order differing from anchor order, an empty feature, mixed
namespaces, preservation of a namespaced `number` attribute, and copying of
comments, processing instructions, and literal braces in source text.

To use another Saxon-HE JAR instead of the bundled 10.6 version, set
`SAXON_JAR`, for example: `SAXON_JAR=/path/to/Saxon-HE.jar tests/run-tests-xslt3.sh`.
