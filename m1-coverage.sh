#!/usr/bin/env bash
set -euo pipefail

EXPECTED_COMMIT="98d0129cf21ce0871637ae36e67b5ff82d3db50d"

# Path to the Kubernetes repository.
# You can optionally pass another path as the first argument.
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

echo "=== M1: Statement Test Coverage ==="
echo "Kubernetes commit: $ACTUAL_COMMIT"

echo
echo "=== Scheduler ==="

"$BASH_BIN" ./build/run.sh bash -c '
export HOME=/tmp
export GOCACHE=/tmp/go-build
export GOPATH=/tmp/gopath

go test -count=1 \
  -coverprofile=coverage-scheduler.out \
  ./pkg/scheduler/...

go tool cover -func=coverage-scheduler.out | tail -n 1
'

echo
echo "=== Controller ==="

"$BASH_BIN" ./build/run.sh bash -c '
export HOME=/tmp
export GOCACHE=/tmp/go-build
export GOPATH=/tmp/gopath

go test -count=1 \
  -coverprofile=coverage-controller.out \
  ./pkg/controller/...

go tool cover -func=coverage-controller.out | tail -n 1
'

echo
echo "=== Kubelet ==="

"$BASH_BIN" ./build/run.sh bash -c '
export HOME=/tmp
export GOCACHE=/tmp/go-build
export GOPATH=/tmp/gopath

go test -count=1 \
  -coverprofile=coverage-kubelet.out \
  ./pkg/kubelet/...

go tool cover -func=coverage-kubelet.out | tail -n 1
'
