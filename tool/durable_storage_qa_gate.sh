#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="${TMPDIR:-/tmp}/maintainiac_durable_qa_$(date +%s).log"

CORE_TESTS=(
  test/app_storage_guard_test.dart
  test/app_storage_warning_preferences_test.dart
  test/maintainiac_draft_autosave_coordinator_test.dart
  test/maintainiac_draft_notification_dispatcher_test.dart
  test/maintainiac_draft_retention_reminder_test.dart
  test/maintainiac_durable_record_store_test.dart
  test/maintainiac_durable_cloud_backup_gateway_test.dart
  test/maintainiac_durable_cloud_revision_store_test.dart
  test/maintainiac_durable_cloud_restore_gateway_test.dart
  test/maintainiac_cloud_restore_runner_test.dart
  test/maintainiac_restore_callable_source_test.dart
  test/maintainiac_restore_plan_client_test.dart
  test/maintainiac_restore_session_client_test.dart
  test/maintainiac_hosted_restore_progress_test.dart
  test/maintainiac_durable_storage_facade_test.dart
  test/maintainiac_firestore_account_isolation_test.dart
  test/maintainiac_firestore_atomic_batch_test.dart
  test/maintainiac_firestore_batch_bounds_test.dart
  test/maintainiac_firestore_durable_record_codec_test.dart
  test/maintainiac_firestore_queue_deduplication_test.dart
  test/maintainiac_firestore_queue_integrity_test.dart
  test/maintainiac_firestore_revision_policy_test.dart
  test/maintainiac_firestore_scope_policy_test.dart
  test/maintainiac_firestore_upload_free_sync_test.dart
  test/maintainiac_firebase_durable_storage_runtime_test.dart
  test/maintainiac_firestore_upload_queue_test.dart
  test/maintainiac_restore_applier_test.dart
  test/maintainiac_restore_batch_processor_test.dart
  test/maintainiac_restore_session_store_test.dart
  test/maintainiac_record_ordering_test.dart
  test/maintainiac_sync_orchestrator_test.dart
  test/maintainiac_sync_settings_test.dart
)

ANALYZE_TARGETS=(
  lib/shared/durable_storage
  lib/shared/firebase
  lib/shared/records
  lib/shared/storage
  lib/shared/sync
)

usage() {
  cat <<'EOF'
Usage: tool/durable_storage_qa_gate.sh [--core|--analyze|--emulators|test files...]

  --core       Run the bounded shared durable-storage regression suite (default)
  --analyze    Analyze only shared durable-storage source directories
  --emulators  Run the existing local demo-project Firebase emulator suite
  test files   Run only the explicitly supplied Flutter test files

The gate writes verbose output to a temporary log and prints only PASS or FAIL.
It never targets a live Firebase project.
EOF
}

run_quiet() {
  if "$@" >"$LOG_FILE" 2>&1; then
    echo "DURABLE_STORAGE_QA_PASS"
    return 0
  fi
  echo "DURABLE_STORAGE_QA_FAIL log=$LOG_FILE" >&2
  return 1
}

cd "$ROOT_DIR"

case "${1:---core}" in
  --core)
    if [ "$#" -gt 1 ]; then
      echo "DURABLE_STORAGE_QA_FAIL --core takes no additional arguments" >&2
      exit 64
    fi
    run_quiet flutter test "${CORE_TESTS[@]}" --reporter compact
    ;;
  --analyze)
    if [ "$#" -gt 1 ]; then
      echo "DURABLE_STORAGE_QA_FAIL --analyze takes no additional arguments" >&2
      exit 64
    fi
    run_quiet flutter analyze "${ANALYZE_TARGETS[@]}"
    ;;
  --emulators)
    if [ "$#" -gt 1 ]; then
      echo "DURABLE_STORAGE_QA_FAIL --emulators takes no arguments" >&2
      exit 64
    fi
    run_quiet bash tool/run_firebase_emulator_tests.sh
    ;;
  -h|--help)
    usage
    ;;
  --*)
    echo "DURABLE_STORAGE_QA_FAIL unknown option: $1" >&2
    usage >&2
    exit 64
    ;;
  *)
    for target in "$@"; do
      case "$target" in
        test/*_test.dart) ;;
        *)
          echo "DURABLE_STORAGE_QA_FAIL invalid test target: $target" >&2
          exit 64
          ;;
      esac
      if [ ! -f "$target" ]; then
        echo "DURABLE_STORAGE_QA_FAIL missing test target: $target" >&2
        exit 66
      fi
    done
    run_quiet flutter test "$@" --reporter compact
    ;;
esac
