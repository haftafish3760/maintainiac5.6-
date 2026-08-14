import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS receipt camera permission is declared, compiled, and requested', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    final podfile = File('ios/Podfile').readAsStringSync();
    final permissionFlow = File(
      'lib/shared/widgets/receipt_capture/receipt_camera_permission.dart',
    ).readAsStringSync();

    expect(infoPlist, contains('<key>NSCameraUsageDescription</key>'));
    expect(podfile, contains("target.name == 'permission_handler_apple'"));
    expect(podfile, contains("'PERMISSION_CAMERA=1'"));
    expect(permissionFlow, contains('Permission.camera.request()'));
  });
}
