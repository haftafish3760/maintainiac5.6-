import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maintenance setup uses the shared receipt capture system', () async {
    final file = File('lib/screens/maintenance/maintenance_setup_screen.dart');
    final source = await file.readAsString();

    expect(
      source,
      contains("shared/widgets/receipt_capture/receipt_capture.dart"),
    );
    expect(source, contains('SharedReceiptAttachmentPanel'));
    expect(source, contains('ReceiptCaptureArea.maintenanceRepair'));
    expect(source, isNot(contains('receipt_capture_section.dart')));
  });
}
