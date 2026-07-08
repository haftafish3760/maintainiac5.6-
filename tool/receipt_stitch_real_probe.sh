#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [[ "$#" -lt 2 ]]; then
  echo "Usage: $0 <receipt-section-1> <receipt-section-2> [receipt-section-3 ...]" >&2
  echo "Set RECEIPT_STITCH_REAL_EXPECT=stitched to require a stitched output." >&2
  exit 64
fi

joined=""
for path in "$@"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing receipt image: $path" >&2
    exit 66
  fi
  if [[ -z "$joined" ]]; then
    joined="$path"
  else
    joined="${joined}|${path}"
  fi
done

RECEIPT_STITCH_REAL_PATHS="$joined" \
  flutter test test/receipt_stitching_real_fixture_probe_test.dart -r compact
