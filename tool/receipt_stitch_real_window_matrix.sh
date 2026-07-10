#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [[ "$#" -lt 1 ]]; then
  echo "Usage: $0 <tall-receipt-image> [height:stride ...]" >&2
  echo "Example: $0 receipt.jpg 900:620 900:760 720:520" >&2
  echo "Set RECEIPT_STITCH_REAL_EXPECT=stitched to require stitched output." >&2
  exit 64
fi

source_image="$1"
shift

if [[ ! -f "$source_image" ]]; then
  echo "Missing receipt image: $source_image" >&2
  exit 66
fi

configs=("$@")
if [[ "${#configs[@]}" -eq 0 ]]; then
  configs=("900:620" "900:760" "720:520")
fi

matrix=""
for config in "${configs[@]}"; do
  if [[ "$config" != *:* ]]; then
    echo "Invalid matrix config: $config" >&2
    echo "Expected height:stride, for example 900:620." >&2
    exit 64
  fi
  height="${config%%:*}"
  stride="${config##*:}"
  echo "Receipt stitch real-window matrix: ${height}x${stride}"
  if [[ -z "$matrix" ]]; then
    matrix="${height}:${stride}"
  else
    matrix="${matrix}|${height}:${stride}"
  fi
done

RECEIPT_STITCH_REAL_TALL_IMAGE="$source_image" \
RECEIPT_STITCH_REAL_WINDOW_MATRIX="$matrix" \
  flutter test \
    test/receipt_stitching_real_fixture_probe_test.dart \
    --plain-name 'real tall receipt matrix probes multiple crop windows in one run' \
    -r compact

echo "Receipt stitch real-window matrix: PASS"
