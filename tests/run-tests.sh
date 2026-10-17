#!/usr/bin/env sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/xslt-tests.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

assert_transform() {
    input=$1
    expected=$2
    actual="$work_dir/$(basename "$input")"

    xsltproc -o "$actual" "$project_dir/task3.xsl" "$input"
    xmllint --noblanks --c14n "$actual" > "$work_dir/actual.c14n"
    xmllint --noblanks --c14n "$expected" > "$work_dir/expected.c14n"
    diff -u "$work_dir/expected.c14n" "$work_dir/actual.c14n"
}

assert_transform "$project_dir/task3_in.xml" "$project_dir/xml_out.xml"
assert_transform "$project_dir/tests/after-feature-group.xml" "$project_dir/tests/after-feature-group.expected.xml"
assert_transform "$project_dir/tests/existing-number.xml" "$project_dir/tests/existing-number.expected.xml"
assert_transform "$project_dir/tests/namespaced-nested.xml" "$project_dir/tests/namespaced-nested.expected.xml"

if xsltproc "$project_dir/task3.xsl" "$project_dir/tests/multiple-feature-ids.xml" > /dev/null 2>&1; then
    echo "Expected a multi-ID featureAnchor to be rejected" >&2
    exit 1
fi

if xsltproc "$project_dir/task3.xsl" "$project_dir/tests/missing-feature.xml" > /dev/null 2>&1; then
    echo "Expected an unresolved featureAnchor to be rejected" >&2
    exit 1
fi

echo "All XSLT tests passed."
