import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'iOS receipt framing rejects full-display false positives before live guidance escalates',
    () async {
      final framing = await File(
        'ios/Runner/ReceiptCameraViewControllerLiveFrameAnalysis.swift',
      ).readAsString();

      expect(
        framing,
        contains('func looksLikeFullDisplayFalsePositive('),
      );
      expect(framing, contains('guard touchesEdge else { return false }'));
      expect(
        framing,
        contains('return widthRatio >= 0.78 && heightRatio >= 0.78'),
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
    },
  );
}
