#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Usage: tool/receipt_camera_ios_native_asset_preflight.sh [runner_app_dir]

Verifies that the built iPhone receipt-camera app bundle contains the expected
arm64 native asset wiring for objective_c before real-device QA.

Default runner_app_dir:
  build/ios/iphoneos/Runner.app
EOF
  exit 0
fi

runner_app_dir="${1:-build/ios/iphoneos/Runner.app}"
manifest_path="$runner_app_dir/Frameworks/App.framework/flutter_assets/NativeAssetsManifest.json"
dylib_path="$runner_app_dir/Frameworks/objective_c.framework/objective_c"

fail() {
  echo "receipt_camera_ios_native_asset_preflight: $*" >&2
  exit 1
}

[[ -d "$runner_app_dir" ]] || fail "Missing Runner.app bundle at $runner_app_dir"
[[ -f "$manifest_path" ]] || fail "Missing NativeAssetsManifest at $manifest_path"
[[ -f "$dylib_path" ]] || fail "Missing objective_c framework binary at $dylib_path"

manifest_contents="$(cat "$manifest_path")"
[[ "$manifest_contents" == *'"ios_arm64"'* ]] || fail "NativeAssetsManifest does not advertise ios_arm64"
[[ "$manifest_contents" == *'objective_c.framework/objective_c'* ]] || fail "NativeAssetsManifest does not point to objective_c.framework/objective_c"

lipo_output="$(lipo -info "$dylib_path" 2>&1 || true)"
file_output="$(file "$dylib_path" 2>&1 || true)"

[[ "$lipo_output" == *'arm64'* ]] || fail "objective_c framework is missing arm64: $lipo_output"
if [[ "$lipo_output" == *'x86_64'* && "$lipo_output" != *'arm64'* ]]; then
  fail "objective_c framework is x86_64-only: $lipo_output"
fi

cat <<EOF
receipt_camera_ios_native_asset_preflight
runner_app_dir=$runner_app_dir
native_assets_manifest=$manifest_path
objective_c_binary=$dylib_path
file=$file_output
lipo=$lipo_output
status=ok
next_action=If flutter run still loses the device after install, treat that as a separate Flutter debug/native-assets tooling blocker rather than a stale x86_64 camera bundle.
EOF
