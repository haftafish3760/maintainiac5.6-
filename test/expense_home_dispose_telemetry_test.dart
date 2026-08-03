import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense home disposal uses the cached telemetry snapshot', () {
    final source = File(
      'lib/screens/expenses/home/expenses_home_screen.dart',
    ).readAsStringSync();
    final disposeStart = source.indexOf('void dispose()');
    final disposeEnd = source.indexOf(
      '@override\n  Widget build',
      disposeStart,
    );

    expect(disposeStart, greaterThanOrEqualTo(0));
    expect(disposeEnd, greaterThan(disposeStart));
    expect(
      source,
      contains(
        '_telemetrySnapshot = ExpenseScreenTelemetryRecorder.snapshot(context)',
      ),
    );
    final disposeBody = source.substring(disposeStart, disposeEnd);
    expect(
      disposeBody,
      contains('ExpenseScreenTelemetryRecorder.recordSnapshot('),
    );
    expect(
      disposeBody,
      isNot(contains('ExpenseScreenTelemetryRecorder.record(\n      context')),
    );
  });
}
