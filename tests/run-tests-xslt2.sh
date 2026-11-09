#!/usr/bin/env sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
saxon_jar=${SAXON_JAR:-"$project_dir/lib/Saxon-HE-10.6.jar"}

if [ ! -r "$saxon_jar" ]; then
    echo "Saxon-HE JAR not found: $saxon_jar" >&2
    exit 1
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/xslt2-tests.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

transform() {
    java -cp "$saxon_jar" net.sf.saxon.Transform "$@" "debug=${DEBUG:-true}"
}

assert_transform() {
    input=$1
    expected=$2
    actual="$work_dir/$(basename "$input")"

    transform -s:"$input" -xsl:"$project_dir/task3-2.0.xsl" -o:"$actual"
    xmllint --noblanks --c14n "$actual" > "$work_dir/actual.c14n"
    xmllint --noblanks --c14n "$expected" > "$work_dir/expected.c14n"
    diff -u "$work_dir/expected.c14n" "$work_dir/actual.c14n"
}

assert_transform "$project_dir/task3_in.xml" "$project_dir/xml_out_2.xml"
assert_transform "$project_dir/tests/after-feature-group.xml" "$project_dir/tests/after-feature-group.expected.xml"
assert_transform "$project_dir/tests/existing-number.xml" "$project_dir/tests/existing-number.expected.xml"
assert_transform "$project_dir/tests/namespaced-nested.xml" "$project_dir/tests/namespaced-nested.expected.xml"
assert_transform "$project_dir/tests/indexed-feature-math.xml" "$project_dir/tests/indexed-feature-math.expected.xml"

if transform -s:"$project_dir/tests/multiple-feature-ids.xml" -xsl:"$project_dir/task3-2.0.xsl" > /dev/null 2>&1; then
    echo "Expected a multi-ID featureAnchor to be rejected" >&2
    exit 1
fi

if transform -s:"$project_dir/tests/missing-feature.xml" -xsl:"$project_dir/task3-2.0.xsl" > /dev/null 2>&1; then
    echo "Expected an unresolved featureAnchor to be rejected" >&2
    exit 1
fi

echo "All XSLT 2.0 tests passed."
