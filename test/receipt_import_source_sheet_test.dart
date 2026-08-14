import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_attachment_panel.dart';

void main() {
  test(
    'manual receipt keeps source choices behind its confirmed setup while app-assisted starts with the source choice',
    () async {
      final panel = await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
      ).readAsString();
      final expenseAttachment = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_attachment_panel.dart',
      ).readAsString();

      expect(panel, contains('this.openImportOptionsOnFirstBuild = false'));
      expect(
        panel,
        contains(
          'if (widget.openImportOptionsOnFirstBuild && !_hasAttachment)',
        ),
      );
      expect(panel, contains('unawaited(openReceiptImportOptions())'));
      expect(expenseAttachment, contains('final startsWithAssistedCapture ='));
      expect(
        expenseAttachment,
        contains('receiptSettings?.appAssistedEnabledFor(_receiptCaptureArea)'),
      );
      expect(expenseAttachment, contains('closeParentWhenImportCanceled:'));
    },
  );

  testWidgets('receipt import sheet exposes common sources and help returns', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SharedReceiptAttachmentPanel(
              hasReceipt: false,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add Receipt'));
    await tester.pumpAndSettle();

    expect(
      find.text('Choose how you want to add this receipt.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byTooltip('Receipt settings'), findsOneWidget);
    expect(find.byTooltip('Receipt help'), findsOneWidget);
    expect(find.text('Capture Photo'), findsOneWidget);
    expect(find.text('Upload Photos'), findsOneWidget);
    expect(find.text('Upload PDF/File'), findsOneWidget);
    expect(find.text('Paste/Text'), findsOneWidget);
    expect(find.text('Text File'), findsNothing);
    expect(find.text('Share Help'), findsNothing);

    await tester.tap(find.byTooltip('Receipt help'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt Import Help'), findsOneWidget);
    expect(find.text('Capture Receipt Photo'), findsOneWidget);
    expect(find.text('Paste Text'), findsOneWidget);
    expect(find.text('Share Help'), findsOneWidget);
    expect(find.text('Text File'), findsOneWidget);
    expect(find.textContaining('one or more receipt photos'), findsOneWidget);
    expect(find.text('Got It'), findsOneWidget);

    await tester.tap(find.text('Got It'));
    await tester.pumpAndSettle();

    expect(
      find.text('Choose how you want to add this receipt.'),
      findsOneWidget,
    );
    expect(find.text('Upload PDF/File'), findsOneWidget);
  });

  testWidgets('receipt import sheet remains usable on short screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SharedReceiptAttachmentPanel(
              hasReceipt: false,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add Receipt'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose how you want to add this receipt.'),
      findsOneWidget,
    );
    expect(find.text('Capture Photo'), findsOneWidget);
    expect(find.text('Upload PDF/File'), findsOneWidget);

    await tester.tap(find.byTooltip('Receipt help'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt Import Help'), findsOneWidget);
    expect(find.text('Got It'), findsOneWidget);

    await tester.tap(find.text('Got It'));
    await tester.pumpAndSettle();

    expect(
      find.text('Choose how you want to add this receipt.'),
      findsOneWidget,
    );
  });

  testWidgets('paste slash text opens paste or text file chooser', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SharedReceiptAttachmentPanel(
              hasReceipt: false,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add Receipt'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Paste/Text'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Paste/Text'));
    await tester.pumpAndSettle();

    expect(find.text('Paste or import receipt text'), findsOneWidget);
    expect(find.text('Paste Text'), findsOneWidget);
    expect(find.text('Text File'), findsOneWidget);
  });

  test(
    'receipt import chooser uses a full-screen, labeled source picker',
    () async {
      final source = await File(
        'lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart',
      ).readAsString();
      final tile = await File(
        'lib/shared/widgets/receipt_capture/receipt_import_source_tile.dart',
      ).readAsString();

      final openStart = source.indexOf('Future<void> openReceiptImportOptions');
      final openEnd = source.indexOf('Future<void> _showReceiptShareHelp');
      final openBlock = source.substring(openStart, openEnd);

      expect(openBlock, contains('Navigator.of(context).push'));
      expect(openBlock, contains('MaterialPageRoute'));
      expect(openBlock, contains('fullscreenDialog: true'));
      expect(source, contains('child: Scaffold('));
      expect(source, contains("tooltip: 'Back to receipt'"));
      expect(source, contains('SafeArea('));
      expect(source, contains('SingleChildScrollView('));
      expect(
        source,
        contains('final columns = constraints.maxWidth >= 340 ? 2 : 1'),
      );
      expect(source, contains('return Wrap('));
      expect(source, contains("label: 'Capture Photo'"));
      expect(source, contains("label: 'Upload Photos'"));
      expect(source, contains("label: 'Upload PDF/File'"));
      expect(source, contains("label: 'Paste/Text'"));
      expect(source, isNot(contains("label: 'Text File'")));
      expect(source, isNot(contains("label: 'Share Help'")));
      expect(source, isNot(contains('_ReceiptPrimaryImportTile')));
      expect(tile, isNot(contains('class _ReceiptPrimaryImportTile')));
      expect(tile, isNot(contains('width: 58')));
      expect(tile, isNot(contains('height: 58')));
    },
  );

  test('Android receipt image import uses the system photo picker', () async {
    final imagePicker = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_picker.dart',
    ).readAsString();

    // Immediate handoff and single-transaction behavior are exercised by
    // receipt_import_transaction_widget_test.dart. Keep this static check
    // narrowly scoped to the platform integration it can actually prove.
    expect(imagePicker, contains('platformPicker is ImagePickerAndroid'));
    expect(imagePicker, contains('useAndroidPhotoPicker = true'));
  });

  test('receipt source chooser asks for Receipt Assist once first', () async {
    final source = await File(
      'lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart',
    ).readAsString();
    final cameraActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
    ).readAsString();
    final intro = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart',
    ).readAsString();
    final uiConfig = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_ui_config.dart',
    ).readAsString();

    final openStart = source.indexOf('Future<void> openReceiptImportOptions');
    final openEnd = source.indexOf('Future<void> _showReceiptShareHelp');
    final openBlock = source.substring(openStart, openEnd);
    final introIndex = openBlock.indexOf('_showFirstUseReceiptAssistIntro');
    final chooserIndex = openBlock.indexOf('Navigator.of(context).push');
    expect(introIndex, greaterThanOrEqualTo(0));
    expect(chooserIndex, greaterThan(introIndex));
    expect(
      openBlock,
      contains('!settings.hasReceiptAssistChoiceFor(widget.area)'),
    );
    expect(
      openBlock,
      contains('intent != ReceiptImportEntryIntent.optionalManualProof'),
    );
    final captureCaseStart = openBlock.indexOf(
      'case ReceiptImportSourceAction.camera',
    );
    final imageCaseStart = openBlock.indexOf(
      'case ReceiptImportSourceAction.image',
    );
    final captureCase = openBlock.substring(captureCaseStart, imageCaseStart);

    expect(captureCase, contains('return takeReceiptPhoto('));
    expect(
      captureCase,
      contains('ReceiptImportEntryIntent.optionalManualProof'),
    );
    expect(captureCase, isNot(contains('openReceiptCaptureSettings')));
    expect(captureCase, isNot(contains('defaultDataSaverLevel')));
    expect(captureCase, isNot(contains('parserPackInstallChoice')));

    final takeStart = cameraActions.indexOf(
      'Future<ReceiptImportActionResult> takeReceiptPhoto',
    );
    final takeEnd = cameraActions.indexOf(
      'Future<_MaintainiacNativeCameraPhotoResult>',
    );
    final takeBlock = cameraActions.substring(takeStart, takeEnd);
    final cameraIntroIndex = takeBlock.indexOf(
      '_showFirstUseReceiptAssistIntro',
    );
    final nativeIndex = takeBlock.indexOf('_takeMaintainiacNativeCameraPhoto');

    expect(cameraIntroIndex, greaterThanOrEqualTo(0));
    expect(nativeIndex, greaterThan(cameraIntroIndex));
    expect(takeBlock, isNot(contains('openReceiptCaptureSettings')));
    expect(takeBlock, isNot(contains('Saved Receipt Proof Size')));
    expect(takeBlock, isNot(contains('defaultDataSaverLevel')));
    expect(takeBlock, isNot(contains('parserPackInstallChoice')));

    expect(intro, contains('uiConfig.firstUsePrompt'));
    expect(intro, contains('SingleChildScrollView('));
    expect(intro, contains('MediaQuery.viewInsetsOf(context).bottom'));
    expect(
      uiConfig,
      contains('Would you like Maintainiac to help fill out receipt details?'),
    );
    expect(uiConfig, contains('Yes, Use Receipt Assist'));
    expect(uiConfig, contains('No, Manual Entry'));
    expect(intro, contains('Manual entry is always available'));
    expect(intro, isNot(contains('OCR')));
    expect(intro, isNot(contains('compression')));
    expect(intro, isNot(contains('storage')));
    expect(intro, isNot(contains('Saved Receipt Proof Size')));
  });
}
