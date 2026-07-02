part of 'expense_screen_telemetry.dart';

extension _ExpenseTelemetryParserSnapshotSummary
    on _ExpenseTelemetryHealthSnapshotAccumulator {
  Map<String, int> get parserCategorySnapshotCounts =>
      Map.unmodifiable(parserCategoryCounts);

  Map<String, int> get parserNeedsReviewCategorySnapshotCounts =>
      Map.unmodifiable(parserNeedsReviewCategoryCounts);

  Map<String, int> get parserFailedCategorySnapshotCounts =>
      Map.unmodifiable(parserFailedCategoryCounts);

  Map<String, int> get parserFieldConfidenceSnapshotCounts =>
      Map.unmodifiable(parserFieldConfidenceCounts);

  Map<String, int> get parserCategoryHealthSnapshotCounts =>
      Map.unmodifiable(parserCategoryHealthCounts);

  Map<String, int> get parserCategoryReviewActionSnapshotCounts =>
      Map.unmodifiable(parserCategoryReviewActionCounts);

  Map<String, int> get parserPackPressureStatusSnapshotCounts =>
      Map.unmodifiable(parserPackPressureStatusCounts);

  Map<String, int> get parserRequiredFieldStatusSnapshotCounts =>
      Map.unmodifiable(parserRequiredFieldStatusCounts);

  Map<String, int> get parserDownstreamReadinessStatusSnapshotCounts =>
      Map.unmodifiable(parserDownstreamReadinessStatusCounts);

  Map<String, int> get parserDownstreamReadinessSnapshotCounts =>
      Map.unmodifiable(parserDownstreamReadinessCounts);

  Map<String, int> get parserReviewRootCauseSnapshotCounts =>
      Map.unmodifiable(parserReviewRootCauseCounts);

  Map<String, int> get localReceiptParserRoutingSnapshotCounts =>
      Map.unmodifiable(localReceiptParserRoutingCounts);

  Map<String, int> get localParserEvidenceOutcomeSnapshotCounts =>
      Map.unmodifiable(localParserEvidenceOutcomeCounts);

  Map<String, int> get ocrParserTaskSnapshotCounts =>
      Map.unmodifiable(ocrParserTaskCounts);

  Map<String, int> get ocrFieldReadinessSnapshotCounts =>
      Map.unmodifiable(ocrFieldReadinessCounts);

  String get topParserCategory => _topCountKey(parserCategoryCounts);

  String get topParserNeedsReviewCategory =>
      _topCountKey(parserNeedsReviewCategoryCounts);

  String get topParserFailedCategory =>
      _topCountKey(parserFailedCategoryCounts);

  String get topParserCategoryHealth =>
      _topCountKey(parserCategoryHealthCounts);

  String get topParserCategoryReviewAction =>
      _topCountKey(parserCategoryReviewActionCounts);

  String get topParserPackPressureStatus =>
      _topCountKey(parserPackPressureStatusCounts);

  String get topParserRequiredFieldStatus =>
      _topCountKey(parserRequiredFieldStatusCounts);

  String get topParserDownstreamReadinessStatus =>
      _topCountKey(parserDownstreamReadinessStatusCounts);

  String get topParserDownstreamReadiness =>
      _topCountKey(parserDownstreamReadinessCounts);

  String get topParserReviewRootCause =>
      _topCountKey(parserReviewRootCauseCounts);

  String get topLocalReceiptParserRouting =>
      _topCountKey(localReceiptParserRoutingCounts);

  String get topLocalParserEvidenceOutcome =>
      _topCountKey(localParserEvidenceOutcomeCounts);

  String get topOcrParserTask => _topCountKey(ocrParserTaskCounts);

  String get topOcrFieldReadiness => _topCountKey(ocrFieldReadinessCounts);
}
