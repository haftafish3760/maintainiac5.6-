import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS receipt settings open as a full-screen route', () async {
    final layout = await File(
      'ios/Runner/ReceiptCameraViewControllerLayout.swift',
    ).readAsString();
    final settings = await File(
      'ios/Runner/ReceiptCameraViewControllerSessionSettings.swift',
    ).readAsString();
    final route = await File(
      'ios/Runner/ReceiptCameraFullScreenSettingsViewController.swift',
    ).readAsString();

    expect(layout, contains('#selector(openReceiptCameraSettingsFullScreen)'));
    expect(settings, contains('settings.modalPresentationStyle = .fullScreen'));
    expect(
      route,
      contains('final class ReceiptCameraFullScreenSettingsViewController'),
    );
    expect(route, contains('view.safeAreaLayoutGuide'));
    expect(
      route,
      contains(
        'Receipt Assist, saved-photo, and account preferences stay in Expense Settings.',
      ),
    );
    expect(route, contains('Automatic capture'));
    expect(route, contains('Receipt edge guidance'));
    expect(route, isNot(contains('SAVED PROOF SIZE')));
    expect(route, isNot(contains('Help fill receipt details')));
  });
}
