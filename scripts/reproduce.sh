#!/usr/bin/env bash
# Usage: scripts/reproduce.sh <kiota-version>   (e.g. 1.35.0)
# Env:   DART (default: dart). Needs the dotnet SDK and dart on PATH; expected/<ver>.txt lists the expected analyzer errors.
# Exit 0  = the expected generator defects (and only those) were reproduced.
# Exit 1  = analyzer output differs from expected (defects fixed, or new ones).
# Exit 2  = setup failure (install/generate/pub get/analyzer crash).
set -uo pipefail
cd "$(dirname "$0")/.."
ver="${1:?kiota version}"
DART="${DART:-dart}"
tools=".tools/kiota-$ver"
out="out/$ver"
mkdir -p "$out"
setup_fail() { echo "SETUP FAILURE: $*" >&2; exit 2; }

if [ ! -x "$tools/kiota" ]; then
  dotnet tool install Microsoft.OpenApi.Kiota --version "$ver" --tool-path "$tools" >"$out/install.log" 2>&1 \
    || { cat "$out/install.log" >&2; setup_fail "kiota $ver install"; }
fi
"$tools/kiota" --version | tee "$out/kiota-version.txt"
grep -q "^$ver" "$out/kiota-version.txt" || setup_fail "kiota version mismatch"

rm -rf lib
"$tools/kiota" generate --language Dart --openapi openapi.yaml \
  --class-name ReproClient --namespace-name repro --output lib/src --clean-output \
  --exclude-backward-compatible >"$out/generate.log" 2>&1 \
  || { cat "$out/generate.log" >&2; setup_fail "kiota generate"; }
[ -f lib/src/models/problem_details_dto.dart ] || setup_fail "generated model missing"

"$DART" pub get >"$out/pub-get.log" 2>&1 || { cat "$out/pub-get.log" >&2; setup_fail "pub get"; }

# --format machine: SEVERITY|TYPE|CODE|FILE|LINE|COL|LEN|MESSAGE
"$DART" analyze --format machine lib >"$out/analyze.raw" 2>"$out/analyze.err"
rc=$?
[ "$rc" -le 3 ] || { cat "$out/analyze.err" >&2; setup_fail "analyzer exit $rc"; }
grep -E '^ERROR\|' "$out/analyze.raw" | awk -F'|' '{n=split($4,p,"/"); print $3 "|" p[n]}' \
  | sort | uniq -c | sed 's/^ *//' >"$out/errors.txt"
cat "$out/errors.txt"

touch "$out/errors.txt"
diff -u "expected/$ver.txt" "$out/errors.txt" \
  || { echo "UNEXPECTED analyzer errors (diff above)" >&2; exit 1; }
echo "OK: analyzer errors match expected/$ver.txt"
