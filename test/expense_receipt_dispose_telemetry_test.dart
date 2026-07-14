import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt entry disposal never reads inherited state from context', () {
    final lifecycle = File(
      'lib/screens/expenses/entry/expense_receipt_entry_lifecycle_helpers.dart',
    ).readAsStringSync();
    final disposeStart = lifecycle.indexOf('void _disposeReceiptEntryState()');
    final disposeEnd = lifecycle.indexOf(
      'Future<void> _discardUncommittedEditProofs()',
      disposeStart,
    );

    expect(disposeStart, greaterThanOrEqualTo(0));
    expect(disposeEnd, greaterThan(disposeStart));
    final disposeBody = lifecycle.substring(disposeStart, disposeEnd);
    expect(
      lifecycle,
      contains(
        '_telemetrySnapshot = ExpenseScreenTelemetryRecorder.snapshot(context)',
      ),
    );
    expect(disposeBody, contains('recordSnapshot('));
    expect(disposeBody, isNot(contains('Recorder.record(\n      context')));
    expect(disposeBody, isNot(contains('maybeOf(context)')));
  });
}
