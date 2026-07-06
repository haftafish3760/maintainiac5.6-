import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt capture flow does not silently enable Receipt Assist', () async {
    final settingsStore = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart',
    ).readAsString();
    final flowHelpers = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_helpers.dart',
    ).readAsString();
    final nativeSettings = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_settings.dart',
    ).readAsString();
    final nativeDescriptors = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_settings_descriptors.dart',
    ).readAsString();
    final photoReviewScreen = await _readReceiptPhotoReviewSource();
    final readBoundarySource = await _readReceiptReadBoundarySource();

    expect(
      settingsStore,
      contains('_readBool(_Keys.appAssistedReceiptFill, false)'),
    );
    expect(
      settingsStore,
      contains('_readBool(_Keys.appAssistedExpenses, false)'),
    );
    expect(
      settingsStore,
      contains('_readBool(_Keys.appAssistedMaterials, false)'),
    );
    expect(
      settingsStore,
      contains('_readBool(_Keys.appAssistedMaintenance, false)'),
    );
    expect(
      flowHelpers,
      contains('settings?.appAssistedEnabledFor(area) ?? false'),
    );
    expect(nativeSettings, contains('this.assistedReceiptFill = false'));
    expect(nativeDescriptors, contains('defaultEnabled: false'));
    expect(photoReviewScreen, contains('this.assistedReceiptFill = false'));
    expect(
      photoReviewScreen,
      contains('assistedReceiptFill: widget.assistedReceiptFill'),
    );
    expect(photoReviewScreen, isNot(contains('assistedReceiptFill: true')));
    expect(
      readBoundarySource,
      contains('assistedReceiptFill: _appAssistedReceiptFillEnabled'),
    );
    expect(flowHelpers, isNot(contains('area == null ? true')));
    expect(flowHelpers, isNot(contains('?? true)')));
    expect(readBoundarySource, contains('_appAssistedReceiptFillEnabled'));
    expect(
      readBoundarySource,
      contains('appAssistedEnabledFor(widget.area) ==\n        true'),
    );
    expect(
      readBoundarySource,
      isNot(contains('appAssistedEnabledFor(widget.area) != false')),
    );
    expect(
      readBoundarySource,
      isNot(contains('appAssistedEnabledFor(widget.area) == false')),
    );
  });
}

Future<String> _readReceiptReadBoundarySource() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_panel_build.dart',
    'lib/shared/widgets/receipt_capture/receipt_pdf_import_sheets.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_text_document_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> _readReceiptPhotoReviewSource() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_capture_flow_capture_and_review.dart',
    'lib/shared/widgets/receipt_capture/receipt_capture_flow_recovery.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}
