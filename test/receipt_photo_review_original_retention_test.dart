import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'photo review preserves the selected original proof retention level',
    () async {
      final source = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
      ).readAsString();

      expect(
        source,
        contains(
          'late ReceiptDataSaverLevel _dataSaverLevel = widget.initialDataSaverLevel;',
        ),
      );
      expect(
        source,
        isNot(contains('ReceiptDataSaverLevel.original\n      ?')),
      );
    },
  );
}
