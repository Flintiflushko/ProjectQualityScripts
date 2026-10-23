#!/usr/bin/env bash
set -euo pipefail

EXPECTED_COMMIT="98d0129cf21ce0871637ae36e67b5ff82d3db50d"

# Path to the Kubernetes repository.
K8S_DIR="${1:-../kubernetes}"

cd "$K8S_DIR"

ACTUAL_COMMIT="$(git rev-parse HEAD)"

if [[ "$ACTUAL_COMMIT" != "$EXPECTED_COMMIT" ]]; then
    echo "Error: wrong Kubernetes commit."
    echo "Expected: $EXPECTED_COMMIT"
    echo "Actual:   $ACTUAL_COMMIT"
    exit 1
fi

BASH_BIN="$(brew --prefix bash)/bin/bash"

echo "=== M3: Package Coupling ==="
echo "Kubernetes commit: $ACTUAL_COMMIT"

"$BASH_BIN" ./build/run.sh bash -c '
export HOME=/tmp
export GOCACHE=/tmp/go-build
export GOPATH=/tmp/gopath

OUTPUT=/tmp/coupling-production.tsv
rm -f "$OUTPUT"

go list -f '\''{{.ImportPath}}{{range .Imports}}{{"\t"}}{{.}}{{end}}'\'' ./pkg/... |
awk -F "\t" -v output="$OUTPUT" '\''
{
    pkg = $1

    if (pkg ~ /\/testing(\/|$)/ ||
        pkg ~ /\/testutil(\/|$)/) {
        next
    }

    count = 0

    for (i = 2; i <= NF; i++) {
        if ($i ~ /^k8s\.io\/kubernetes\/pkg\// &&
            $i !~ /\/testing(\/|$)/ &&
            $i !~ /\/testutil(\/|$)/) {
            count++
        }
    }

    print count "\t" pkg >> output

    total += count
    packages++

    if (count > max) {
        max = count
        maxpkg = pkg
    }
}
END {
    printf "Packages analysed: %d\n", packages
    printf "Average direct internal dependencies: %.2f\n", total / packages
    printf "Maximum direct internal dependencies: %d\n", max
    printf "Most coupled package: %s\n", maxpkg
}
'\''

echo
echo "=== Top 20 most coupled packages ==="
sort -nr "$OUTPUT" | head -n 20
'