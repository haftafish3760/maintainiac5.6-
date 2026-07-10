import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
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

  test(
    'native camera shell uses gear settings control instead of wrench',
    () async {
      final topControls = await File(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_top_controls.dart',
      ).readAsString();
      final uiConfig = await File(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_ui_config.dart',
      ).readAsString();

      expect(topControls, contains('Icons.settings_rounded'));
      expect(topControls, contains('label: uiConfig.settingsLabel'));
      expect(
        uiConfig,
        contains("this.settingsLabel = 'Receipt camera settings'"),
      );
      expect(topControls, isNot(contains('Icons.build_rounded')));
      expect(topControls, isNot(contains('Icons.handyman_rounded')));
      expect(topControls, isNot(contains('Icons.tune_rounded')));
    },
  );

  test(
    'native camera shell does not rotate fake receipt guidance copy',
    () async {
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
    },
  );

  test('native camera shell keeps a round shutter control contract', () async {
    final bottomControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart',
    ).readAsString();
    final shutterStart = bottomControls.indexOf(
      'class _ReceiptNativeCameraShutterButton',
    );
    final shutterEnd = bottomControls.indexOf(
      'class _ReceiptNativeCameraIconButton',
      shutterStart,
    );
    final shutterBlock = bottomControls.substring(shutterStart, shutterEnd);

    expect(shutterBlock, contains('label: \'Take receipt photo\''));
    expect(shutterBlock, contains('shape: const CircleBorder()'));
    expect(shutterBlock, contains('customBorder: const CircleBorder()'));
    expect(shutterBlock, contains('shape: BoxShape.circle'));
    expect(shutterBlock, contains('width: 70'));
    expect(shutterBlock, contains('height: 70'));
    expect(shutterBlock, isNot(contains('RoundedRectangleBorder(')));
  });

  test(
    'native camera shell keeps top and bottom controls inside safe areas',
    () async {
      final topControls = await File(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_top_controls.dart',
      ).readAsString();
      final bottomBar = await File(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_bar.dart',
      ).readAsString();

      expect(topControls, contains('return SafeArea('));
      expect(topControls, contains('bottom: false'));
      expect(
        topControls,
        contains('padding: const EdgeInsets.fromLTRB(8, 6, 8, 0)'),
      );
      expect(bottomBar, contains('child: SafeArea('));
      expect(bottomBar, contains('top: false'));
      expect(bottomBar, contains('minimum: const EdgeInsets.only(bottom: 8)'));
      expect(
        bottomBar,
        contains('padding: const EdgeInsets.fromLTRB(12, 6, 12, 6)'),
      );
    },
  );

  test(
    'native camera shell avoids a full width bottom gradient bar over the preview',
    () async {
      final bottomBar = await File(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_bar.dart',
      ).readAsString();
      final uiConfig = await File(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_ui_config.dart',
      ).readAsString();

      expect(bottomBar, isNot(contains('LinearGradient(')));
      expect(bottomBar, isNot(contains('Color(0xB8050607)')));
      expect(bottomBar, contains('child: SafeArea('));
    },
  );

  test(
    'native camera shell keeps framed top-bar control sizing contract',
    () async {
      final bottomControls = await File(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart',
      ).readAsString();
      final iconButtonStart = bottomControls.indexOf(
        'class _ReceiptNativeCameraIconButton',
      );
      final iconButtonBlock = bottomControls.substring(iconButtonStart);

      expect(iconButtonBlock, contains('minimumSize: const Size(44, 44)'));
      expect(
        iconButtonBlock,
        contains('tapTargetSize: MaterialTapTargetSize.shrinkWrap'),
      );
      expect(iconButtonBlock, contains('RoundedRectangleBorder('));
      expect(
        iconButtonBlock,
        contains('borderRadius: BorderRadius.circular(8)'),
      );
      expect(
        iconButtonBlock,
        contains('side: const BorderSide(color: Color(0xFF526168), width: .8)'),
      );
    },
  );

  test(
    'native camera shell keeps bottom bar accessibility summary contract',
    () async {
      final bottomBar = await File(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_bar.dart',
      ).readAsString();

      expect(bottomBar, contains("label: _semanticLabel"));
      expect(bottomBar, contains("? 'receipt assist'"));
      expect(bottomBar, contains(": 'manual receipt'"));
      expect(bottomBar, contains("? 'quality pending'"));
      expect(bottomBar, contains("? 'backup camera'"));
      expect(bottomBar, contains(": 'native camera'"));
      expect(
        bottomBar,
        contains("return '\$engine shutter, \$assist, \$quality';"),
      );
      expect(
        bottomBar,
        contains('capturedPhotoCount > 0 && onReviewCapturedPhotos != null'),
      );
      expect(bottomBar, contains("label: _nextLabel"));
      expect(
        bottomBar,
        contains(
          "tooltip: 'Done: review captured receipt photos in Maintainiac'",
        ),
      );
      expect(bottomBar, contains('label: uiConfig.addPhotoLabel'));
      expect(bottomBar, contains("tooltip: 'Add another receipt photo'"));
    },
  );

  test(
    'native camera shell keeps torch control label and disable contract',
    () async {
      final topControls = await File(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_top_controls.dart',
      ).readAsString();
      final uiConfig = await File(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_ui_config.dart',
      ).readAsString();

      expect(topControls, contains('Icons.flash_on_rounded'));
      expect(topControls, contains('Icons.flash_off_rounded'));
      expect(topControls, contains('uiConfig.turnLightOffLabel'));
      expect(uiConfig, contains("this.turnLightOnLabel = 'Turn light on'"));
      expect(uiConfig, contains("this.turnLightOffLabel = 'Turn light off'"));
      expect(
        topControls,
        contains('onPressed: torchSupported ? onTorch : null'),
      );
    },
  );

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
          previousSectionReasonCode: ' Missing Bottom Edge And Totals ',
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

  testWidgets(
    'native camera shell keeps next-step controls inside compact phones',
    (tester) async {
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
            ),
            settings: const ReceiptNativeCameraSettings(
              assistedReceiptFill: true,
            ),
            preview: const ColoredBox(color: Color(0xFF38444B)),
            onBack: () {},
            onCapture: () {},
            onSettings: () {},
            onTorch: () {},
            onReviewCapturedPhotos: _noop,
            onAddPhoto: _noop,
            capturedPhotoCount: 3,
            longReceiptMode: true,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Done (3)'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);

      final nextRect = tester.getRect(find.text('Done (3)'));
      final addRect = tester.getRect(find.text('Add Photo'));
      final shutterIcon = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == Icons.receipt_long_rounded &&
            widget.size == 30,
      );
      final shutterRect = tester.getRect(shutterIcon);

      expect(nextRect.right, lessThanOrEqualTo(320));
      expect(addRect.left, greaterThanOrEqualTo(0));
      expect(nextRect.bottom, lessThan(shutterRect.top));
    },
  );

  testWidgets(
    'native camera shell keeps guidance above next-step controls on compact phones',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: ReceiptNativeCameraShell(
            capabilities: const ReceiptNativeCameraCapabilities(
              engine: ReceiptNativeCameraEngine.cameraX,
              available: true,
              hasRearCamera: true,
            ),
            settings: const ReceiptNativeCameraSettings(
              assistedReceiptFill: true,
            ),
            preview: const ColoredBox(color: Color(0xFF38444B)),
            onBack: () {},
            onCapture: () {},
            onSettings: () {},
            onReviewCapturedPhotos: _noop,
            onAddPhoto: _noop,
            capturedPhotoCount: 3,
            longReceiptMode: true,
            guidanceStatus: 'Manual capture is ready.',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final guidanceRect = tester.getRect(
        find.text('Manual capture is ready.'),
      );
      final nextRect = tester.getRect(find.text('Done (3)'));
      final addRect = tester.getRect(find.text('Add Photo'));

      expect(guidanceRect.bottom, lessThan(nextRect.top));
      expect(guidanceRect.bottom, lessThan(addRect.top));
    },
  );
}

void _noop() {}
