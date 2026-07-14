import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense receipt attachment explains when automatic filling is off', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_panel_build.dart',
    ).readAsStringSync();

    expect(source, contains("widget.area == ReceiptCaptureArea.expenses"));
    expect(source, contains('Automatic filling is off.'));
    expect(source, contains('openReceiptCaptureSettings()'));
    expect(
      source,
      contains("TextButton(onPressed: onTurnOn, child: const Text('Turn On'))"),
    );
  });
}
