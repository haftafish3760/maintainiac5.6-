import 'dart:io';

import 'package:image/image.dart' as img;

import 'receipt_stitching_image_helpers.dart';

Future<List<File>> writePhoneWindowStack(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas();
  final starts = <int>[0, 1120, 2240, 3360];
  final captures = <img.Image>[];
  for (var index = 0; index < starts.length; index++) {
    final window = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    final shifted = index.isOdd
        ? shiftReceiptStitchingShot(window, dx: 18, dy: 0)
        : index == 2
        ? shiftReceiptStitchingShot(window, dx: -15, dy: 0)
        : window;
    captures.add(shifted);
  }
  return _writeStack(captures, prefix);
}

Future<List<File>> writeSixPhoneWindowStack(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 6);
  final starts = <int>[0, 1120, 2240, 3360, 4480, 5600];
  final captures = <img.Image>[];
  for (var index = 0; index < starts.length; index++) {
    final window = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    final cropped = index.isEven
        ? clipReceiptStitchingSide(window, right: 42)
        : clipReceiptStitchingSide(window, left: 36);
    captures.add(
      shiftReceiptStitchingShot(cropped, dx: index.isEven ? 16 : -18, dy: 0),
    );
  }
  return _writeStack(captures, prefix);
}

Future<List<File>> writeSixPhoneWindowExposureStack(String prefix) async {
  final tallReceipt = tallReceiptStitchingCanvas(sectionCount: 6);
  final starts = <int>[0, 1120, 2240, 3360, 4480, 5600];
  final captures = <img.Image>[];
  for (var index = 0; index < starts.length; index++) {
    final window = img.copyCrop(
      tallReceipt,
      x: 0,
      y: starts[index],
      width: tallReceipt.width,
      height: 1500,
    );
    final cropped = index.isEven
        ? clipReceiptStitchingSide(window, right: 36)
        : clipReceiptStitchingSide(window, left: 32);
    final shifted = shiftReceiptStitchingShot(
      cropped,
      dx: index.isEven ? 15 : -17,
      dy: 0,
    );
    captures.add(
      adjustReceiptStitchingBrightness(shifted, delta: index.isEven ? 32 : -26),
    );
  }
  return _writeStack(captures, prefix);
}

Future<List<File>> _writeStack(List<img.Image> images, String prefix) async {
  final files = <File>[];
  for (var index = 0; index < images.length; index++) {
    files.add(
      await writeTempReceiptStitchingImage(images[index], '${prefix}_$index'),
    );
  }
  return files;
}
