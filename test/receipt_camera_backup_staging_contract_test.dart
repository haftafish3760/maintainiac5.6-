import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone-camera fallback is staged before receipt review', () {
    final actions = File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
    ).readAsStringSync();
    final models = File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_models.dart',
    ).readAsStringSync();

    expect(
      actions,
      contains('Future<_PickedReceiptPhotos> _stagePhoneCameraBackupPhotos('),
    );
    expect(
      actions,
      contains(
        'Future<_PickedReceiptPhotos> _stageDocumentScannerBackupPhotos(',
      ),
    );
    expect(actions, contains('ReceiptAcquiredPhotoStaging().stage('));
    expect(actions, contains('phone_camera_backup_receipt_photo'));
    expect(actions, contains('document_scanner_backup_receipt_photo'));
    expect(
      actions,
      contains(
        'stagingDiagnosticsByPath: staged.captureDiagnosticsByPhotoPath',
      ),
    );
    expect(
      actions,
      contains('} on ReceiptProofStorageException catch (error) {'),
    );
    expect(actions, contains('} catch (_) {'));
    expect(
      models,
      contains('Map<String, Map<String, Object?>> stagingDiagnosticsByPath'),
    );
    expect(models, contains('...?stagingDiagnosticsByPath[path]'));
  });
}
