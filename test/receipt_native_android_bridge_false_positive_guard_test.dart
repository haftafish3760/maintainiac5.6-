import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android receipt framing rejects full-display false positives before live guidance escalates',
    () async {
      final framing = await File(
        'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraFraming.kt',
      ).readAsString();

      expect(
        framing,
        contains(
          'internal fun ReceiptCameraActivity.looksLikeFullDisplayFalsePositive',
        ),
      );
      expect(framing, contains('if (!touchesEdge) return false'));
      expect(framing, contains('return widthRatio >= 0.78 && heightRatio >= 0.78'));
      expect(
        framing,
        contains(
          'if (looksLikeFullDisplayFalsePositive(widthRatio, heightRatio, touchesEdge)) {\n'
          '        return LiveReceiptFraming()\n'
          '    }',
        ),
      );
    },
  );
}
