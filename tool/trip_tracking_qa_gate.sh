#!/usr/bin/env bash
set -u

if [ "$#" -eq 0 ]; then
  echo "TRIP_QA_FAIL missing_test_target"
  exit 64
fi

log_file="${TMPDIR:-/tmp}/maintainiac_trip_qa_$(date +%s).log"
if flutter test "$@" --reporter compact >"$log_file" 2>&1; then
  echo "TRIP_QA_PASS"
  exit 0
fi

echo "TRIP_QA_FAIL log=$log_file"
exit 1
