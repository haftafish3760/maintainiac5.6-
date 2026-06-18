import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_viewer_screen.dart';

void main() {
  testWidgets('missing PDF proof explains recovery to screen readers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReceiptPdfViewerScreen(
          path: '/tmp/maintainiac_missing_accessibility.pdf',
          title: 'Missing receipt proof',
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    final missingTitle = find.text('Receipt PDF not found');
    for (var pump = 0; pump < 20 && missingTitle.evaluate().isEmpty; pump++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(missingTitle, findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('Receipt PDF not found.*needs to be reattached'),
      ),
      findsOneWidget,
    );
  });
}
