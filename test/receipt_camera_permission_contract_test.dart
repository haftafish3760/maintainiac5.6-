import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt capture requests only the permissions it needs', () {
    final android = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final ios = File('ios/Runner/Info.plist').readAsStringSync();

    expect(android, contains('android.permission.CAMERA'));
    expect(android, isNot(contains('android.permission.READ_MEDIA_IMAGES')));
    expect(android, isNot(contains('android.permission.READ_EXTERNAL_STORAGE')));

    expect(ios, contains('NSCameraUsageDescription'));
    expect(ios, contains('only when you choose to photograph receipts'));
    expect(ios, contains('NSPhotoLibraryUsageDescription'));
    expect(ios, contains('lets you choose receipt images'));
  });
}
