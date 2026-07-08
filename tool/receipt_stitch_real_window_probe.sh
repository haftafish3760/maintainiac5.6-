#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [[ "$#" -lt 1 ]]; then
  echo "Usage: $0 <tall-receipt-image> [window-height] [window-stride]" >&2
  exit 64
fi

source_image="$1"
if [[ ! -f "$source_image" ]]; then
  echo "Missing receipt image: $source_image" >&2
  exit 66
fi

export RECEIPT_STITCH_REAL_TALL_IMAGE="$source_image"
if [[ "${2:-}" != "" ]]; then
  export RECEIPT_STITCH_REAL_WINDOW_HEIGHT="$2"
fi
if [[ "${3:-}" != "" ]]; then
  export RECEIPT_STITCH_REAL_WINDOW_STRIDE="$3"
fi

flutter test \
  test/receipt_stitching_real_fixture_probe_test.dart \
  --plain-name 'real tall receipt probe crops local receipt windows before stitching' \
  -r compact
