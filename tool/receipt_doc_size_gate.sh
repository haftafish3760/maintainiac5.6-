#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path
import sys

patterns = [
    'expense_command_center_ocr_contract*.md',
    'firebase_sync*schema_spec.md',
    'receipt_camera_ocr*.md',
    'receipt_camera_world_class_readiness.md',
    'receipt_real_device_test_script.md',
]

exempt_patterns = [
    'receipt_camera_ocr_handoff_*.md',
]

paths = []
for pattern in patterns:
    paths.extend(Path('docs').glob(pattern))

exempt_paths = set()
for pattern in exempt_patterns:
    exempt_paths.update(Path('docs').glob(pattern))

failed = False
for path in sorted(set(paths) - exempt_paths):
    line_count = len(path.read_text().splitlines())
    if line_count > 500:
        print(f'{path}: {line_count} lines exceeds 500-line receipt doc limit.', file=sys.stderr)
        failed = True

if failed:
    sys.exit(1)

print(f'Receipt doc size gate: files={len(set(paths))} maxLines=500')
PY
