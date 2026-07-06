import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'release-one camera controls prioritize receipt workflow over pro tools',
    () {
      final map = File(
        'docs/receipt_camera_completion_map.md',
      ).readAsStringSync().toLowerCase();
      final android = File(
        'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraReviewSettings.kt',
      ).readAsStringSync();
      final ios = File(
        'ios/Runner/ReceiptCameraViewControllerControls.swift',
      ).readAsStringSync();

      expect(map, contains('manual shutter'));
      expect(map, contains('torch when'));
      expect(map, contains('basic brightness control'));
      expect(map, contains('phone-native autofocus'));
      expect(map, contains('unproven live quality claims are default-off'));
      expect(map, contains('focus slider'));
      expect(map, contains('focus slider is not a'));
      expect(map, contains('release blocker'));
      expect(android, contains('enableTorch(torchOn)'));
      expect(android, contains('Turn light on'));
      expect(ios, contains('cameraDevice.torchMode'));
      expect(ios, contains('Turn light on'));
    },
  );
}
