part of 'expense_screen_telemetry.dart';

ExpenseTelemetryHealthSnapshot _buildExpenseTelemetryHealthSnapshotFromRecords(
  Iterable<ExpenseTelemetryRecord> records, {
  DateTime? generatedAtUtc,
}) {
  final accumulator = _ExpenseTelemetryHealthSnapshotAccumulator(
    totalEventCount: records.length,
    generatedAtUtc: generatedAtUtc,
  );
  for (final record in records) {
    accumulator.record(record);
  }
  return accumulator.toSnapshot();
}
