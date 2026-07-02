part of '../../receipts/receipt_ocr_contract.dart';

class ReceiptOcrSourceHandoffSummary {
  const ReceiptOcrSourceHandoffSummary({
    required this.sourceSignalCounts,
    required this.riskFlagCounts,
    required this.sourceFirstDecisionCounts,
    required this.sourceFirstOutcomeCounts,
    required this.handoffSignalCounts,
    required this.handoffWarningProfileCounts,
    required this.stitchSignalCounts,
    required this.scannerDecisionCounts,
    required this.captureSourceSignalCounts,
    required this.coverageSignalCounts,
    required this.continuationSignalCounts,
    required this.completionSignalCounts,
    required this.photoQualityRiskCounts,
  });

  const ReceiptOcrSourceHandoffSummary.empty()
    : sourceSignalCounts = const {},
      riskFlagCounts = const {},
      sourceFirstDecisionCounts = const {},
      sourceFirstOutcomeCounts = const {},
      handoffSignalCounts = const {},
      handoffWarningProfileCounts = const {},
      stitchSignalCounts = const {},
      scannerDecisionCounts = const {},
      captureSourceSignalCounts = const {},
      coverageSignalCounts = const {},
      continuationSignalCounts = const {},
      completionSignalCounts = const {},
      photoQualityRiskCounts = const {};

  factory ReceiptOcrSourceHandoffSummary.fromAttachments(
    List<ReceiptAttachmentRecord> attachments,
  ) {
    final sourceSignals = <String, int>{};
    final risks = <String, int>{};
    final sourceFirstDecisions = <String, int>{};
    final sourceFirstOutcomes = <String, int>{};
    final handoffs = <String, int>{};
    final handoffWarnings = <String, int>{};
    final stitches = <String, int>{};
    final scannerDecisions = <String, int>{};
    final captureSources = <String, int>{};
    final coverageSignals = <String, int>{};
    final continuations = <String, int>{};
    final completions = <String, int>{};
    final qualityRisks = <String, int>{};

    for (final attachment in attachments) {
      for (final signal in attachment.documentSignals) {
        final token = _safeOcrHandoffToken(signal);
        if (token.isEmpty) continue;
        _incrementOcrHandoffCount(sourceSignals, token);
        if (token.startsWith('receipt_handoff_')) {
          _incrementOcrHandoffCount(handoffs, token);
        }
        if (token.startsWith('ocr_source_first_')) {
          if (token.startsWith('ocr_source_first_outcome_')) {
            _incrementOcrHandoffCount(sourceFirstOutcomes, token);
          } else {
            _incrementOcrHandoffCount(sourceFirstDecisions, token);
          }
        }
        if (token.startsWith('receipt_handoff_warning_') &&
            token != 'receipt_handoff_warning_saved_photo_ok') {
          _incrementOcrHandoffCount(handoffWarnings, token);
        }
        if (token.startsWith('receipt_handoff_stitch_') ||
            token.startsWith('stitch_overlap_') ||
            token.startsWith('stitch_source_') ||
            token == 'stitched_ocr_source' ||
            token == 'multiple_ocr_sources_fallback') {
          _incrementOcrHandoffCount(stitches, token);
        }
        if (token.startsWith('scanner_decision_')) {
          _incrementOcrHandoffCount(scannerDecisions, token);
        }
        if (_isOcrCaptureSourceSignal(token)) {
          _incrementOcrHandoffCount(captureSources, token);
        }
        if (token.startsWith('receipt_coverage_')) {
          _incrementOcrHandoffCount(coverageSignals, token);
        }
        if (token.startsWith('receipt_continuation_')) {
          _incrementOcrHandoffCount(continuations, token);
        }
        if (token.startsWith('receipt_completion_')) {
          _incrementOcrHandoffCount(completions, token);
        }
      }
      for (final risk in attachment.riskFlags) {
        final token = _safeOcrHandoffToken(risk);
        if (token.isEmpty) continue;
        _incrementOcrHandoffCount(risks, token);
        if (token.startsWith('ocr_source_first_')) {
          _incrementOcrHandoffCount(sourceFirstDecisions, token);
        }
        if (token.startsWith('ocr_source_')) {
          _incrementOcrHandoffCount(qualityRisks, token);
        }
        if (token.startsWith('ocr_source_continuation_')) {
          _incrementOcrHandoffCount(continuations, token);
        }
        if (token.startsWith('ocr_source_completion_')) {
          _incrementOcrHandoffCount(completions, token);
        }
      }
      for (final warning in attachment.photoQualityWarnings) {
        final token = _safeOcrHandoffToken('photo_quality_$warning');
        if (token.isEmpty) continue;
        _incrementOcrHandoffCount(qualityRisks, token);
      }
    }

    return ReceiptOcrSourceHandoffSummary(
      sourceSignalCounts: Map.unmodifiable(sourceSignals),
      riskFlagCounts: Map.unmodifiable(risks),
      sourceFirstDecisionCounts: Map.unmodifiable(sourceFirstDecisions),
      sourceFirstOutcomeCounts: Map.unmodifiable(sourceFirstOutcomes),
      handoffSignalCounts: Map.unmodifiable(handoffs),
      handoffWarningProfileCounts: Map.unmodifiable(handoffWarnings),
      stitchSignalCounts: Map.unmodifiable(stitches),
      scannerDecisionCounts: Map.unmodifiable(scannerDecisions),
      captureSourceSignalCounts: Map.unmodifiable(captureSources),
      coverageSignalCounts: Map.unmodifiable(coverageSignals),
      continuationSignalCounts: Map.unmodifiable(continuations),
      completionSignalCounts: Map.unmodifiable(completions),
      photoQualityRiskCounts: Map.unmodifiable(qualityRisks),
    );
  }

  final Map<String, int> sourceSignalCounts;
  final Map<String, int> riskFlagCounts;
  final Map<String, int> sourceFirstDecisionCounts;
  final Map<String, int> sourceFirstOutcomeCounts;
  final Map<String, int> handoffSignalCounts;
  final Map<String, int> handoffWarningProfileCounts;
  final Map<String, int> stitchSignalCounts;
  final Map<String, int> scannerDecisionCounts;
  final Map<String, int> captureSourceSignalCounts;
  final Map<String, int> coverageSignalCounts;
  final Map<String, int> continuationSignalCounts;
  final Map<String, int> completionSignalCounts;
  final Map<String, int> photoQualityRiskCounts;

  bool get hasSignals =>
      sourceSignalCounts.isNotEmpty ||
      riskFlagCounts.isNotEmpty ||
      sourceFirstDecisionCounts.isNotEmpty ||
      sourceFirstOutcomeCounts.isNotEmpty ||
      handoffSignalCounts.isNotEmpty ||
      handoffWarningProfileCounts.isNotEmpty ||
      stitchSignalCounts.isNotEmpty ||
      scannerDecisionCounts.isNotEmpty ||
      captureSourceSignalCounts.isNotEmpty ||
      coverageSignalCounts.isNotEmpty ||
      continuationSignalCounts.isNotEmpty ||
      completionSignalCounts.isNotEmpty ||
      photoQualityRiskCounts.isNotEmpty;
}
