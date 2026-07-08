import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

void main() {
  test(
    'stitches phone-window long receipt when sections have clipped vertical edges',
    () async {
      final files = await _writeVerticalEdgeCroppedPhoneWindows(
        'vertical_edge_phone_window',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [for (final file in files) file.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(4));
      expect(result.overlapPixels, hasLength(4));
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(result.sourcePreservationCode, contains('derived_stitched'));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );

      final stitched = img.decodeImage(
        await File(result.stitchedPath!).readAsBytes(),
      );
      expect(stitched, isNotNull);
      expect(stitched!.width, result.stitchedWidth);
      expect(stitched.height, result.stitchedHeight);
      expect(result.stitchedPixelCount, lessThan(16000000));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<List<File>> _writeVerticalEdgeCroppedPhoneWindows(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 5);
  final starts = <int>[0, 1120, 2240, 3360, 4480];
  final files = <File>[];
  for (var index = 0; index < starts.length; index++) {
    final window = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    final clipped = index.isEven
        ? clipReceiptStitchingVerticalEdge(window, bottom: 34)
        : clipReceiptStitchingVerticalEdge(window, top: 38);
    final shifted = shiftReceiptStitchingShot(
      clipped,
      dx: index.isEven ? 14 : -16,
      dy: 0,
    );
    files.add(
      await writeTempReceiptStitchingImage(shifted, '${prefix}_$index'),
    );
  }
  return files;
}
