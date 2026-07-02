part of 'receipt_assistance_policy.dart';

class ReceiptLocalOnlyAcceptanceGate {
  const ReceiptLocalOnlyAcceptanceGate({
    required this.canCaptureReceipt,
    required this.canSaveReceiptProof,
    required this.canOpenBasicLocalReview,
    required this.requiresHeavyOfflinePackBeforeCapture,
    required this.requiresCloudAssistBeforeCapture,
    required this.optionalPacksDeferredBeforeCapture,
    required this.statusCode,
    required this.actionCode,
    required this.evidenceCodes,
    required this.userFacingSummary,
  });

  factory ReceiptLocalOnlyAcceptanceGate.fromSummary(
    ReceiptBrainFootprintSummary summary,
  ) {
    final requiredPayloads = summary.requiredBasePayloadCodes;
    final canCapture =
        summary.baseCaptureWorksWithoutOptionalPacks &&
        requiredPayloads.contains('native_receipt_camera');
    final canSave =
        requiredPayloads.contains('receipt_proof_storage') &&
        requiredPayloads.contains('data_saver_proof_copies');
    final canReview =
        summary.baseLocalReceiptReadingAvailable &&
        requiredPayloads.contains('basic_local_receipt_reader') &&
        requiredPayloads.contains('manual_receipt_entry');
    final heavyRequired =
        summary.includedLocalPackBytes > 0 ||
        !summary.optionalPacksDetachedFromBaseInstall ||
        !summary.baseInstallCanShipWithoutFullOfflineReceiptBrain;
    final cloudRequired =
        !canReview && summary.cloudFallbackPackCodes.isNotEmpty;
    final optionalDeferred =
        summary.shouldDeferOptionalLocalPacks ||
        summary.optionalLocalPackBytes == 0 ||
        summary.requiresExplicitDownload;
    final evidence = <String>[
      if (canCapture) 'capture_available_in_base',
      if (canSave) 'proof_save_available_in_base',
      if (canReview) 'basic_local_review_available_in_base',
      if (optionalDeferred) 'optional_packs_not_required_before_capture',
      if (summary.cloudFallbackPackCodes.isNotEmpty)
        'cloud_assist_optional_after_local_flow',
      if (summary.fullOfflineReceiptBrainMustStayOptional)
        'full_offline_brain_optional',
    ];
    final status = _localOnlyAcceptanceStatusCode(
      canCapture: canCapture,
      canSave: canSave,
      canReview: canReview,
      heavyRequired: heavyRequired,
      cloudRequired: cloudRequired,
      summary: summary,
    );
    final action = _localOnlyAcceptanceActionCode(status);

    return ReceiptLocalOnlyAcceptanceGate(
      canCaptureReceipt: canCapture,
      canSaveReceiptProof: canSave,
      canOpenBasicLocalReview: canReview,
      requiresHeavyOfflinePackBeforeCapture: heavyRequired,
      requiresCloudAssistBeforeCapture: cloudRequired,
      optionalPacksDeferredBeforeCapture: optionalDeferred,
      statusCode: status,
      actionCode: action,
      evidenceCodes: List.unmodifiable(evidence),
      userFacingSummary: _localOnlyAcceptanceSummary(
        status: status,
        action: action,
        summary: summary,
      ),
    );
  }

  final bool canCaptureReceipt;
  final bool canSaveReceiptProof;
  final bool canOpenBasicLocalReview;
  final bool requiresHeavyOfflinePackBeforeCapture;
  final bool requiresCloudAssistBeforeCapture;
  final bool optionalPacksDeferredBeforeCapture;
  final String statusCode;
  final String actionCode;
  final List<String> evidenceCodes;
  final String userFacingSummary;

  bool get baseFlowCanRunLocallyNow {
    return canCaptureReceipt &&
        canSaveReceiptProof &&
        canOpenBasicLocalReview &&
        !requiresHeavyOfflinePackBeforeCapture &&
        !requiresCloudAssistBeforeCapture;
  }

  bool get blocksLowStorageUsers {
    return !baseFlowCanRunLocallyNow;
  }

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'receiptLocalOnlyAcceptanceStatusCode': statusCode,
      'receiptLocalOnlyAcceptanceActionCode': actionCode,
      'receiptLocalOnlyBaseFlowCanRunNow': baseFlowCanRunLocallyNow,
      'receiptLocalOnlyCanCaptureReceipt': canCaptureReceipt,
      'receiptLocalOnlyCanSaveReceiptProof': canSaveReceiptProof,
      'receiptLocalOnlyCanOpenBasicReview': canOpenBasicLocalReview,
      'receiptLocalOnlyRequiresHeavyPackBeforeCapture':
          requiresHeavyOfflinePackBeforeCapture,
      'receiptLocalOnlyRequiresCloudBeforeCapture':
          requiresCloudAssistBeforeCapture,
      'receiptLocalOnlyOptionalPacksDeferredBeforeCapture':
          optionalPacksDeferredBeforeCapture,
      'receiptLocalOnlyBlocksLowStorageUsers': blocksLowStorageUsers,
      'receiptLocalOnlyEvidenceCodes': evidenceCodes,
      'receiptLocalOnlyUserFacingSummary': userFacingSummary,
    };
  }
}

String _localOnlyAcceptanceStatusCode({
  required bool canCapture,
  required bool canSave,
  required bool canReview,
  required bool heavyRequired,
  required bool cloudRequired,
  required ReceiptBrainFootprintSummary summary,
}) {
  if (!canCapture) return 'blocked_capture_not_available_in_base';
  if (!canSave) return 'blocked_proof_save_not_available_in_base';
  if (!canReview) return 'blocked_basic_local_review_not_available';
  if (heavyRequired) return 'blocked_heavy_pack_required_before_capture';
  if (cloudRequired) return 'blocked_cloud_required_before_capture';
  if (summary.baseInstallNeedsSizeReview) {
    return 'review_base_receipt_size_before_adding_weight';
  }
  if (summary.shouldDeferOptionalLocalPacks ||
      summary.optionalLocalPackBytes == 0 ||
      summary.fullOfflineReceiptBrainMustStayOptional) {
    return 'ready_local_first_optional_packs_deferred';
  }
  return 'ready_local_first_base_flow';
}

String _localOnlyAcceptanceActionCode(String statusCode) {
  return switch (statusCode) {
    'blocked_capture_not_available_in_base' =>
      'restore_native_capture_in_required_base',
    'blocked_proof_save_not_available_in_base' =>
      'restore_proof_save_and_data_saver_in_required_base',
    'blocked_basic_local_review_not_available' =>
      'restore_basic_local_reader_before_optional_packs',
    'blocked_heavy_pack_required_before_capture' =>
      'move_heavy_receipt_pack_out_of_required_capture_flow',
    'blocked_cloud_required_before_capture' =>
      'restore_local_review_before_cloud_assist',
    'review_base_receipt_size_before_adding_weight' =>
      'review_base_size_before_adding_receipt_weight',
    'ready_local_first_optional_packs_deferred' =>
      'ship_base_capture_save_review_before_optional_packs',
    _ => 'continue_local_first_receipt_flow',
  };
}

String _localOnlyAcceptanceSummary({
  required String status,
  required String action,
  required ReceiptBrainFootprintSummary summary,
}) {
  final base =
      'The base receipt flow can capture, save proof, and open basic local review before any optional receipt pack.';
  final optional = summary.optionalLocalPackBytes > 0
      ? 'Stronger offline packs are optional (${summary.optionalLocalPackSizeLabel}) and must wait for user choice.'
      : 'No stronger offline pack is required before receipt capture.';
  final cloud = summary.cloudFallbackPackCodes.isEmpty
      ? 'Cloud assist is not required for this base flow.'
      : 'Cloud assist remains optional and must not block local capture.';
  return switch (status) {
    'ready_local_first_optional_packs_deferred' ||
    'ready_local_first_base_flow' => '$base $optional $cloud',
    'review_base_receipt_size_before_adding_weight' =>
      '$base $optional $cloud Review the base receipt size before adding more local weight.',
    _ =>
      'The local receipt flow is blocked. Action required: $action. Restore capture, proof save, and basic local review before optional packs or cloud assist.',
  };
}
