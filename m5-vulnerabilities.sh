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

echo "=== M5: Known Reachable Vulnerabilities ==="
echo "Kubernetes commit: $ACTUAL_COMMIT"

"$BASH_BIN" ./build/run.sh bash -c '
export HOME=/tmp
export GOCACHE=/tmp/go-build
export GOPATH=/tmp/gopath

echo
echo "=== Installing govulncheck v1.9.0 ==="

go install golang.org/x/vuln/cmd/govulncheck@v1.9.0

echo
echo "=== Running vulnerability scan ==="

set +e
$GOPATH/bin/govulncheck ./cmd/... ./pkg/...
STATUS=$?
set -e

echo
echo "=== GOVULNCHECK EXIT CODE: $STATUS ==="

# govulncheck returns a non-zero exit code when vulnerabilities are found.
# The script itself should still complete successfully.
exit 0
'