import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/home/invoice_form_details.dart';
import 'package:maintaniac/shared/signatures/app_signature_models.dart';

void main() {
  testWidgets('signature sheet can apply saved owner signature only', (
    tester,
  ) async {
    final saved = _signature(AppSignatureRole.owner);
    AppSignatureResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  result = await showInvoiceSignatureSheet(
                    context,
                    savedOwnerSignature: saved,
                  );
                },
                child: const Text('Open Signature Sheet'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Signature Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Use Saved My Signature'), findsOneWidget);
    expect(find.text('Update My Saved Signature'), findsOneWidget);
    expect(find.text('Add Customer Signature'), findsOneWidget);

    await tester.tap(find.text('Use Saved My Signature'));
    await tester.pumpAndSettle();

    expect(result, same(saved));
    expect(result!.role, AppSignatureRole.owner);
  });

  testWidgets('signature sheet without saved owner still requires capture', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () => showInvoiceSignatureSheet(context),
                child: const Text('Open Signature Sheet'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Signature Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Use Saved My Signature'), findsNothing);
    expect(find.text('Add My Signature'), findsOneWidget);
    expect(find.text('Add Customer Signature'), findsOneWidget);
  });
}

AppSignatureResult _signature(AppSignatureRole role) {
  return AppSignatureResult(
    role: role,
    signedAt: DateTime(2026, 6, 15, 10),
    strokes: const [
      AppSignatureStroke([Offset(1, 1), Offset(9, 9)]),
    ],
  );
}
