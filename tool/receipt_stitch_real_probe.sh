#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
flutter_command="${FLUTTER_BIN:-flutter}"

if [[ "$#" -lt 2 ]]; then
  echo "Usage: $0 <receipt-section-1> <receipt-section-2> [receipt-section-3 ...]" >&2
  echo "Set RECEIPT_STITCH_REAL_EXPECT=stitched to require a stitched output." >&2
  exit 64
fi

joined=""
source_paths=()
source_hashes=()
for path in "$@"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing receipt image: $path" >&2
    exit 66
  fi
  source_paths+=("$path")
  source_hashes+=("$(shasum -a 256 "$path" | awk '{print $1}')")
  if [[ -z "$joined" ]]; then
    joined="$path"
  else
    joined="${joined}|${path}"
  fi
done

RECEIPT_STITCH_REAL_PATHS="$joined" \
  "$flutter_command" test test/receipt_stitching_real_fixture_probe_test.dart -r compact

for index in "${!source_paths[@]}"; do
  current_hash="$(shasum -a 256 "${source_paths[$index]}" | awk '{print $1}')"
  if [[ "$current_hash" != "${source_hashes[$index]}" ]]; then
    echo "Receipt stitch altered source image: ${source_paths[$index]}" >&2
    exit 70
  fi
done

echo "Receipt stitch source integrity: PASS"
