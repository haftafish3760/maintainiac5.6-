import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'review exposes section removal and uses one stable-frame straighten slider',
    (tester) async {
      late Directory directory;
      late List<String> paths;
      await tester.runAsync(() async {
        directory = await Directory.systemTemp.createTemp(
          'receipt_review_surface_',
        );
        paths = <String>[];
        for (var index = 0; index < 2; index++) {
          final image = img.Image(width: 240, height: 480);
          img.fill(image, color: img.ColorRgb8(246, 245, 238));
          img.drawLine(
            image,
            x1: 24,
            y1: 80 + index * 20,
            x2: 216,
            y2: 84 + index * 20,
            color: img.ColorRgb8(20, 20, 20),
            thickness: 3,
          );
          final file = File('${directory.path}/section-$index.jpg');
          await file.writeAsBytes(img.encodeJpg(image), flush: true);
          paths.add(file.path);
        }
      });
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        if (await directory.exists()) await directory.delete(recursive: true);
      });

      await tester.binding.setSurfaceSize(const Size(412, 915));
      await tester.pumpWidget(
        MaterialApp(
          home: ReceiptPhotoReviewScreen(
            initialPhotoPaths: paths,
            initialDataSaverLevel: ReceiptDataSaverLevel.balanced,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Crop'), findsOneWidget);
      expect(find.text('Retake Section 1'), findsOneWidget);
      expect(find.text('Add Another Photo'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('Arrange'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.textContaining('Check the store'), findsNothing);

      await tester.binding.setSurfaceSize(const Size(915, 412));
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        find.byKey(const ValueKey('receipt-review-wide-short-actions')),
        findsOneWidget,
      );
      expect(find.text('Crop'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(412, 915));
      await tester.pump(const Duration(milliseconds: 150));

      await tester.tap(find.text('Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Remove receipt photo?'), findsOneWidget);
      await tester.tap(find.text('Remove Photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Remove'), findsNothing);
      expect(find.text('Add Another Photo'), findsOneWidget);

      await tester.tap(find.text('Crop'));
      await tester.pump();

      expect(find.text('Straighten image'), findsOneWidget);
      expect(find.text('Move Left'), findsNothing);
      expect(find.text('Move Right'), findsNothing);
      expect(find.text('Move Up'), findsNothing);
      expect(find.text('Move Down'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('receipt-review-straighten-button')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('receipt-review-straighten-slider')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Straighten receipt image'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(915, 412));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);
      expect(find.byType(Slider), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
