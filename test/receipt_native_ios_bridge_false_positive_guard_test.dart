import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'iOS receipt framing rejects full-display false positives before live guidance escalates',
    () async {
      final framing = await File(
        'ios/Runner/ReceiptCameraViewControllerLiveFrameAnalysis.swift',
      ).readAsString();
      final readability = await File(
        'ios/Runner/ReceiptCameraViewControllerLiveReadability.swift',
      ).readAsString();

      expect(
        framing,
        contains('func looksLikeFullDisplayFalsePositive('),
      );
      expect(framing, contains('guard touchesEdge else { return false }'));
      expect(
        framing,
        contains('let nearFullDisplay = widthRatio >= 0.78 && heightRatio >= 0.78'),
      );
      expect(
        framing,
        contains('let tallScreenLikePanel = heightRatio >= 0.88 && (0.46...0.82).contains(widthRatio)'),
      );
      expect(
        framing,
        contains('return nearFullDisplay || tallScreenLikePanel'),
      );
      expect(
        framing,
        contains(
          'if looksLikeFullDisplayFalsePositive(\n'
          '      widthRatio: widthRatio,\n'
          '      heightRatio: heightRatio,\n'
          '      touchesEdge: touchesEdge\n'
          '    ) {\n'
          '      return LiveReceiptFraming()\n'
          '    }',
        ),
      );
      expect(
        framing,
        contains('func hasReliableLiveReceiptTargetForQualityWarnings('),
      );
      expect(framing, contains('if !edgeDetectionEnabled { return false }'));
      expect(
        framing,
        contains('if !framing.found || !hasUsableLiveFramingBounds(framing) { return false }'),
      );
      expect(framing, contains('if framing.touchesEdge { return false }'));
      expect(
        framing,
        contains('if framing.widthRatio < 0.42 || framing.heightRatio < 0.36 { return false }'),
      );
      expect(
        readability,
        contains('if !hasReliableLiveReceiptTargetForQualityWarnings(framing) {'),
      );
      expect(
        readability,
        contains('latestReadabilitySignal = "waiting_for_receipt_target"'),
      );
    },
  );
}
