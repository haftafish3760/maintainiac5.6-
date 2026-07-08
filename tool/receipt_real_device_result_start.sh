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
snapshot_root="${TMPDIR:-/tmp}/maintainiac_receipt_camera_device_snapshot"
snapshot_dir="$snapshot_root/${date_stamp}-${safe_slug}"

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

cp "$template_path" "$output_path"

bash tool/receipt_camera_real_device_snapshot.sh "$snapshot_dir" >/dev/null

python3 - "$output_path" "$timestamp" "$branch" "$commit" "$workspace" "$snapshot_dir" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
timestamp, branch, commit, workspace, snapshot_dir = sys.argv[2:]
text = path.read_text()

def summarize_log(log_path: Path, no_devices_patterns: list[str]) -> str:
    if not log_path.exists():
        return "missing snapshot log; inspect setup"

    raw = log_path.read_text()
    if "SKIPPED missing command:" in raw:
        missing = raw.split("SKIPPED missing command:", 1)[1].strip().splitlines()[0]
        return f"skipped; missing command {missing}"
    if "EXIT_CODE " in raw:
        return "command failed; inspect linked log"

    payload_lines = [
        line.strip()
        for line in raw.splitlines()
        if line.strip() and not line.startswith("COMMAND ")
    ]
    payload = "\n".join(payload_lines)
    if any(pattern in payload for pattern in no_devices_patterns):
        return "captured; no devices listed"
    if not payload_lines:
        return "captured; no device details reported"
    return "captured; inspect linked log"

snapshot_path = Path(snapshot_dir)
flutter_summary = summarize_log(
    snapshot_path / "flutter_devices.txt",
    ["No devices were found", "NO DEVICES LISTED"],
)
adb_summary = summarize_log(
    snapshot_path / "adb_devices.txt",
    ["List of devices attached"],
)
xcrun_summary = summarize_log(
    snapshot_path / "xcrun_devices.txt",
    ["NO DEVICES LISTED", "SKIPPED non-Darwin host"],
)

metadata_block = (
    "## Environment And Device Matrix\n\n"
    f"- Workspace: `{workspace}`\n"
    f"- Flutter devices snapshot: {flutter_summary}\n"
    f"- ADB devices snapshot: {adb_summary}\n"
    f"- Xcode devices snapshot: {xcrun_summary}\n\n"
    "List the device classes covered in this session:"
)
text = text.replace(
    "## Environment And Device Matrix\n\nList the device classes covered in this session:",
    metadata_block,
    1,
)

replacements = {
    "- Date:": f"- Date: {timestamp}",
    "- Branch:": f"- Branch: {branch}",
    "- Commit:": f"- Commit: {commit}",
    "- Build type:": "- Build type: NOT RUN YET",
    "- Tester:": "- Tester: NOT FILLED YET",
    "- Devices:": "- Devices: metadata only; verify during manual run",
    "- Receipt set:": "- Receipt set: NOT FILLED YET",
    "- Metadata snapshot summary:": f"- Metadata snapshot summary: `{snapshot_dir}/summary.txt`",
    "- Flutter devices snapshot log:": f"- Flutter devices snapshot log: `{snapshot_dir}/flutter_devices.txt`",
    "- ADB devices snapshot log:": f"- ADB devices snapshot log: `{snapshot_dir}/adb_devices.txt`",
    "- Xcode devices snapshot log:": f"- Xcode devices snapshot log: `{snapshot_dir}/xcrun_devices.txt`",
}
for old, new in replacements.items():
    text = text.replace(old, new, 1)
path.write_text(text)
PY

echo "$output_path"
