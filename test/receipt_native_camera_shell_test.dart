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
    expect(find.text('Move closer'), findsOneWidget);
    expect(find.text('Assisted receipt'), findsOneWidget);
    expect(find.text('Readable'), findsOneWidget);
    expect(find.text('1 of 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Receipt camera settings'));
    await tester.tap(find.byTooltip('Turn light on'));
    await tester.tap(find.bySemanticsLabel('Take receipt photo'));
    await tester.tap(find.byTooltip('Back'));

    expect(openedSettings, isTrue);
    expect(toggledTorch, isTrue);
    expect(captured, isTrue);
    expect(wentBack, isTrue);

    final previewRect = tester.getRect(
      find.byKey(const ValueKey('receipt-preview')),
    );
    final shutterRect = tester.getRect(
      find.bySemanticsLabel('Take receipt photo'),
    );
    final settingsRect = tester.getRect(
      find.byTooltip('Receipt camera settings'),
    );

    expect(previewRect.height, 915);
    expect(settingsRect.center.dy, lessThan(90));
    expect(shutterRect.center.dy, greaterThan(760));
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
          settings: const ReceiptNativeCameraSettings(),
          preview: const ColoredBox(color: Color(0xFF38444B)),
          previousSectionPreview: const ColoredBox(
            key: ValueKey('previous-section-ghost'),
            color: Color(0xFFCED8DC),
          ),
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
  });
}
