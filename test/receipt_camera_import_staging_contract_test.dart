import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gallery receipt imports are staged before review', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
    ).readAsStringSync();

    expect(source, contains('_stageImportedReceiptPhotos(picked)'));
    expect(source, contains('ReceiptAcquiredPhotoStaging().stage('));
    expect(source, contains('existing_receipt_photo_import'));
    expect(source, contains('importedPhotoStagedBeforeReview'));
    expect(source, contains('Choose it again before continuing.'));
    expect(
      source,
      contains('reviewPickedPhotoPaths(\n        staged.photoPaths,'),
    );
  });

  test('attachment-panel fallback photos are staged before review', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_camera_fallback_actions.dart',
    ).readAsStringSync();

    expect(source, contains('_stageFallbackReceiptPhotos('));
    expect(source, contains('ReceiptAcquiredPhotoStaging().stage('));
    expect(source, contains('phone_camera_backup_receipt_photo'));
    expect(source, contains('document_scanner_backup_receipt_photo'));
    expect(source, contains('_mergeStagedFallbackDiagnostics('));
    expect(source, contains('Capture it again before continuing.'));
  });
}
