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
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Capture Receipt Photo'), findsOneWidget);
    expect(find.text('Upload Receipt Photos'), findsOneWidget);
    expect(find.text('Upload PDF/File'), findsOneWidget);
    expect(find.text('Text File'), findsOneWidget);
    expect(find.text('Paste Text'), findsOneWidget);
    expect(find.text('Share Help'), findsOneWidget);
    expect(find.textContaining('choose Maintainiac'), findsOneWidget);

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

  testWidgets('receipt import help remains usable on short screens', (
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
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt Import Help'), findsOneWidget);
    expect(find.text('Got It'), findsOneWidget);

    await tester.tap(find.text('Got It'));
    await tester.pumpAndSettle();

    expect(find.text('Capture or upload receipt'), findsOneWidget);
  });
}
