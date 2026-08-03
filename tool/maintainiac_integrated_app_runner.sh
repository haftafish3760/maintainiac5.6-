#!/usr/bin/env bash
# Builds and records the single combined Maintainiac app from the current
# integration worktree.  A Flutter build can only include this worktree's
# checked-out files; feature branches appear in the evidence as pending until
# their accepted commits are integrated here.

set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: tool/maintainiac_integrated_app_runner.sh [options]

Create an auditable whole-app integration run from the CURRENT worktree.
This script never checks out, merges, cherry-picks, pushes, or deletes Git
history. It records unintegrated local branches so they cannot be mistaken for
code included in the build.

Options:
  --evidence                 Record Git/worktree evidence only (default).
  --analyze                  Run whole-app `flutter analyze`.
  --all-tests                Run the complete Flutter test suite serially.
  --build-android            Build one combined Android debug APK.
  --build-ios                Build one combined iOS debug app (no codesign).
  --android-serial SERIAL    Required target for Android install/launch.
  --install-android          Install the combined debug APK on that target.
  --launch-android           Launch Maintainiac on that target after install.
  --output PATH              Put evidence in PATH (default: timestamped build/).
  --help                     Show this help.

Suggested workflow:
  1. Each engineer works in an isolated feature worktree and commits there.
  2. Accepted commits are intentionally integrated into Maintainiac_5.7_Active.
  3. Run --analyze --build-android here. That APK contains every accepted
     integration change, including changes that are still uncommitted here.
  4. Only invoke --install-android when a device install is explicitly wanted.

Examples:
  tool/maintainiac_integrated_app_runner.sh --analyze --build-android
  tool/maintainiac_integrated_app_runner.sh --build-android \
    --android-serial R5CX14WC8FA --install-android --launch-android
EOF
}

run_evidence_only=true
run_analyze=false
run_all_tests=false
build_android=false
build_ios=false
install_android=false
launch_android=false
android_serial=''
output_dir=''

while [ "$#" -gt 0 ]; do
  case "$1" in
    --evidence) ;;
    --analyze) run_evidence_only=false; run_analyze=true ;;
    --all-tests) run_evidence_only=false; run_all_tests=true ;;
    --build-android) run_evidence_only=false; build_android=true ;;
    --build-ios) run_evidence_only=false; build_ios=true ;;
    --install-android) run_evidence_only=false; install_android=true ;;
    --launch-android) run_evidence_only=false; launch_android=true ;;
    --android-serial)
      shift
      android_serial="${1:?--android-serial requires a serial}"
      ;;
    --output)
      shift
      output_dir="${1:?--output requires a path}"
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      show_help >&2
      exit 2
      ;;
  esac
  shift
done

if [ "$install_android" = true ] || [ "$launch_android" = true ]; then
  if [ -z "$android_serial" ]; then
    echo "--android-serial is required for --install-android or --launch-android." >&2
    exit 2
  fi
fi

if [ "$launch_android" = true ] && [ "$install_android" = false ]; then
  echo "--launch-android requires --install-android in the same run." >&2
  exit 2
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

branch_name="$(git branch --show-current)"
timestamp="$(date '+%Y%m%d-%H%M%S')"
if [ -z "$output_dir" ]; then
  output_dir="build/maintainiac_integration_runs/$timestamp"
fi
mkdir -p "$output_dir"

integration_warning=''
case "$branch_name" in
  codex/maintainiac-5.7-integrated-*) ;;
  *) integration_warning="Current branch is not named as a 5.7 integration branch." ;;
esac

git status --short > "$output_dir/git-status.txt"
git diff --name-status > "$output_dir/git-diff-name-status.txt"
git diff --stat > "$output_dir/git-diff-stat.txt"
git log --oneline --decorate -30 > "$output_dir/git-log.txt"
git worktree list --porcelain > "$output_dir/git-worktrees.txt"
git branch --no-merged HEAD > "$output_dir/unintegrated-local-branches.txt"

{
  echo "Maintainiac integrated-app evidence"
  echo "created_at=$(date -Iseconds)"
  echo "repository=$repo_root"
  echo "branch=$branch_name"
  echo "commit=$(git rev-parse HEAD)"
  echo "worktree_dirty=$(test -n "$(git status --short)" && echo yes || echo no)"
  echo "included_source=the current worktree only"
  echo "unintegrated_branch_policy=not included until intentionally integrated here"
  if [ -n "$integration_warning" ]; then
    echo "warning=$integration_warning"
  fi
  if [ -s "$output_dir/unintegrated-local-branches.txt" ]; then
    echo "unintegrated_local_branches=yes"
  else
    echo "unintegrated_local_branches=no"
  fi
} > "$output_dir/manifest.txt"

echo "Whole-app integration evidence: $output_dir"
echo "Branch: $branch_name"
if [ -n "$integration_warning" ]; then
  echo "WARNING: $integration_warning" >&2
fi
if [ -s "$output_dir/unintegrated-local-branches.txt" ]; then
  echo "WARNING: local branches not merged into this build are listed in:" >&2
  echo "  $output_dir/unintegrated-local-branches.txt" >&2
fi

if [ "$run_evidence_only" = true ]; then
  exit 0
fi

if [ "$run_analyze" = true ]; then
  flutter analyze
fi

if [ "$run_all_tests" = true ]; then
  flutter test --concurrency=1
fi

if [ "$build_android" = true ] || [ "$install_android" = true ]; then
  flutter build apk --debug
  apk_path='build/app/outputs/flutter-apk/app-debug.apk'
  if [ ! -f "$apk_path" ]; then
    echo "Android build reported success but no debug APK was found." >&2
    exit 1
  fi
  cp "$apk_path" "$output_dir/maintainiac-integrated-debug.apk"
fi

if [ "$build_ios" = true ]; then
  flutter build ios --debug --no-codesign
fi

if [ "$install_android" = true ]; then
  if ! adb devices -l | awk -v serial="$android_serial" '$1 == serial && $2 == "device" { found = 1 } END { exit found ? 0 : 1 }'; then
    echo "Requested Android target is not connected and authorized: $android_serial" >&2
    exit 1
  fi
  adb -s "$android_serial" install -r "$apk_path"
fi

if [ "$launch_android" = true ]; then
  adb -s "$android_serial" shell monkey -p com.maintainiac 1 >/dev/null
fi

echo "Whole-app integration run completed: $output_dir"
