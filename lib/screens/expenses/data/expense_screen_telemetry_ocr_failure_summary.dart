part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryOcrFailureSummary {
  const _ExpenseTelemetryOcrFailureSummary({
    required this.causeCounts,
    required this.sourceCounts,
    required this.stageCounts,
    required this.topCause,
    required this.topSource,
    required this.topStage,
  });

  final Map<String, int> causeCounts;
  final Map<String, int> sourceCounts;
  final Map<String, int> stageCounts;
  final String topCause;
  final String topSource;
  final String topStage;
}

_ExpenseTelemetryOcrFailureSummary _buildExpenseTelemetryOcrFailureSummary(
  Iterable<ExpenseFailureBreakdown> failureBreakdowns,
) {
  final causeCounts = <String, int>{};
  final sourceCounts = <String, int>{};
  final stageCounts = <String, int>{};

  for (final failure in failureBreakdowns) {
    if (failure.workflowStep != ExpenseWorkflowStep.receiptOcr.name) {
      continue;
    }
    causeCounts.update(
      failure.confirmedCause,
      (count) => count + failure.count,
      ifAbsent: () => failure.count,
    );
    sourceCounts.update(
      _ocrSourceFromEvidence(failure.evidence),
      (count) => count + failure.count,
      ifAbsent: () => failure.count,
    );
    stageCounts.update(
      failure.failedAt,
      (count) => count + failure.count,
      ifAbsent: () => failure.count,
    );
  }

  return _ExpenseTelemetryOcrFailureSummary(
    causeCounts: Map.unmodifiable(causeCounts),
    sourceCounts: Map.unmodifiable(sourceCounts),
    stageCounts: Map.unmodifiable(stageCounts),
    topCause: _topCountKey(causeCounts),
    topSource: _topCountKey(sourceCounts),
    topStage: _topCountKey(stageCounts),
  );
}
