import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/workday_note_sheet.dart';

void main() {
  testWidgets('workday note requires text and returns the trimmed note', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await openWorkdayNoteSheet(context);
              },
              child: const Text('Add note'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Save Note');
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Picked up filters  ');
    await tester.pump();
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);

    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(result, 'Picked up filters');
  });

  testWidgets('cancel does not create a note', (tester) async {
    String? result = 'unchanged';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await openWorkdayNoteSheet(context);
              },
              child: const Text('Add note'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
