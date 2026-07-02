#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path
import re
import sys

files = [Path('docs/receipt_camera_cleanup_pass_log.md')]
files.extend(sorted(Path('docs').glob('receipt_camera_cleanup_pass_log_archive_*.md')))

if not files[0].exists():
    print('Missing active receipt camera cleanup pass log.', file=sys.stderr)
    sys.exit(1)

failed = False
total_entries = 0
pass_locations = {}
for path in files:
    text = path.read_text()
    line_count = len(text.splitlines())
    entry_count = 0
    for line_number, line in enumerate(text.splitlines(), start=1):
        match = re.match(r'^## Pass (\d+)\b', line)
        if not match:
            continue
        entry_count += 1
        pass_number = match.group(1)
        pass_locations.setdefault(pass_number, []).append(f'{path}:{line_number}')
    total_entries += entry_count
    if line_count > 500:
        print(f'{path}: {line_count} lines exceeds 500-line log limit.', file=sys.stderr)
        failed = True

for pass_number, locations in sorted(pass_locations.items(), key=lambda item: int(item[0])):
    if len(locations) > 1:
        joined = ', '.join(locations)
        print(f'Pass {pass_number} appears more than once: {joined}', file=sys.stderr)
        failed = True

if total_entries == 0:
    print('No pass entries found in receipt camera cleanup pass logs.', file=sys.stderr)
    failed = True

if failed:
    sys.exit(1)

print(f'Receipt cleanup log gate: files={len(files)} entries={total_entries} maxLines=500')
PY
