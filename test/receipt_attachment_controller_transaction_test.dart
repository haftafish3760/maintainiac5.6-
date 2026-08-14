import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  testWidgets('attached receipt controller opens one visible source route', (
    tester,
  ) async {
    final controller = ReceiptAttachmentPanelController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SharedReceiptAttachmentPanel(
            controller: controller,
            hasReceipt: false,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(controller.isAttached, isTrue);
    final resultFuture = controller.openImportOptions();
    await tester.pumpAndSettle();

    expect(find.text('Upload Photos'), findsOneWidget);
    expect(
      find.text('Choose how you want to add this receipt.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Back to receipt'));
    await tester.pumpAndSettle();

    expect(await resultFuture, isNull);
    expect(find.text('Attach A Receipt'), findsOneWidget);
  });
}
