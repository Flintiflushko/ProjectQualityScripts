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

if ! command -v gocognit >/dev/null 2>&1; then
    echo "Error: gocognit is not installed or not in PATH."
    exit 1
fi

IGNORE='_test|testdata|/testing/|zz_generated'

echo "=== M2: Cognitive Complexity ==="
echo "Kubernetes commit: $ACTUAL_COMMIT"

echo
echo "=== Scheduler: average ==="
gocognit \
    -ignore "$IGNORE" \
    -avg ./pkg/scheduler

echo
echo "=== Scheduler: top 20 ==="
gocognit \
    -ignore "$IGNORE" \
    -top 20 ./pkg/scheduler

echo
echo "=== Controller: average ==="
gocognit \
    -ignore "$IGNORE" \
    -avg ./pkg/controller

echo
echo "=== Controller: top 20 ==="
gocognit \
    -ignore "$IGNORE" \
    -top 20 ./pkg/controller

echo
echo "=== Kubelet: average ==="
gocognit \
    -ignore "$IGNORE" \
    -avg ./pkg/kubelet

echo
echo "=== Kubelet: top 20 ==="
gocognit \
    -ignore "$IGNORE" \
    -top 20 ./pkg/kubelet