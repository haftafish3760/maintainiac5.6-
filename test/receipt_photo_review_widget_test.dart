import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  late Directory receiptDirectory;
  late List<String> receiptPaths;

  setUpAll(() async {
    receiptDirectory = await Directory.systemTemp.createTemp(
      'maintainiac-receipt-review-',
    );
    receiptPaths = await Future.wait([
      _writeReceiptImage(receiptDirectory, 'receipt-top.png', seed: 18),
      _writeReceiptImage(receiptDirectory, 'receipt-bottom.png', seed: 42),
    ]);
  });

  tearDownAll(() => receiptDirectory.delete(recursive: true));

  testWidgets('two-photo review keeps long receipt decisions clear', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReceiptPhotoReviewScreen(
          initialPhotoPaths: receiptPaths,
          initialDataSaverLevel: ReceiptDataSaverLevel.balanced,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Review 2 receipt sections'), findsOneWidget);
    expect(find.text('Section 1 of 2'), findsAtLeastNWidgets(1));
    expect(find.text('Add Another Photo'), findsOneWidget);
    expect(find.text('Use Receipt'), findsOneWidget);
    expect(find.text('Match receipt photos'), findsNothing);
    expect(find.text('Check photo order'), findsNothing);
    expect(find.text('Save space preview'), findsNothing);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('narrow phone review keeps primary actions visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ReceiptPhotoReviewScreen(
          initialPhotoPaths: receiptPaths,
          initialDataSaverLevel: ReceiptDataSaverLevel.balanced,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Retake Section 1'), findsOneWidget);
    expect(find.text('Add Another Photo'), findsOneWidget);
    expect(find.text('Use Receipt'), findsOneWidget);
  });
}

Future<String> _writeReceiptImage(
  Directory directory,
  String name, {
  required int seed,
}) async {
  final image = img.Image(width: 360, height: 560);
  img.fill(image, color: img.ColorRgb8(248, 248, 244));
  for (var y = 44; y < image.height - 24; y += 24) {
    final width = 180 + ((y + seed) % 120);
    img.fillRect(
      image,
      x1: 28,
      y1: y,
      x2: width,
      y2: y + 4,
      color: img.ColorRgb8(38, 38, 38),
    );
  }
  final file = File('${directory.path}/$name');
  await file.writeAsBytes(img.encodePng(image), flush: true);
  return file.path;
}
