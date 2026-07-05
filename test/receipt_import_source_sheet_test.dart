import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_attachment_panel.dart';

void main() {
  testWidgets('receipt import route exposes common sources and help returns', (
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
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Capture Receipt Photo'), findsOneWidget);
    expect(find.text('Upload Receipt Photos'), findsOneWidget);
    expect(find.text('Upload PDF/File'), findsOneWidget);
    expect(find.text('Text File'), findsOneWidget);
    expect(find.text('Paste Text'), findsOneWidget);
    expect(find.text('Share Help'), findsOneWidget);

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

  testWidgets('receipt import route remains usable on short screens', (
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
    expect(find.text('Capture Receipt Photo'), findsOneWidget);
    expect(find.text('Upload PDF/File'), findsOneWidget);

    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt Import Help'), findsOneWidget);
    expect(find.text('Got It'), findsOneWidget);

    await tester.tap(find.text('Got It'));
    await tester.pumpAndSettle();

    expect(find.text('Capture or upload receipt'), findsOneWidget);
  });

  test('receipt import chooser is a safe full-screen route', () async {
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
    expect(openBlock, isNot(contains('showModalBottomSheet')));
    expect(source, contains('return Scaffold('));
    expect(source, contains('SafeArea('));
    expect(source, contains('ListView('));
    expect(source, contains('_ReceiptPrimaryImportTile'));
    expect(tile, contains('class _ReceiptPrimaryImportTile'));
    expect(tile, contains('width: 58'));
    expect(tile, contains('height: 58'));
  });
}
