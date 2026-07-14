#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
flutter_command="${FLUTTER_BIN:-flutter}"

if [[ "$#" -lt 1 ]]; then
  echo "Usage: $0 <tall-receipt-image> [window-height] [window-stride]" >&2
  echo "Set RECEIPT_STITCH_REAL_EXPECT=stitched to require a stitched output." >&2
  exit 64
fi

source_image="$1"
if [[ ! -f "$source_image" ]]; then
  echo "Missing receipt image: $source_image" >&2
  exit 66
fi
source_hash="$(shasum -a 256 "$source_image" | awk '{print $1}')"

if [[ -n "${2:-}" && ! "$2" =~ ^[1-9][0-9]*$ ]]; then
  echo "Window height must be a positive integer: $2" >&2
  exit 64
fi
if [[ -n "${3:-}" && ! "$3" =~ ^[1-9][0-9]*$ ]]; then
  echo "Window stride must be a positive integer: $3" >&2
  exit 64
fi

export RECEIPT_STITCH_REAL_TALL_IMAGE="$source_image"
if [[ "${2:-}" != "" ]]; then
  export RECEIPT_STITCH_REAL_WINDOW_HEIGHT="$2"
fi
if [[ "${3:-}" != "" ]]; then
  export RECEIPT_STITCH_REAL_WINDOW_STRIDE="$3"
fi

"$flutter_command" test \
  test/receipt_stitching_real_fixture_probe_test.dart \
  --plain-name 'real tall receipt probe crops local receipt windows before stitching' \
  -r compact

current_hash="$(shasum -a 256 "$source_image" | awk '{print $1}')"
if [[ "$current_hash" != "$source_hash" ]]; then
  echo "Receipt stitch altered source image: $source_image" >&2
  exit 70
fi

echo "Receipt stitch source integrity: PASS"
