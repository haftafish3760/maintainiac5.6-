import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OCR evidence cannot replace the user-reviewed photo order', () async {
    final source = await File(
      'lib/shared/widgets/receipt_capture/'
      'receipt_photo_review_stitch_order_evidence.dart',
    ).readAsString();
    final preview = await File(
      'lib/shared/widgets/receipt_capture/'
      'receipt_photo_review_stitch_preview_async.dart',
    ).readAsString();

    expect(source, contains('Future<void> _collectStitchOrderEvidence()'));
    expect(source, contains("'stitchOrderAuthority': 'user_reviewed_order'"));
    expect(
      source,
      contains("'stitchOrderRecommendationAvailable': plan.changed"),
    );
    expect(source, contains("'stitchOrderAutomaticallyChanged': false"));
    expect(source, isNot(contains('..addAll(plan.orderedPaths)')));
    expect(preview, contains('await _collectStitchOrderEvidence();'));
    expect(preview, isNot(contains('_applyAutomaticStitchOrderIfConfident')));
  });
}
