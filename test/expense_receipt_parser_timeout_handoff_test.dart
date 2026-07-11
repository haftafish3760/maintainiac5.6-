import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'receipt parser handoff cannot leave processing spinner unbounded',
    () async {
      final source = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_imported_text_parse_actions.dart',
      ).readAsString();

      expect(source, contains('Duration _receiptParserTimeout('));
      expect(source, contains('ReceiptCapabilityTier.heavyweight'));
      expect(source, contains('.timeout(_receiptParserTimeout(capability))'));
      expect(source, contains('on TimeoutException'));
      expect(source, contains("failureKind: 'receipt_parser_timeout'"));
      expect(source, contains("_scanningReceiptPhotos = false"));
      expect(source, contains("'Open manual receipt details'"));
      expect(source, contains('_scrollToReceiptReview()'));
    },
  );
}
