import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test(
    'real receipt probe stitches provided local receipt sections safely',
    () async {
      final paths = _realReceiptProbePaths();
      if (paths.length < 2) {
        markTestSkipped(
          'Set RECEIPT_STITCH_REAL_PATHS to two or more receipt image paths '
          'separated by | to run the local real-receipt stitch probe.',
        );
        return;
      }

      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: 'Missing $path');
      }

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: paths,
      );

      expect(result.inputPaths, paths);
      expect(result.ocrSourcePaths, isNotEmpty);
      expect(
        result.didStitch || result.requiresOcrSourceReviewBeforeAssistedRead,
        isTrue,
        reason: result.detailLabel,
      );
      if (result.didStitch) {
        expect(result.stitchedPath, isNotNull);
        expect(File(result.stitchedPath!).existsSync(), isTrue);
        expect(result.ocrSourcePaths, [result.stitchedPath]);
        expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      } else {
        expect(result.usedFallback, isTrue, reason: result.detailLabel);
        expect(result.ocrSourcePaths, paths);
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

List<String> _realReceiptProbePaths() {
  final raw = Platform.environment['RECEIPT_STITCH_REAL_PATHS'];
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split('|')
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .toList(growable: false);
}
