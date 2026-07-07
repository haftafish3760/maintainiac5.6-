import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ios native asset preflight script pins arm64 objective_c checks', () {
    final script = File(
      'tool/receipt_camera_ios_native_asset_preflight.sh',
    ).readAsStringSync();

    expect(
      script,
      contains(
        'Usage: tool/receipt_camera_ios_native_asset_preflight.sh [runner_app_dir]',
      ),
    );
    expect(script, contains('build/ios/iphoneos/Runner.app'));
    expect(script, contains('NativeAssetsManifest.json'));
    expect(script, contains('objective_c.framework/objective_c'));
    expect(script, contains('"ios_arm64"'));
    expect(script, contains('lipo -info'));
    expect(script, contains('status=ok'));
    expect(
      script,
      contains('separate Flutter debug/native-assets tooling blocker'),
    );
    expect(script, isNot(contains('adb shell input')));
  });

  test('camera guards include ios native asset preflight syntax coverage', () {
    final fastGate = File('tool/receipt_fast_guard_gate.sh').readAsStringSync();

    expect(
      fastGate,
      contains('tool/receipt_camera_ios_native_asset_preflight.sh'),
    );
  });
}
