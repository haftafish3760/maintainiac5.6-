import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'possible incomplete receipt records only an explicit user decision',
    () async {
      final source = await File(
        'lib/shared/widgets/receipt_capture/'
        'receipt_photo_review_completion_actions.dart',
      ).readAsString();

      final prompt = source.indexOf(
        'final userDecision = await showDialog<_ReceiptContinueDecision>',
      );
      final confirmed = source.indexOf(
        'userDecision ?? _ReceiptContinueDecision.keepReviewing',
      );
      final recorded = source.indexOf('_recordReceiptCompletionDecision(');

      expect(prompt, greaterThanOrEqualTo(0));
      expect(confirmed, greaterThan(prompt));
      expect(recorded, greaterThan(confirmed));
      expect(
        source,
        contains(
          'confirmedDecision == _ReceiptContinueDecision.continueAnyway',
        ),
      );
      expect(source, contains('decision: confirmedDecision'));
      expect(source, contains('await addAnotherReceiptPhoto();'));
      expect(
        source,
        isNot(
          contains(
            'decision: _ReceiptContinueDecision.continueAnyway,\n'
            '      coverageDecision: decision',
          ),
        ),
      );
    },
  );
}
