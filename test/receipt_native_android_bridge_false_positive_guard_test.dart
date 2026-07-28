import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android receipt framing rejects full-display false positives before live guidance escalates',
    () async {
      final framing = await File(
        'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraFraming.kt',
      ).readAsString();
      final analysis =
          await File(
            'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraAnalysis.kt',
          ).readAsString() +
          await File(
            'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraAnalysisFrame.kt',
          ).readAsString();

      expect(
        framing,
        contains(
          'internal fun ReceiptCameraActivity.looksLikeFullDisplayFalsePositive',
        ),
      );
      expect(framing, contains('if (!touchesEdge) return false'));
      expect(
        framing,
        contains(
          'val nearFullDisplay = widthRatio >= 0.78 && heightRatio >= 0.78',
        ),
      );
      expect(
        framing,
        contains(
          'val tallScreenLikePanel = heightRatio >= 0.88 && widthRatio in 0.46..0.82',
        ),
      );
      expect(
        framing,
        contains('return nearFullDisplay || tallScreenLikePanel'),
      );
      expect(
        framing,
        contains(
          'if (looksLikeFullDisplayFalsePositive(widthRatio, heightRatio, touchesEdge)) {\n'
          '        return LiveReceiptFraming()\n'
          '    }',
        ),
      );
      expect(
        framing,
        contains(
          'internal fun ReceiptCameraActivity.hasReliableLiveReceiptTargetForQualityWarnings',
        ),
      );
      expect(framing, contains('if (!edgeDetectionEnabled) return false'));
      expect(
        framing,
        contains(
          'if (!framing.found || !hasUsableLiveFramingBounds(framing)) return false',
        ),
      );
      expect(framing, contains('if (framing.touchesEdge) return false'));
      expect(
        framing,
        contains(
          'if (framing.widthRatio < 0.42 || framing.heightRatio < 0.36) return false',
        ),
      );
      expect(
        analysis,
        contains('!hasReliableLiveReceiptTargetForQualityWarnings(framing)'),
      );
      expect(
        analysis,
        contains('latestReadabilitySignal = "waiting_for_receipt_target"'),
      );
    },
  );
}
