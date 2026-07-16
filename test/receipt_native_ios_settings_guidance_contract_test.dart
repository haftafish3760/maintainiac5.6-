import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'iOS receipt camera settings keep live guidance focused on capture workflow',
    () async {
      final labels = await File(
        'ios/Runner/ReceiptCameraViewControllerLabels.swift',
      ).readAsString();
      final fullScreenSettings = await File(
        'ios/Runner/ReceiptCameraFullScreenSettingsViewController.swift',
      ).readAsString();

      final reviewStyleStart = labels.indexOf(
        'func setReceiptReviewStyle(_ value: String)',
      );
      final reviewStyleEnd = labels.indexOf('\n  func setDataSaverLevel', reviewStyleStart);
      expect(reviewStyleStart, greaterThanOrEqualTo(0));
      expect(reviewStyleEnd, greaterThan(reviewStyleStart));
      final reviewStyleBlock = labels.substring(reviewStyleStart, reviewStyleEnd);

      expect(reviewStyleBlock, contains('reviewDepth = value'));
      expect(reviewStyleBlock, contains('updateSettingsStatusStrip()'));
      expect(reviewStyleBlock, isNot(contains('guidanceLabel.text')));
      expect(reviewStyleBlock, isNot(contains('Detailed receipt details are on.')));
      expect(reviewStyleBlock, isNot(contains('Price-only receipt details are on.')));

      final dataSaverStart = labels.indexOf('func setDataSaverLevel(_ value: String)');
      final dataSaverEnd = labels.indexOf('\n  func storageSafetyDetail()', dataSaverStart);
      expect(dataSaverStart, greaterThanOrEqualTo(0));
      expect(dataSaverEnd, greaterThan(dataSaverStart));
      final dataSaverBlock = labels.substring(dataSaverStart, dataSaverEnd);

      expect(dataSaverBlock, contains('dataSaverLevel = value'));
      expect(dataSaverBlock, contains('updateSettingsStatusStrip()'));
      expect(dataSaverBlock, isNot(contains('guidanceLabel.text')));
      expect(dataSaverBlock, isNot(contains('Save-space proof size set to')));
      expect(dataSaverBlock, isNot(contains('OCR still reads the temporary full-quality photo first.')));

      expect(
        fullScreenSettings,
        isNot(
          contains('"Automatic brightness assist", "Asistencia automática de brillo"'),
        ),
      );
      expect(
        fullScreenSettings,
        contains('"Receipt framing checks", "Revisiones de encuadre del recibo"'),
      );
      expect(
        fullScreenSettings,
        contains('camera.setReceiptGuidanceWarningsEnabled(enabled)'),
      );
      expect(
        fullScreenSettings,
        contains('if !enabled && camera.autoCaptureEnabled {'),
      );
      expect(
        fullScreenSettings,
        contains('camera.guidanceLabel.text = camera.autoCaptureBlockedMessage()'),
      );
      expect(fullScreenSettings, contains('camera.latestAutoCaptureStatus = "off"'));
      expect(
        fullScreenSettings,
        contains('Long receipt mode is unavailable for this device or storage setting.'),
      );
      expect(
        fullScreenSettings,
        contains('Automatic capture needs receipt edge guidance.'),
      );
      expect(
        fullScreenSettings,
        contains('Maintainiac does not use tap-to-focus.'),
      );
      expect(fullScreenSettings, isNot(contains('camera.assistedReceiptFill')));
      expect(fullScreenSettings, isNot(contains('setReceiptReviewStyle')));
    },
  );
}
