import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('explicit review discard is distinct from a resumable receipt draft', () {
    final discarded = ReceiptPhotoReviewResult.discardedByUser(
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );

    expect(discarded.discardedByUser, isTrue);
    expect(discarded.keptForLater, isFalse);
    expect(discarded.photoPaths, isEmpty);
  });

  test('photo review exposes honest exit, draft, and continue choices', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_actions.dart',
    ).readAsStringSync();
    final flow = File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_review_result.dart',
    ).readAsStringSync();

    expect(source, contains("Text('Exit Without Saving')"));
    expect(source, contains("Text('Exit & Save Draft')"));
    expect(source, contains("Text('Back to Photos')"));
    expect(source, contains('ReceiptPhotoReviewResult.discardedByUser'));
    expect(flow, contains('if (reviewResult.discardedByUser)'));
    expect(flow, contains('await staged.discardStagedPhotos();'));
  });
}
