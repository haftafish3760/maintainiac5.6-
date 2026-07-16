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
      _writeReceiptImage(receiptDirectory, 'receipt-tail.png', seed: 77),
    ]);
  });

  tearDownAll(() => receiptDirectory.delete(recursive: true));

  testWidgets('two-photo review keeps long receipt decisions clear', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReceiptPhotoReviewScreen(
          initialPhotoPaths: receiptPaths.take(2).toList(),
          initialDataSaverLevel: ReceiptDataSaverLevel.balanced,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Section 1 of 2'), findsAtLeastNWidgets(1));
    expect(find.text('Add Another Photo'), findsOneWidget);
    expect(find.text('Use Receipt'), findsOneWidget);
    expect(
      find.textContaining('Check each section.', findRichText: true),
      findsOneWidget,
    );
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
          initialPhotoPaths: receiptPaths.take(2).toList(),
          initialDataSaverLevel: ReceiptDataSaverLevel.balanced,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Retake Section 1'), findsOneWidget);
    expect(find.text('Add Another Photo'), findsOneWidget);
    expect(find.text('Use Receipt'), findsOneWidget);
  });

  testWidgets('three-section review stays usable on a narrow phone', (
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

    expect(find.text('Section 1 of 3'), findsAtLeastNWidgets(1));
    expect(find.text('Section 2 of 3'), findsOneWidget);
    expect(find.text('Section 3 of 3'), findsOneWidget);
    expect(find.text('Retake Section 1'), findsOneWidget);
    expect(find.text('Add Another Photo'), findsOneWidget);
    expect(find.text('Use Receipt'), findsOneWidget);
  });

  testWidgets('review keeps the receipt image as the dominant surface', (
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

    final photoSurface = find.byType(InteractiveViewer);
    final actionTray = find.text('Use Receipt');
    expect(photoSurface, findsOneWidget);
    expect(actionTray, findsOneWidget);
    expect(
      tester.getSize(photoSurface).height,
      greaterThan(tester.getSize(actionTray).height * 5),
    );
  });

  testWidgets('review keeps a clear Use Receipt action for a weak photo', (
    tester,
  ) async {
    final path = receiptPaths.first;
    await tester.pumpWidget(
      MaterialApp(
        home: ReceiptPhotoReviewScreen(
          initialPhotoPaths: [path],
          initialDataSaverLevel: ReceiptDataSaverLevel.balanced,
          initialQualityChecksByPath: {
            path: const ReceiptPhotoQualityCheck(
              width: 320,
              height: 480,
              focusScore: 3,
              brightness: 36,
              isLikelyReadable: false,
            ),
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Use Receipt'), findsOneWidget);
    expect(find.text('Use Anyway'), findsNothing);
    expect(find.text('Review receipt photo'), findsNothing);
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
