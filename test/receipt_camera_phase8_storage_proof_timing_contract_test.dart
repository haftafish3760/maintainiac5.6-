import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phase 8 keeps storage proof settings behind attached receipt proof', () async {
    final publishHelpers = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart',
    ).readAsString();
    final settingsSheet = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
    ).readAsString();

    expect(publishHelpers, contains('hasSavedReceiptProof:'));
    expect(
      publishHelpers,
      contains('_photoPaths.isNotEmpty || _documentAttachments.isNotEmpty'),
    );
    expect(settingsSheet, contains('required this.hasSavedReceiptProof'));
    expect(settingsSheet, contains('final bool hasSavedReceiptProof;'));
    expect(settingsSheet, contains('if (hasSavedReceiptProof) ...['));
    expect(
      settingsSheet,
      contains('_ReceiptDataSaverDefaultPicker(settings: settings)'),
    );
    expect(
      settingsSheet,
      contains(
        'Saved Receipt Proof Size appears after your first receipt photo or file is attached.',
      ),
    );
    expect(
      settingsSheet,
      contains(
        'Changes save as soon as you tap a switch. Apply Settings closes this screen. Saved proof size appears after you capture or attach a receipt first.',
      ),
    );
  });
}
