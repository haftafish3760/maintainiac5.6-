#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Usage: tool/receipt_real_device_result_start.sh [slug]

Creates a privacy-safe real-device receipt-camera result note from the camera
template. This script records metadata only. It does not install, launch, tap,
or navigate any device UI.
EOF
  exit 0
fi

slug="${1:-device-batch}"
safe_slug="$(printf '%s' "$slug" | tr '[:space:]' '-' | tr -cd '[:alnum:]-_')"
date_stamp="$(date '+%Y-%m-%d')"
timestamp="$(date '+%Y-%m-%d %H:%M:%S %Z')"

template_path="docs/receipt_real_device_result_template.md"
output_dir="docs/receipt_real_device_runs"
output_path="$output_dir/${date_stamp}-${safe_slug}.md"

mkdir -p "$output_dir"

if [[ ! -f "$template_path" ]]; then
  echo "Missing template: $template_path" >&2
  exit 1
fi

if [[ -e "$output_path" ]]; then
  echo "Refusing to overwrite existing result note: $output_path" >&2
  exit 1
fi

branch="$(git branch --show-current 2>/dev/null || echo unknown)"
commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
workspace="$(pwd -P)"

flutter_summary="NOT CHECKED"
adb_summary="NOT CHECKED"
xcrun_summary="NOT CHECKED"

if command -v flutter >/dev/null 2>&1; then
  flutter_summary="$(
    flutter devices 2>/dev/null | awk 'NF { print }' | paste -sd ' | ' - || true
  )"
  flutter_summary="${flutter_summary:-NO DEVICES LISTED}"
fi

if command -v adb >/dev/null 2>&1; then
  adb_summary="$(
    adb devices -l 2>/dev/null | awk 'NR > 1 && NF { print }' | paste -sd ' | ' - || true
  )"
  adb_summary="${adb_summary:-NO DEVICES LISTED}"
fi

if [[ "$(uname -s)" == "Darwin" ]] && command -v xcrun >/dev/null 2>&1; then
  xcrun_summary="$(
    xcrun xctrace list devices 2>/dev/null | awk 'NF { print }' | head -n 5 | paste -sd ' | ' - || true
  )"
  xcrun_summary="${xcrun_summary:-NO DEVICES LISTED}"
fi

cp "$template_path" "$output_path"

python3 - "$output_path" "$timestamp" "$branch" "$commit" "$workspace" "$flutter_summary" "$adb_summary" "$xcrun_summary" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
timestamp, branch, commit, workspace, flutter_summary, adb_summary, xcrun_summary = sys.argv[2:]
text = path.read_text()
replacements = {
    "- Date:": f"- Date: {timestamp}",
    "- Branch:": f"- Branch: {branch}",
    "- Commit:": f"- Commit: {commit}",
    "- Build type:": "- Build type: NOT RUN YET",
    "- Tester:": "- Tester: NOT FILLED YET",
    "- Devices:": "- Devices: metadata only; verify during manual run",
    "- Receipt set:": "- Receipt set: NOT FILLED YET",
    "## Environment And Device Matrix": "## Environment And Device Matrix\n\n"
    f"- Workspace: `{workspace}`\n"
    f"- Flutter devices snapshot: {flutter_summary}\n"
    f"- ADB devices snapshot: {adb_summary}\n"
    f"- Xcode devices snapshot: {xcrun_summary}",
}
for old, new in replacements.items():
    text = text.replace(old, new, 1)
path.write_text(text)
PY

echo "$output_path"
