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
    Offset? focusPoint;
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
            onTorch: () => toggledTorch = true,
            onTapFocus: (point) => focusPoint = point,
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
    expect(find.text('Maintainiac Receipt Camera'), findsOneWidget);
    expect(find.text('Native receipt controls'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Move closer'), findsOneWidget);
    expect(find.text('Receipt assist'), findsOneWidget);
    expect(find.text('Next reviews text'), findsOneWidget);
    expect(
      find.text(
        'After capture: review receipt text, then choose business, personal, or mixed.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Readable'), findsOneWidget);
    expect(find.text('Save space'), findsNothing);
    expect(find.text('Saved proof'), findsNothing);
    expect(find.text('Proof size'), findsNothing);
    expect(find.text('1 of 1'), findsOneWidget);
    expect(find.text('Tap text to focus'), findsOneWidget);
    expect(find.text('Pinch to zoom'), findsOneWidget);
    expect(find.text('Brightness assist'), findsOneWidget);
    expect(find.byTooltip('Reset brightness'), findsOneWidget);

    await tester.tap(find.byTooltip('Receipt camera settings'));
    await tester.tap(find.byTooltip('Turn light on'));
    await tester.tap(find.bySemanticsLabel('Take receipt photo'));
    await tester.tap(find.byTooltip('Back'));
    await tester.tap(find.byTooltip('Reset brightness'));
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
    expect(resetExposure, isTrue);
    expect(focusPoint, isNotNull);
    expect(focusPoint!.dx, closeTo(.5, .06));
    expect(focusPoint!.dy, closeTo(.36, .08));
    expect(zoomValue, greaterThan(2));

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(1.25);
    expect(exposureValue, 1.25);

    final previewRect = tester.getRect(
      find.byKey(const ValueKey('receipt-preview')),
    );
    final shutterRect = tester.getRect(
      find.bySemanticsLabel('Take receipt photo'),
    );
    final settingsRect = tester.getRect(
      find.byTooltip('Receipt camera settings'),
    );
    final titleRect = tester.getRect(find.text('Maintainiac Receipt Camera'));

    expect(previewRect.height, 915);
    expect(settingsRect.center.dy, lessThan(90));
    expect(titleRect.center.dy, lessThan(90));
    expect(titleRect.left, greaterThan(60));
    expect(titleRect.right, lessThan(340));
    expect(shutterRect.center.dy, greaterThan(760));
  });

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

  testWidgets('native camera shell can show long receipt ghost guide', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ReceiptNativeCameraShell(
          capabilities: const ReceiptNativeCameraCapabilities(
            engine: ReceiptNativeCameraEngine.avFoundation,
            available: true,
            hasRearCamera: true,
          ),
          settings: const ReceiptNativeCameraSettings(
            assistedReceiptFill: false,
          ),
          preview: const ColoredBox(color: Color(0xFF38444B)),
          previousSectionPreview: const ColoredBox(
            key: ValueKey('previous-section-ghost'),
            color: Color(0xFFCED8DC),
          ),
          previousSectionReasonCode: 'missing_bottom_edge_and_totals',
          previousSectionGuidance:
              'Keep the last readable lines in the top ghost slice.',
          onBack: () {},
          onCapture: () {},
          onSettings: () {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('previous-section-ghost')),
      findsOneWidget,
    );
    expect(find.text('Match the bottom section'), findsOneWidget);
    expect(
      find.text('Keep the last readable lines in the top ghost slice.'),
      findsOneWidget,
    );
    expect(
      find.text('Line up 3-5 repeated receipt lines here'),
      findsOneWidget,
    );
    expect(find.text('Tap text to focus'), findsNothing);
    expect(find.text('Pinch to zoom'), findsNothing);
    expect(find.text('Brightness assist'), findsNothing);
    expect(find.text('Native receipt controls'), findsOneWidget);
    expect(find.text('Manual receipt'), findsOneWidget);
    expect(find.text('Save photo only'), findsOneWidget);
    expect(find.text('Saved proof'), findsOneWidget);
    expect(find.text('Proof size'), findsNothing);
    expect(find.text('Save space'), findsNothing);
  });

  testWidgets('native camera shell explains manual photo-only capture', (
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
        ),
      ),
    );

    expect(find.text('Manual receipt'), findsOneWidget);
    expect(find.text('Save photo only'), findsOneWidget);
    expect(
      find.text(
        'After capture: keep the receipt photo attached to this expense.',
      ),
      findsOneWidget,
    );
  });
}
