import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'iOS receipt camera settings stay focused on active capture controls',
    () async {
      final source = await File(
        'ios/Runner/ReceiptCameraFullScreenSettingsViewController.swift',
      ).readAsString();

      expect(
        source,
        contains(
          'Saved receipt preferences are available from Receipt Settings before capture.',
        ),
      );
      expect(
        source,
        isNot(contains('Camera only. These controls affect receipt capture.')),
      );
      expect(source, contains('Long receipt mode'));
      expect(source, contains('Automatic capture'));
      expect(source, contains('Receipt edge guidance'));
      expect(source, contains('camera.longReceiptMode = enabled'));
      expect(source, contains('camera.autoCaptureEnabled = enabled'));
      expect(source, contains('camera.edgeDetectionEnabled = enabled'));
    },
  );
}
