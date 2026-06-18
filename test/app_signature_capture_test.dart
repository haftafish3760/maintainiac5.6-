import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/signatures/app_signature_capture.dart';
import 'package:maintaniac/shared/signatures/app_signature_models.dart';

void main() {
  testWidgets('signature capture saves finger or stylus ink', (tester) async {
    AppSignatureResult? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () async {
                    saved = await showModalBottomSheet<AppSignatureResult>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const AppSignatureCaptureSheet(
                        role: AppSignatureRole.owner,
                        title: 'Add My Signature',
                      ),
                    );
                  },
                  child: const Text('Open Signature'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Signature'));
    await tester.pumpAndSettle();

    expect(find.text('Add My Signature'), findsOneWidget);
    expect(find.text('Save Signature'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNull,
    );

    await tester.drag(
      find.byKey(const Key('app-signature-canvas')),
      const Offset(120, 36),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Save Signature'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.role, AppSignatureRole.owner);
    expect(saved!.hasInk, isTrue);
  });
}
