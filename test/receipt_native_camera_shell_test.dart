import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  testWidgets('native camera shell keeps receipt preview primary', (
    tester,
  ) async {
    var captured = false;
    var openedSettings = false;
    var wentBack = false;
    var toggledTorch = false;
    var resetExposure = false;
    double? zoomValue;
    double? exposureValue;

    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceiptNativeCameraShell(
            capabilities: const ReceiptNativeCameraCapabilities(
              engine: ReceiptNativeCameraEngine.cameraX,
              available: true,
              hasRearCamera: true,
              supportsTorch: true,
              supportsTapFocus: true,
              supportsContinuousFocus: true,
              supportsExposureCompensation: true,
              supportsZoom: true,
              minExposureOffset: -2,
              maxExposureOffset: 2,
              minZoom: 1,
              maxZoom: 10,
            ),
            settings: const ReceiptNativeCameraSettings(
              assistedReceiptFill: true,
              dataSaverLevel: ReceiptDataSaverLevel.strong,
            ),
            preview: const ColoredBox(
              key: ValueKey('receipt-preview'),
              color: Color(0xFF546068),
            ),
            onBack: () => wentBack = true,
            onCapture: () => captured = true,
            onSettings: () => openedSettings = true,
            onReviewCapturedPhotos: () {},
            onTorch: () => toggledTorch = true,
            onZoomChanged: (zoom) => zoomValue = zoom,
            onExposureChanged: (value) => exposureValue = value,
            onExposureReset: () => resetExposure = true,
            currentZoom: 2,
            currentExposureOffset: .5,
            qualityLabel: 'Readable',
            guidanceTitle: 'Move closer',
            guidanceMessage: 'Fill the screen with readable receipt text.',
            guidanceStatus: 'Manual capture is always available.',
            sectionLabel: '1 of 1',
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('receipt-preview')), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Receipt camera settings'), findsOneWidget);
    expect(find.byTooltip('Turn light on'), findsOneWidget);
    expect(find.text('Manual capture is always available.'), findsOneWidget);
    expect(find.text('Receipt assist'), findsNothing);
    expect(find.text('Next reviews text'), findsNothing);
    expect(find.textContaining('After capture:'), findsNothing);
    expect(find.text('Ready'), findsNothing);
    expect(find.text('Readable'), findsNothing);
    expect(find.text('Save space'), findsNothing);
    expect(find.text('Saved proof'), findsNothing);
    expect(find.text('Proof size'), findsNothing);
    expect(find.text('1 of 1'), findsOneWidget);
    expect(find.text('Tap text to focus'), findsNothing);
    expect(find.text('Auto sharpness'), findsNothing);
    expect(find.text('Pinch to zoom'), findsNothing);
    expect(find.text('Brightness assist'), findsNothing);
    expect(find.byTooltip('Reset brightness'), findsNothing);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Add Photo'), findsNothing);

    final primaryShutterIcon = find.byWidgetPredicate(
      (widget) =>
          widget is Icon &&
          widget.icon == Icons.receipt_long_rounded &&
          widget.size == 30,
    );
    await tester.tap(find.byTooltip('Receipt camera settings'));
    await tester.tap(find.byTooltip('Turn light on'));
    await tester.tap(primaryShutterIcon);
    await tester.tap(find.byTooltip('Back'));
    await tester.tapAt(const Offset(206, 330));
    final firstFinger = await tester.startGesture(const Offset(180, 460));
    final secondFinger = await tester.startGesture(const Offset(232, 460));
    await firstFinger.moveTo(const Offset(150, 460));
    await secondFinger.moveTo(const Offset(262, 460));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();

    expect(openedSettings, isTrue);
    expect(toggledTorch, isTrue);
    expect(captured, isTrue);
    expect(wentBack, isTrue);
    expect(resetExposure, isFalse);
    expect(zoomValue, greaterThan(2));

    expect(find.byType(Slider), findsNothing);
    expect(exposureValue, isNull);

    final previewRect = tester.getRect(
      find.byKey(const ValueKey('receipt-preview')),
    );
    final shutterRect = tester.getRect(primaryShutterIcon);
    final settingsRect = tester.getRect(
      find.byTooltip('Receipt camera settings'),
    );

    expect(previewRect.height, 915);
    expect(settingsRect.center.dy, lessThan(90));
    expect(shutterRect.center.dy, greaterThan(760));
  });

  testWidgets(
    'native camera shell shows next-step controls only after a photo exists',
    (tester) async {
      var reviewed = false;
      var addedPhoto = false;

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptNativeCameraShell(
              capabilities: const ReceiptNativeCameraCapabilities(
                engine: ReceiptNativeCameraEngine.cameraX,
                available: true,
                hasRearCamera: true,
              ),
              settings: const ReceiptNativeCameraSettings(
                assistedReceiptFill: true,
              ),
              preview: const ColoredBox(color: Color(0xFF546068)),
              onBack: () {},
              onCapture: () {},
              onSettings: () {},
              onReviewCapturedPhotos: () => reviewed = true,
              onAddPhoto: () => addedPhoto = true,
              capturedPhotoCount: 2,
              longReceiptMode: true,
            ),
          ),
        ),
      );

      expect(find.text('Done (2)'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);

      await tester.tap(find.text('Done (2)'));
      await tester.pump();
      await tester.tap(find.text('Add Photo'));
      await tester.pump();

      expect(reviewed, isTrue);
      expect(addedPhoto, isTrue);
    },
  );

  testWidgets('native camera shell routes system back through camera back', (
    tester,
  ) async {
    var wentBack = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ReceiptNativeCameraShell(
          capabilities: const ReceiptNativeCameraCapabilities(
            engine: ReceiptNativeCameraEngine.cameraX,
            available: true,
            hasRearCamera: true,
          ),
          settings: const ReceiptNativeCameraSettings(
            assistedReceiptFill: false,
          ),
          preview: const ColoredBox(color: Color(0xFF546068)),
          onBack: () => wentBack++,
          onCapture: () {},
          onSettings: () {},
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(wentBack, 1);
  });

  testWidgets('native camera shell keeps tap focus retired for receipts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ReceiptNativeCameraShell(
          capabilities: const ReceiptNativeCameraCapabilities(
            engine: ReceiptNativeCameraEngine.cameraX,
            available: true,
            hasRearCamera: true,
            supportsTapFocus: true,
            supportsContinuousFocus: true,
          ),
          settings: const ReceiptNativeCameraSettings(tapFocusEnabled: true),
          preview: const ColoredBox(
            key: ValueKey('receipt-preview'),
            color: Color(0xFF38444B),
          ),
          onBack: () {},
          onCapture: () {},
          onSettings: () {},
        ),
      ),
    );

    await tester.tapAt(const Offset(195, 420));
    await tester.pump();

    expect(find.text('Tap text to focus'), findsNothing);
    expect(find.text('Auto sharpness'), findsNothing);
  });

  testWidgets('native camera shell shows custom guidance message when status is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReceiptNativeCameraShell(
          capabilities: const ReceiptNativeCameraCapabilities(
            engine: ReceiptNativeCameraEngine.cameraX,
            available: true,
            hasRearCamera: true,
          ),
          settings: const ReceiptNativeCameraSettings(
            assistedReceiptFill: false,
          ),
          preview: const ColoredBox(color: Color(0xFF38444B)),
          onBack: () {},
          onCapture: () {},
          onSettings: () {},
          guidanceTitle: 'Line up the receipt',
          guidanceMessage: 'Keep the receipt inside the frame from top to bottom.',
        ),
      ),
    );

    expect(
      find.text('Keep the receipt inside the frame from top to bottom.'),
      findsOneWidget,
    );
    expect(find.text('Fill the screen with readable receipt text'), findsNothing);
  });

}
