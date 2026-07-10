import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

const _mixedEncodingTimeout = Timeout(Duration(minutes: 3));

void main() {
  test(
    'stitches mixed JPEG and PNG sections at different resolutions',
    () async {
      final top = receiptStitchingSection(seed: 750, topTextOffset: 0);
      final middle = receiptStitchingSection(seed: 751, topTextOffset: 18);
      final bottom = receiptStitchingSection(seed: 752, topTextOffset: 36);
      copyReceiptStitchingOverlap(from: top, to: middle, pixels: 380);
      copyReceiptStitchingOverlap(from: middle, to: bottom, pixels: 380);

      final topFile = await writeTempReceiptStitchingImageWithQuality(
        top,
        'mixed_encoding_top',
        quality: 96,
      );
      final middleFile = await _writePng(
        img.copyResize(middle, width: 1080),
        'mixed_encoding_middle',
      );
      final bottomFile = await writeTempReceiptStitchingImageWithQuality(
        img.copyResize(bottom, width: 760),
        'mixed_encoding_bottom',
        quality: 58,
      );
      final sourcePaths = [topFile.path, middleFile.path, bottomFile.path];
      final originalBytes = [
        for (final path in sourcePaths) await File(path).readAsBytes(),
      ];

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: sourcePaths,
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.pairs, hasLength(2));
      expect(
        result.pairs.map((pair) => pair.confidence),
        everyElement(greaterThanOrEqualTo(.50)),
      );
      expect(result.ocrSourcePaths, [result.stitchedPath]);
      expect(result.ocrSourceContractCode, 'stitched_ocr_source_ready');
      for (var index = 0; index < sourcePaths.length; index++) {
        expect(
          await File(sourcePaths[index]).readAsBytes(),
          originalBytes[index],
        );
      }
    },
    timeout: _mixedEncodingTimeout,
  );
}

Future<File> _writePng(img.Image image, String name) async {
  final file = File(
    '${Directory.systemTemp.path}/maintainiac_receipt_stitch_$name.png',
  );
  await file.writeAsBytes(img.encodePng(image), flush: true);
  return file;
}
