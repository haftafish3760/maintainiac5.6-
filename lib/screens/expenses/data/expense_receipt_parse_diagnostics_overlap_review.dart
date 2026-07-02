part of 'expense_receipt_parser.dart';

extension ExpenseReceiptParseDiagnosticsOverlapReview
    on ExpenseReceiptParseDiagnostics {
  bool get hasParserDuplicateOverlapReview =>
      parserTaskCount('long_receipt_duplicate_text') > 0 ||
      parserTaskCount('long_receipt_near_duplicate_text') > 0 ||
      parserTaskCount('long_receipt_probable_overlap') > 0;

  bool get hasParserDuplicateOverlapSourceLabels =>
      parserDuplicateOverlapSourceLabels.isNotEmpty;

  int get parserDuplicateOverlapAnchorCount =>
      parserDuplicateOverlapSourceLabels.length;

  bool get hasParserDuplicateOverlapWindowLabels =>
      parserDuplicateOverlapWindowLabels.isNotEmpty;

  String get parserDuplicateOverlapWindowSummaryLabel {
    if (!hasParserDuplicateOverlapWindowLabels) return '';
    final windows = parserDuplicateOverlapWindowLabels.take(2).join(', ');
    if (parserDuplicateOverlapWindowLabels.length <= 2) return windows;
    return '$windows, +${parserDuplicateOverlapWindowLabels.length - 2} more';
  }

  bool get hasParserDuplicateOverlapConfidenceLabels =>
      parserDuplicateOverlapConfidenceLabels.isNotEmpty;

  String get parserDuplicateOverlapConfidenceSummaryLabel {
    if (!hasParserDuplicateOverlapConfidenceLabels) return '';
    final confidence = parserDuplicateOverlapConfidenceLabels
        .take(2)
        .join(', ');
    if (parserDuplicateOverlapConfidenceLabels.length <= 2) return confidence;
    return '$confidence, +${parserDuplicateOverlapConfidenceLabels.length - 2} more';
  }

  String get parserDuplicateOverlapEvidenceSummaryLabel {
    if (!hasParserDuplicateOverlapReview) return '';
    final anchorCount = parserDuplicateOverlapAnchorCount;
    final parts = <String>[
      if (anchorCount > 0)
        anchorCount == 1 ? '1 overlap anchor' : '$anchorCount overlap anchors',
      if (parserDuplicateOverlapConfidenceSummaryLabel.isNotEmpty)
        parserDuplicateOverlapConfidenceSummaryLabel,
      if (parserDuplicateOverlapWindowSummaryLabel.isNotEmpty)
        parserDuplicateOverlapWindowSummaryLabel,
    ];
    if (parts.isEmpty) return 'Repeated receipt overlap needs review';
    return parts.join(' | ');
  }

  String get parserDuplicateOverlapSourceSummaryLabel {
    if (!hasParserDuplicateOverlapSourceLabels) return '';
    final anchors = parserDuplicateOverlapSourceLabels.take(2).join(', ');
    if (parserDuplicateOverlapSourceLabels.length <= 2) return anchors;
    return '$anchors, +${parserDuplicateOverlapSourceLabels.length - 2} more';
  }

  String get parserDuplicateOverlapReviewLabel {
    if (!hasParserDuplicateOverlapReview) return '';
    final sourceLabel = parserDuplicateOverlapSourceSummaryLabel;
    if (sourceLabel.isNotEmpty) {
      return 'Check repeated overlap near $sourceLabel';
    }
    final duplicateCount =
        parserTaskCount('long_receipt_duplicate_text') +
        parserTaskCount('long_receipt_near_duplicate_text');
    if (duplicateCount > 1) {
      return 'Check $duplicateCount repeated overlap lines';
    }
    return 'Check repeated overlap line';
  }

  String get parserDuplicateOverlapReviewInstruction {
    if (!hasParserDuplicateOverlapReview) return '';
    final sourceLabel = parserDuplicateOverlapSourceSummaryLabel;
    if (sourceLabel.isNotEmpty) {
      final windowLabel = parserDuplicateOverlapWindowSummaryLabel;
      final windowText = windowLabel.isEmpty ? '' : ' ($windowLabel)';
      return 'Compare $sourceLabel$windowText before saving so repeated receipt overlap is not counted twice.';
    }
    return 'Compare the repeated receipt lines before saving so duplicate charges are not counted twice.';
  }
}
