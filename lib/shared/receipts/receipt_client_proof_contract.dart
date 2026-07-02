part of 'receipt_processing_contract.dart';

class ReceiptClientProofRedactionLine {
  const ReceiptClientProofRedactionLine({
    required this.receiptLineId,
    required this.proofLineReferenceLabel,
    required this.action,
    required this.reason,
    this.sourceReceiptSectionLabel = '',
    this.wasSelected = false,
  });

  final String receiptLineId;
  final String proofLineReferenceLabel;
  final ReceiptClientProofRedactionAction action;
  final String reason;
  final String sourceReceiptSectionLabel;
  final bool wasSelected;

  bool get isVisible => action == ReceiptClientProofRedactionAction.show;
  bool get isHidden => action == ReceiptClientProofRedactionAction.hide;
  bool get needsReview => action == ReceiptClientProofRedactionAction.review;

  Map<String, Object?> toPrivacySafeMap() {
    return {
      'receiptLineId': receiptLineId,
      'proofLineReferenceLabel': proofLineReferenceLabel,
      'action': action.name,
      'reason': reason,
      if (sourceReceiptSectionLabel.trim().isNotEmpty)
        'sourceReceiptSectionLabel': sourceReceiptSectionLabel.trim(),
      'wasSelected': wasSelected,
    };
  }
}

class ReceiptClientProofRedactionPlan {
  const ReceiptClientProofRedactionPlan({
    required this.receiptId,
    required this.purpose,
    required this.lines,
    required this.totalSourceLineCount,
  });

  factory ReceiptClientProofRedactionPlan.fromBundle(
    ReceiptLineSelectionBundle bundle,
  ) {
    final lines = <ReceiptClientProofRedactionLine>[
      for (final line in bundle.selectedLines)
        ReceiptClientProofRedactionLine(
          receiptLineId: line.receiptLineId,
          proofLineReferenceLabel: line.proofLineReferenceLabel,
          action: line.redactsFromClientProofByDefault
              ? ReceiptClientProofRedactionAction.hide
              : line.needsClientProofReview
              ? ReceiptClientProofRedactionAction.review
              : ReceiptClientProofRedactionAction.show,
          reason: line.redactsFromClientProofByDefault
              ? 'selected_line_hidden_by_default'
              : line.needsClientProofReview
              ? 'selected_line_needs_review_before_share'
              : 'selected_line_safe_to_show',
          sourceReceiptSectionLabel: line.sourceReceiptSectionLabel,
          wasSelected: true,
        ),
      for (var index = 0; index < bundle.excludedLineCount; index++)
        ReceiptClientProofRedactionLine(
          receiptLineId: '${bundle.receiptId}-excluded-${index + 1}',
          proofLineReferenceLabel: 'Excluded line ${index + 1}',
          action: ReceiptClientProofRedactionAction.hide,
          reason: 'not_selected_for_client_proof',
        ),
    ];
    return ReceiptClientProofRedactionPlan(
      receiptId: bundle.receiptId,
      purpose: bundle.purpose,
      lines: List.unmodifiable(lines),
      totalSourceLineCount: bundle.totalSourceLineCount,
    );
  }

  final String receiptId;
  final ReceiptLineSelectionPurpose purpose;
  final List<ReceiptClientProofRedactionLine> lines;
  final int totalSourceLineCount;

  int get visibleLineCount => lines.where((line) => line.isVisible).length;
  int get hiddenLineCount => lines.where((line) => line.isHidden).length;
  int get reviewLineCount => lines.where((line) => line.needsReview).length;
  bool get needsReviewBeforeShare => reviewLineCount > 0;
  bool get hasHiddenLines => hiddenLineCount > 0;
  bool get canShareNow => lines.isNotEmpty && !needsReviewBeforeShare;

  Map<String, Object?> toPrivacySafeMap() {
    return {
      'receiptId': receiptId,
      'purpose': purpose.name,
      'totalSourceLineCount': totalSourceLineCount,
      'visibleLineCount': visibleLineCount,
      'hiddenLineCount': hiddenLineCount,
      'reviewLineCount': reviewLineCount,
      'needsReviewBeforeShare': needsReviewBeforeShare,
      'hasHiddenLines': hasHiddenLines,
      'canShareNow': canShareNow,
      'lines': lines
          .map((line) => line.toPrivacySafeMap())
          .toList(growable: false),
    };
  }
}

class ReceiptClientProofReviewSummary {
  const ReceiptClientProofReviewSummary({
    required this.receiptId,
    required this.purpose,
    required this.status,
    required this.visibleLineCount,
    required this.hiddenLineCount,
    required this.reviewLineCount,
    required this.totalSourceLineCount,
    required this.sourceSectionCount,
    required this.needsManualReview,
    required this.readyToShare,
    required this.recommendedNextAction,
  });

  factory ReceiptClientProofReviewSummary.fromPlan(
    ReceiptClientProofRedactionPlan plan,
  ) {
    final sourceSections = <String>{
      for (final line in plan.lines)
        if (line.sourceReceiptSectionLabel.trim().isNotEmpty)
          line.sourceReceiptSectionLabel.trim(),
    };
    final status = plan.reviewLineCount > 0
        ? 'review_required'
        : plan.hiddenLineCount > 0
        ? 'redacted_ready'
        : 'ready_to_share';
    final recommendedNextAction = switch (status) {
      'review_required' => 'review_lines_before_client_share',
      'redacted_ready' => 'preview_redacted_client_proof',
      _ => 'share_client_proof',
    };
    return ReceiptClientProofReviewSummary(
      receiptId: plan.receiptId,
      purpose: plan.purpose,
      status: status,
      visibleLineCount: plan.visibleLineCount,
      hiddenLineCount: plan.hiddenLineCount,
      reviewLineCount: plan.reviewLineCount,
      totalSourceLineCount: plan.totalSourceLineCount,
      sourceSectionCount: sourceSections.length,
      needsManualReview: plan.needsReviewBeforeShare,
      readyToShare: plan.canShareNow,
      recommendedNextAction: recommendedNextAction,
    );
  }

  final String receiptId;
  final ReceiptLineSelectionPurpose purpose;
  final String status;
  final int visibleLineCount;
  final int hiddenLineCount;
  final int reviewLineCount;
  final int totalSourceLineCount;
  final int sourceSectionCount;
  final bool needsManualReview;
  final bool readyToShare;
  final String recommendedNextAction;

  bool get hasHiddenLines => hiddenLineCount > 0;
  bool get hasMultipleSourceSections => sourceSectionCount > 1;

  Map<String, Object?> toPrivacySafeMap() {
    return {
      'receiptId': receiptId,
      'purpose': purpose.name,
      'status': status,
      'visibleLineCount': visibleLineCount,
      'hiddenLineCount': hiddenLineCount,
      'reviewLineCount': reviewLineCount,
      'totalSourceLineCount': totalSourceLineCount,
      'sourceSectionCount': sourceSectionCount,
      'needsManualReview': needsManualReview,
      'readyToShare': readyToShare,
      'recommendedNextAction': recommendedNextAction,
      'hasHiddenLines': hasHiddenLines,
      'hasMultipleSourceSections': hasMultipleSourceSections,
    };
  }
}

class ReceiptClientProofSourceSectionSummary {
  const ReceiptClientProofSourceSectionSummary({
    required this.sourceReceiptSectionLabel,
    required this.visibleLineCount,
    required this.hiddenLineCount,
    required this.reviewLineCount,
    required this.totalLineCount,
  });

  final String sourceReceiptSectionLabel;
  final int visibleLineCount;
  final int hiddenLineCount;
  final int reviewLineCount;
  final int totalLineCount;

  bool get needsManualReview => reviewLineCount > 0;
  bool get hasHiddenLines => hiddenLineCount > 0;
  bool get hasVisibleLines => visibleLineCount > 0;

  Map<String, Object?> toPrivacySafeMap() {
    return {
      'sourceReceiptSectionLabel': sourceReceiptSectionLabel,
      'visibleLineCount': visibleLineCount,
      'hiddenLineCount': hiddenLineCount,
      'reviewLineCount': reviewLineCount,
      'totalLineCount': totalLineCount,
      'needsManualReview': needsManualReview,
      'hasHiddenLines': hasHiddenLines,
      'hasVisibleLines': hasVisibleLines,
    };
  }
}

class ReceiptClientProofImageReviewPlan {
  const ReceiptClientProofImageReviewPlan({
    required this.receiptId,
    required this.purpose,
    required this.sections,
    required this.unassignedLineCount,
    required this.unassignedHiddenLineCount,
    required this.unassignedReviewLineCount,
  });

  factory ReceiptClientProofImageReviewPlan.fromRedactionPlan(
    ReceiptClientProofRedactionPlan plan,
  ) {
    final sectionLines = <String, List<ReceiptClientProofRedactionLine>>{};
    var unassignedLineCount = 0;
    var unassignedHiddenLineCount = 0;
    var unassignedReviewLineCount = 0;
    for (final line in plan.lines) {
      final sectionLabel = line.sourceReceiptSectionLabel.trim();
      if (sectionLabel.isEmpty) {
        unassignedLineCount += 1;
        if (line.isHidden) unassignedHiddenLineCount += 1;
        if (line.needsReview) unassignedReviewLineCount += 1;
        continue;
      }
      sectionLines.putIfAbsent(sectionLabel, () => []).add(line);
    }
    final sections =
        [
          for (final entry in sectionLines.entries)
            ReceiptClientProofSourceSectionSummary(
              sourceReceiptSectionLabel: entry.key,
              visibleLineCount: entry.value
                  .where((line) => line.isVisible)
                  .length,
              hiddenLineCount: entry.value
                  .where((line) => line.isHidden)
                  .length,
              reviewLineCount: entry.value
                  .where((line) => line.needsReview)
                  .length,
              totalLineCount: entry.value.length,
            ),
        ]..sort(
          (left, right) => left.sourceReceiptSectionLabel.compareTo(
            right.sourceReceiptSectionLabel,
          ),
        );
    return ReceiptClientProofImageReviewPlan(
      receiptId: plan.receiptId,
      purpose: plan.purpose,
      sections: List.unmodifiable(sections),
      unassignedLineCount: unassignedLineCount,
      unassignedHiddenLineCount: unassignedHiddenLineCount,
      unassignedReviewLineCount: unassignedReviewLineCount,
    );
  }

  final String receiptId;
  final ReceiptLineSelectionPurpose purpose;
  final List<ReceiptClientProofSourceSectionSummary> sections;
  final int unassignedLineCount;
  final int unassignedHiddenLineCount;
  final int unassignedReviewLineCount;

  int get sectionCount => sections.length;
  int get hiddenSectionCount =>
      sections.where((section) => section.hasHiddenLines).length;
  int get reviewSectionCount =>
      sections.where((section) => section.needsManualReview).length;
  int get visibleSectionCount =>
      sections.where((section) => section.hasVisibleLines).length;
  bool get needsManualImageReview =>
      reviewSectionCount > 0 || unassignedReviewLineCount > 0;
  bool get needsRedactionPreview =>
      hiddenSectionCount > 0 || unassignedHiddenLineCount > 0;

  Map<String, Object?> toPrivacySafeMap() {
    return {
      'receiptId': receiptId,
      'purpose': purpose.name,
      'sectionCount': sectionCount,
      'visibleSectionCount': visibleSectionCount,
      'hiddenSectionCount': hiddenSectionCount,
      'reviewSectionCount': reviewSectionCount,
      'unassignedLineCount': unassignedLineCount,
      'unassignedHiddenLineCount': unassignedHiddenLineCount,
      'unassignedReviewLineCount': unassignedReviewLineCount,
      'needsManualImageReview': needsManualImageReview,
      'needsRedactionPreview': needsRedactionPreview,
      'sections': sections
          .map((section) => section.toPrivacySafeMap())
          .toList(growable: false),
    };
  }
}
