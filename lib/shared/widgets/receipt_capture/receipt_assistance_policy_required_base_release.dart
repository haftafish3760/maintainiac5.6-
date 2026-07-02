part of 'receipt_assistance_policy.dart';

class ReceiptRequiredBaseFootprintReleaseCheck {
  const ReceiptRequiredBaseFootprintReleaseCheck({
    required this.requiredBaseBytes,
    required this.fullOfflineBytes,
    required this.requiredBaseBudgetBytes,
    required this.reviewBudgetBytes,
    required this.optionalBytes,
    required this.requiredPayloadCodes,
    required this.optionalPayloadCodes,
    required this.blockingReasonCodes,
    required this.reviewReasonCodes,
    required this.releaseActionCode,
    required this.userFacingSummary,
  });

  factory ReceiptRequiredBaseFootprintReleaseCheck.fromSummary(
    ReceiptBrainFootprintSummary summary,
  ) {
    final blocking = <String>[
      if (!summary.baseInstallStaysUnderRequiredBudget)
        'required_base_over_100mb',
      if (summary.includedLocalPackBytes > 0) 'parser_pack_in_required_base',
      if (!summary.baseCaptureWorksWithoutOptionalPacks)
        'capture_requires_optional_pack',
      if (!summary.optionalPacksDetachedFromBaseInstall)
        'optional_pack_attached_to_required_base',
      if (!summary.baseInstallCanShipWithoutFullOfflineReceiptBrain)
        'full_offline_brain_required_for_capture',
    ];
    final review = <String>[
      if (summary.baseInstallNeedsSizeReview &&
          summary.baseInstallStaysUnderRequiredBudget)
        'required_base_over_50mb_review',
      if (summary.fullOfflineReceiptBrainExceedsRequiredBaseGuardrail)
        'full_offline_brain_over_100mb_optional_only',
      if (summary.optionalLocalPackBytes > 0 &&
          !summary.requiresExplicitDownload)
        'optional_pack_missing_explicit_download',
      if (summary.optionalLocalPackBytes > 0 &&
          !summary.fullOfflineReceiptBrainMustStayOptional)
        'optional_pack_must_remain_optional',
    ];
    final status = blocking.isNotEmpty
        ? 'blocked'
        : review.isNotEmpty
        ? 'review'
        : 'ready';
    final action = blocking.isNotEmpty
        ? 'fix_required_receipt_base_before_release'
        : review.isNotEmpty
        ? 'review_receipt_base_before_adding_weight'
        : 'ship_required_receipt_base';
    final summaryLabel = switch (status) {
      'blocked' =>
        'Required receipt capture cannot ship until heavy OCR/parser work is moved out of the base install.',
      'review' =>
        'Required receipt capture can stay lean only if full offline receipt intelligence remains optional.',
      _ =>
        'Required receipt capture is lean enough to ship without optional receipt intelligence.',
    };

    return ReceiptRequiredBaseFootprintReleaseCheck(
      requiredBaseBytes: summary.baseReceiptBudgetBytes,
      fullOfflineBytes: summary.fullOfflineReceiptBudgetBytes,
      requiredBaseBudgetBytes:
          ReceiptBrainFootprintSummary.maxRequiredBaseReceiptBudgetBytes,
      reviewBudgetBytes:
          ReceiptBrainFootprintSummary.reviewRequiredBaseReceiptBudgetBytes,
      optionalBytes: summary.optionalLocalPackBytes,
      requiredPayloadCodes: summary.requiredBasePayloadCodes,
      optionalPayloadCodes: summary.optionalPayloadCodes,
      blockingReasonCodes: List.unmodifiable(blocking),
      reviewReasonCodes: List.unmodifiable(review),
      releaseActionCode: action,
      userFacingSummary: summaryLabel,
    );
  }

  final int requiredBaseBytes;
  final int fullOfflineBytes;
  final int requiredBaseBudgetBytes;
  final int reviewBudgetBytes;
  final int optionalBytes;
  final List<String> requiredPayloadCodes;
  final List<String> optionalPayloadCodes;
  final List<String> blockingReasonCodes;
  final List<String> reviewReasonCodes;
  final String releaseActionCode;
  final String userFacingSummary;

  bool get requiredBaseCanShip => blockingReasonCodes.isEmpty;
  bool get requiresReview => reviewReasonCodes.isNotEmpty;
  bool get fullOfflineBrainIsOptional =>
      optionalPayloadCodes.isNotEmpty || fullOfflineBytes > requiredBaseBytes;
  String get statusCode {
    if (!requiredBaseCanShip) return 'blocked';
    if (requiresReview) return 'review';
    return 'ready';
  }

  String get requiredBaseLabel => _formatReceiptBytes(requiredBaseBytes);
  String get optionalLabel => _formatReceiptBytes(optionalBytes);
  String get fullOfflineLabel => _formatReceiptBytes(fullOfflineBytes);

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'receiptRequiredBaseFootprintStatusCode': statusCode,
      'receiptRequiredBaseFootprintCanShip': requiredBaseCanShip,
      'receiptRequiredBaseFootprintRequiresReview': requiresReview,
      'receiptRequiredBaseFootprintFullOfflineOptional':
          fullOfflineBrainIsOptional,
      'receiptRequiredBaseFootprintBlockingReasonCodes': blockingReasonCodes,
      'receiptRequiredBaseFootprintReviewReasonCodes': reviewReasonCodes,
      'receiptRequiredBaseFootprintReleaseActionCode': releaseActionCode,
      'receiptRequiredBaseFootprintRequiredBytes': requiredBaseBytes,
      'receiptRequiredBaseFootprintOptionalBytes': optionalBytes,
      'receiptRequiredBaseFootprintFullOfflineBytes': fullOfflineBytes,
      'receiptRequiredBaseFootprintRequiredPayloadCodes': requiredPayloadCodes,
      'receiptRequiredBaseFootprintOptionalPayloadCodes': optionalPayloadCodes,
      'receiptRequiredBaseFootprintSummary': userFacingSummary,
    };
  }
}
