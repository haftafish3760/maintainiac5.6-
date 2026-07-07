import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_attachment_panel.dart';

void main() {
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

    expect(find.text('Capture or upload receipt'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Capture Photo'), findsOneWidget);
    expect(find.text('Upload Photos'), findsOneWidget);
    expect(find.text('Upload PDF/File'), findsOneWidget);
    expect(find.text('Paste/Text'), findsOneWidget);
    expect(find.text('Text File'), findsNothing);
    expect(find.text('Share Help'), findsNothing);

    await tester.scrollUntilVisible(
      find.textContaining('choose Maintainiac'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('choose Maintainiac'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Help'),
      -120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Help'));
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

    expect(find.text('Capture or upload receipt'), findsOneWidget);
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
    expect(find.text('Capture or upload receipt'), findsOneWidget);
    expect(find.text('Capture Photo'), findsOneWidget);
    expect(find.text('Upload PDF/File'), findsOneWidget);

    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt Import Help'), findsOneWidget);
    expect(find.text('Got It'), findsOneWidget);

    await tester.tap(find.text('Got It'));
    await tester.pumpAndSettle();

    expect(find.text('Capture or upload receipt'), findsOneWidget);
  });

  test('receipt import chooser keeps original compact sheet grid', () async {
    final source = await File(
      'lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart',
    ).readAsString();
    final tile = await File(
      'lib/shared/widgets/receipt_capture/receipt_import_source_tile.dart',
    ).readAsString();

    final openStart = source.indexOf('Future<void> openReceiptImportOptions');
    final openEnd = source.indexOf('Future<void> _showReceiptShareHelp');
    final openBlock = source.substring(openStart, openEnd);

    expect(openBlock, contains('showModalBottomSheet'));
    expect(openBlock, isNot(contains('Navigator.of(context).push')));
    expect(openBlock, isNot(contains('MaterialPageRoute')));
    expect(openBlock, isNot(contains('fullscreenDialog: true')));
    expect(source, isNot(contains('return Scaffold(')));
    expect(source, contains('SafeArea('));
    expect(source, contains('SingleChildScrollView('));
    expect(source, contains('crossAxisCount: 2'));
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
  });

  test('capture path asks only receipt assist before camera launch', () async {
    final source = await File(
      'lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart',
    ).readAsString();
    final cameraActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
    ).readAsString();
    final intro = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart',
    ).readAsString();

    final openStart = source.indexOf('Future<void> openReceiptImportOptions');
    final openEnd = source.indexOf('Future<void> _showReceiptShareHelp');
    final openBlock = source.substring(openStart, openEnd);
    final captureCaseStart = openBlock.indexOf(
      'case _ReceiptImportAction.camera',
    );
    final imageCaseStart = openBlock.indexOf('case _ReceiptImportAction.image');
    final captureCase = openBlock.substring(captureCaseStart, imageCaseStart);

    expect(captureCase, contains('await takeReceiptPhoto();'));
    expect(captureCase, isNot(contains('openReceiptCaptureSettings')));
    expect(captureCase, isNot(contains('defaultDataSaverLevel')));
    expect(captureCase, isNot(contains('parserPackInstallChoice')));

    final takeStart = cameraActions.indexOf('Future<void> takeReceiptPhoto');
    final takeEnd = cameraActions.indexOf(
      'Future<_MaintainiacNativeCameraPhotoOutcome>',
    );
    final takeBlock = cameraActions.substring(takeStart, takeEnd);
    final introIndex = takeBlock.indexOf('_showFirstUseReceiptCameraIntro');
    final nativeIndex = takeBlock.indexOf('_takeMaintainiacNativeCameraPhoto');

    expect(introIndex, greaterThanOrEqualTo(0));
    expect(nativeIndex, greaterThan(introIndex));
    expect(takeBlock, isNot(contains('openReceiptCaptureSettings')));
    expect(takeBlock, isNot(contains('Saved Receipt Proof Size')));
    expect(takeBlock, isNot(contains('defaultDataSaverLevel')));
    expect(takeBlock, isNot(contains('parserPackInstallChoice')));

    expect(
      intro,
      contains('Would you like Maintainiac to help fill out receipt details?'),
    );
    expect(intro, contains('Yes, Use Receipt Assist'));
    expect(intro, contains('No, Manual Entry'));
    expect(intro, contains('Manual entry is always available'));
    expect(intro, isNot(contains('OCR')));
    expect(intro, isNot(contains('compression')));
    expect(intro, isNot(contains('storage')));
    expect(intro, isNot(contains('Saved Receipt Proof Size')));
  });
}
