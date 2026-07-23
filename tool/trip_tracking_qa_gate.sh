#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob

usage() {
  cat <<'EOF'
Usage:
  trip_tracking_qa_gate.sh [options] [paths...]

  No args       Run every trip-domain test (test/trip_*_test.dart)
  --all         Same as no args
  --simulations [iterations]
                Run deterministic simulation/fuzz tests and the safe benchmark
                runner (default 100, maximum 1000 iterations)
  --analyze     flutter analyze with explicit files/folders
  --android-debug  flutter build apk --debug
  -h, --help    Show this help
EOF
}

log_file="${TMPDIR:-/tmp}/maintainiac_trip_qa_$(date +%s).log"

collect_trip_tracking_tests() {
  local -a tests=(
    test/trip_*_test.dart
  )
  if [ ${#tests[@]} -eq 0 ]; then
    echo "TRIP_QA_FAIL no_trip_tracking_tests_found"
    exit 1
  fi
  echo "${tests[@]}"
}

if [ "$#" -eq 0 ]; then
  test_targets=($(collect_trip_tracking_tests))
  command=(flutter test "${test_targets[@]}" --reporter compact)
elif [ "$1" = "--all" ]; then
  shift
  if [ "$#" -ne 0 ]; then
    echo "TRIP_QA_FAIL --all takes no additional args"
    exit 64
  fi
  test_targets=($(collect_trip_tracking_tests))
  command=(flutter test "${test_targets[@]}" --reporter compact)
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  usage
  exit 64
elif [ "$1" = "--simulations" ]; then
  shift
  simulation_iterations="${1:-100}"
  if [ "$#" -gt 1 ] ||
    ! [[ "$simulation_iterations" =~ ^[0-9]+$ ]] ||
    [ "$simulation_iterations" -lt 1 ] ||
    [ "$simulation_iterations" -gt 1000 ]; then
    echo "TRIP_QA_FAIL simulations_require_iterations_1_to_1000"
    exit 64
  fi
  simulation_tests=(
    test/trip_*simulation*_test.dart
    test/trip_*fuzz_test.dart
  )
  if [ ${#simulation_tests[@]} -eq 0 ]; then
    echo "TRIP_QA_FAIL no_simulation_tests_found"
    exit 1
  fi
  if ! flutter test "${simulation_tests[@]}" --reporter compact \
    >"$log_file" 2>&1; then
    echo "TRIP_QA_FAIL log=$log_file"
    exit 1
  fi
  if ! dart run tool/trip_tracking_simulation_runner.dart \
    "--iterations=$simulation_iterations" >>"$log_file" 2>&1; then
    echo "TRIP_QA_FAIL log=$log_file"
    exit 1
  fi
  echo "TRIP_QA_PASS"
  exit 0
elif [ "$1" = "--android-debug" ]; then
  command=(flutter build apk --debug)
elif [ "$1" = "--analyze" ]; then
  shift
  if [ "$#" -eq 0 ]; then
    echo "TRIP_QA_FAIL --analyze requires at least one path"
    exit 64
  fi
  command=(flutter analyze "$@")
else
  command=(flutter test "$@" --reporter compact)
fi

if "${command[@]}" >"$log_file" 2>&1; then
  echo "TRIP_QA_PASS"
  exit 0
fi

echo "TRIP_QA_FAIL log=$log_file"
exit 1
