import 'dart:io';

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

  test('native camera shell exposes no tap focus callback hook', () async {
    final shell = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart',
    ).readAsString();
    final previewControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_top_controls.dart',
    ).readAsString();

    expect(shell, isNot(contains('this.onTapFocus')));
    expect(shell, isNot(contains('final ValueChanged<Offset>? onTapFocus')));
    expect(previewControls, isNot(contains('this.onTapFocus')));
    expect(previewControls, isNot(contains('onTapUp: _tapFocusAvailable')));
    expect(previewControls, isNot(contains('_tapFocusAvailable')));
  });

  test('native camera shell uses gear settings control instead of wrench', () async {
    final topControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_top_controls.dart',
    ).readAsString();

    expect(topControls, contains('Icons.settings_rounded'));
    expect(topControls, contains("label: 'Receipt camera settings'"));
    expect(topControls, isNot(contains('Icons.build_rounded')));
    expect(topControls, isNot(contains('Icons.handyman_rounded')));
    expect(topControls, isNot(contains('Icons.tune_rounded')));
  });

  test('native camera shell does not rotate fake receipt guidance copy', () async {
    final shell = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart',
    ).readAsString();
    final guidance = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart',
    ).readAsString();

    final combined = '$shell\n$guidance';
    expect(combined, isNot(contains('guidanceMessages')));
    expect(combined, isNot(contains('warningCarousel')));
    expect(combined, isNot(contains('randomGuidance')));
    expect(combined, isNot(contains('Timer.periodic')));
    expect(combined, isNot(contains('Future.delayed')));
    expect(combined, isNot(contains('Stream.periodic')));
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
    expect(
      find.text('Keep the last readable lines in the top ghost slice.'),
      findsOneWidget,
    );
    expect(find.text('Manual receipt'), findsNothing);
    expect(find.text('Save photo only'), findsNothing);
    expect(find.text('Saved proof'), findsNothing);
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

    expect(find.text('Manual receipt'), findsNothing);
    expect(find.text('Save photo only'), findsNothing);
    expect(find.textContaining('After capture:'), findsNothing);
  });

  testWidgets('native camera shell keeps controls inside compact phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ReceiptNativeCameraShell(
          capabilities: const ReceiptNativeCameraCapabilities(
            engine: ReceiptNativeCameraEngine.cameraX,
            available: true,
            hasRearCamera: true,
            supportsTorch: true,
            supportsContinuousFocus: true,
            supportsExposureCompensation: true,
            minExposureOffset: -2,
            maxExposureOffset: 2,
          ),
          settings: const ReceiptNativeCameraSettings(
            assistedReceiptFill: true,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
          ),
          preview: const ColoredBox(color: Color(0xFF38444B)),
          onBack: () {},
          onCapture: () {},
          onSettings: () {},
          onTorch: () {},
          onExposureChanged: (_) {},
          onExposureReset: () {},
          guidanceTitle: 'Hold steady',
          guidanceMessage: 'Receipt text should fill the screen.',
          guidanceStatus: 'Manual capture is ready.',
          qualityLabel: 'Readable',
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Receipt camera settings'), findsOneWidget);
    expect(find.byTooltip('Turn light on'), findsOneWidget);
    final shutterIcon = find.byWidgetPredicate(
      (widget) =>
          widget is Icon &&
          widget.icon == Icons.receipt_long_rounded &&
          widget.size == 30,
    );
    expect(shutterIcon, findsOneWidget);

    final shutterRect = tester.getRect(shutterIcon);
    final bottomSafeY =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(shutterRect.bottom, lessThanOrEqualTo(bottomSafeY - 8));
    expect(shutterRect.center.dx, closeTo(160, 2));
  });
}
