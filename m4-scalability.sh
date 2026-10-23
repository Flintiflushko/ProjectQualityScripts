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

echo "=== M4: Scheduler Scalability ==="
echo "Kubernetes commit: $ACTUAL_COMMIT"

echo
echo "=== Installing etcd ==="

"$BASH_BIN" ./build/run.sh bash -c '
export HOME=/tmp
export GOCACHE=/tmp/go-build
export GOPATH=/tmp/gopath

./hack/install-etcd.sh
'

run_benchmark() {
    WORKLOAD="$1"

    echo
    echo "=== Benchmark: ${WORKLOAD} ==="

    "$BASH_BIN" ./build/run.sh bash -c "
export HOME=/tmp
export GOCACHE=/tmp/go-build
export GOPATH=/tmp/gopath
export PATH=\"\$(pwd)/third_party/etcd:\$PATH\"

make test-integration \
  WHAT=./test/integration/scheduler_perf/misc \
  KUBE_CACHE_MUTATION_DETECTOR=false \
  KUBE_TIMEOUT=-timeout=1h \
  ETCD_LOGLEVEL=warn \
  FULL_LOG=y \
  ARTIFACTS=/tmp \
  SHORT=-short=false \
  KUBE_TEST_ARGS=\"-run=^$ -benchtime=1x \
-bench=BenchmarkPerfScheduling/SchedulingBasic/${WORKLOAD}$ \
-perf-scheduling-label-filter=-performance\"
"
}

run_benchmark "5Nodes"
run_benchmark "500Nodes"
run_benchmark "5000Nodes"