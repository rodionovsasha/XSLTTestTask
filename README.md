# XSLT math numbering

`task3.xsl` numbers every `math` element in logical document order. A
`feature` contributes its `math` elements at the position of its matching
`featureAnchor`; it is not counted again at its physical position in
`featureGroup`.

The stylesheet is written for XSLT 1.0 and works for both namespaced and
non-namespaced source XML.

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

```sh
xsltproc -o xml_out.xml task3.xsl task3_in.xml
```

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
tests/run-tests.sh
```

The checks cover the supplied example, a section after `featureGroup`,
replacement of an existing number, namespaces, nested math in a feature, and
invalid multi-ID or unresolved anchors.
