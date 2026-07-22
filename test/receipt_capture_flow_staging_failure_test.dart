import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native capture staging has a user-safe fallback for unexpected errors',
    () {
      final source = File(
        '${Directory.current.path}/lib/shared/widgets/receipt_capture/'
        'receipt_capture_flow_capture_and_review.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('} on ReceiptProofStorageException catch (error) {'),
      );
      expect(source, contains('} catch (_) {'));
      expect(source, contains('ReceiptCaptureFlowStatus.stagingFailed'));
      expect(source, contains("reason: 'unexpected_staging_failure'"));
      expect(source, contains('retry_receipt_camera_or_import_existing_photo'));
      expect(source, contains('could not prepare that receipt photo safely'));
    },
  );

  test('review-route failures preserve the staged receipt for recovery', () {
    final source = File(
      '${Directory.current.path}/lib/shared/widgets/receipt_capture/'
      'receipt_capture_flow_capture_and_review.dart',
    ).readAsStringSync();

    expect(source, contains("stage: 'review_unavailable'"));
    expect(source, contains("reason: 'review_route_open_failed'"));
    expect(source, contains('keep_staged_receipt_for_recovery'));
    expect(source, contains('ReceiptCaptureFlowStatus.reviewUnavailable'));
    expect(source, contains('Your receipt photo was kept for recovery.'));
  });
}
