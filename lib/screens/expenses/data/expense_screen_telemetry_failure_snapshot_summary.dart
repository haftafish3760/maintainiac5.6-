part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryFailureSnapshotSummary {
  const _ExpenseTelemetryFailureSnapshotSummary({
    required this.breakdowns,
    required this.ocrFailure,
    required this.recentDetails,
  });

  final List<ExpenseFailureBreakdown> breakdowns;
  final _ExpenseTelemetryOcrFailureSummary ocrFailure;
  final List<ExpenseFailureEventDetail> recentDetails;
}

extension _ExpenseTelemetryFailureSnapshotSummaryBuilder
    on _ExpenseTelemetryHealthSnapshotAccumulator {
  _ExpenseTelemetryFailureSnapshotSummary buildFailureSnapshotSummary() {
    final breakdowns =
        failureStats.values.map((stats) => stats.toBreakdown()).toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return _ExpenseTelemetryFailureSnapshotSummary(
      breakdowns: List.unmodifiable(breakdowns),
      ocrFailure: _buildExpenseTelemetryOcrFailureSummary(breakdowns),
      recentDetails: List.unmodifiable(
        recentFailures.reversed.take(100).toList(growable: false),
      ),
    );
  }
}
