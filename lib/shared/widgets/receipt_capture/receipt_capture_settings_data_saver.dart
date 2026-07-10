part of 'receipt_capture_settings_store.dart';

extension ReceiptCaptureSettingsDataSaver on ReceiptCaptureSettingsController {
  ReceiptDataSaverLevel get defaultDataSaverLevel {
    final saved = _box.get(_Keys.defaultDataSaverLevel) as String?;
    if (saved == null || saved.isEmpty) {
      return _deviceCapability.recommendedDataSaverLevel;
    }
    return ReceiptDataSaverLevel.fromName(saved);
  }

  ReceiptProofTargetSizePolicy get defaultDataSaverProofTargetSizePolicy {
    return defaultDataSaverLevel.proofTargetSizePolicy;
  }

  ReceiptCaptureStorageEstimate defaultDataSaverStorageEstimate({
    required CloudBackupQuotaCheck cloudQuota,
    int photoCount = 1,
    int averageOriginalPhotoBytes = 24 * 1024 * 1024,
  }) {
    return ReceiptCaptureStorageEstimate(
      dataSaverLevel: defaultDataSaverLevel,
      cloudQuota: cloudQuota,
      photoCount: photoCount,
      averageOriginalPhotoBytes: averageOriginalPhotoBytes,
    );
  }

  String get defaultDataSaverProofTargetSummary {
    final policy = defaultDataSaverProofTargetSizePolicy;
    final target = policy.keepsOriginalLocalOnly
        ? 'local original only'
        : '${policy.targetLabel} target, ${policy.rangeLabel} range';
    final backup = policy.cloudBackupDefaultAllowed
        ? 'safe for normal backup proof copies'
        : 'not used for cloud backup by default';
    final review = policy.requiresReadabilityReview
        ? 'Review readability before relying on this smaller proof.'
        : 'No extra readability review is required beyond normal receipt review.';
    return '${policy.level.label}: $target; $backup. ${policy.userFacingSummary} $review';
  }

  ReceiptDeviceStorageClass get defaultDataSaverStorageClass {
    return storageClassForDataSaverLevel(defaultDataSaverLevel);
  }

  ReceiptCloudAssistPlan get defaultDataSaverCloudAssistPlan {
    return _deviceCapability.cloudAssistPlanFor(
      dataSaverLevel: defaultDataSaverLevel,
    );
  }

  ReceiptBrainDeploymentRecommendation get defaultDataSaverReceiptBrain {
    final plan = defaultDataSaverCloudAssistPlan;
    return _deviceCapability.receiptBrainRecommendationFor(
      defaultDataSaverStorageClass,
      cloudAssistPlan: plan,
    );
  }

  ReceiptBrainFootprintSummary get defaultDataSaverFootprintSummary {
    final plan = defaultDataSaverCloudAssistPlan;
    return _deviceCapability.receiptBrainFootprintSummaryFor(
      defaultDataSaverStorageClass,
      cloudAssistPlan: plan,
    );
  }

  ReceiptLocalOnlyAcceptanceGate get defaultDataSaverLocalOnlyAcceptanceGate {
    return defaultDataSaverFootprintSummary.localOnlyAcceptanceGate;
  }

  ReceiptInstallFootprintStrategy get defaultDataSaverInstallFootprintStrategy {
    return defaultDataSaverFootprintSummary.installFootprintStrategy;
  }

  String get defaultDataSaverLocalOnlyReadinessSummary {
    final gate = defaultDataSaverLocalOnlyAcceptanceGate;
    final status = switch (gate.statusCode) {
      'ready_local_first_optional_packs_deferred' =>
        'Ready: receipt capture, proof save, and basic local review work now. Bigger offline packs wait until the user chooses them.',
      'ready_local_first_base_flow' =>
        'Ready: receipt capture, proof save, and basic local review work from the base app.',
      'review_base_receipt_size_before_adding_weight' =>
        'Review needed: the base receipt flow is getting heavy. Keep optional OCR/parser packs separate before adding more receipt weight.',
      'blocked_capture_not_available_in_base' =>
        'Blocked: receipt capture must work before optional packs or cloud assist.',
      'blocked_proof_save_not_available_in_base' =>
        'Blocked: receipt proof saving must work before optional packs or cloud assist.',
      'blocked_basic_local_review_not_available' =>
        'Blocked: basic local receipt review must work before optional packs or cloud assist.',
      'blocked_heavy_pack_required_before_capture' =>
        'Blocked: a heavy offline pack cannot be required before the user can capture and save a receipt.',
      'blocked_cloud_required_before_capture' =>
        'Blocked: cloud assist cannot be required before the user can capture and save a receipt.',
      _ => gate.userFacingSummary,
    };
    return '$status ${gate.userFacingSummary}';
  }

  bool get defaultDataSaverCanRunBaseReceiptFlowLocallyNow {
    return defaultDataSaverLocalOnlyAcceptanceGate.baseFlowCanRunLocallyNow;
  }

  bool get defaultDataSaverBlocksLowStorageReceiptUsers {
    return defaultDataSaverLocalOnlyAcceptanceGate.blocksLowStorageUsers;
  }

  String get defaultDataSaverFirstInstallBoundarySummary {
    return defaultDataSaverFootprintSummary
        .userFacingFirstInstallReceiptBoundarySummary;
  }

  String get defaultDataSaverInstallFootprintSummary {
    final strategy = defaultDataSaverInstallFootprintStrategy;
    final intro =
        'First install: ${strategy.requiredBaseLabel} for receipt camera, proof save, manual entry, and basic local reading.';
    final optional = strategy.optionalOfflineBytes > 0
        ? 'Extra offline receipt help is optional (${strategy.optionalOfflineLabel}) and downloads only after you choose it.'
        : 'No extra offline receipt download is required for this setup.';
    final lowStorage = strategy.baseDownloadStillUsefulOnTinyPhones
        ? 'Low-storage phones can still capture and review basic receipts.'
        : 'This setup is too heavy for low-storage phones until receipt packs are split out.';
    return '$intro $optional $lowStorage';
  }

  ReceiptParserPackRoutingPlan get defaultDataSaverParserPackRoutingPlan {
    return defaultDataSaverCloudAssistPlan.parserPackRoutingPlan;
  }

  ReceiptParserPackInstallChoice get defaultDataSaverParserPackInstallChoice {
    return defaultDataSaverCloudAssistPlan.parserPackInstallChoice;
  }

  bool get defaultDataSaverShouldOfferOptionalLocalParserPacks {
    final footprint = defaultDataSaverFootprintSummary;
    return footprint.requiresExplicitDownload &&
        !footprint.shouldDeferOptionalLocalPacks;
  }

  String get defaultDataSaverReceiptCapabilitySummary {
    final brain = defaultDataSaverReceiptBrain;
    final footprint = defaultDataSaverFootprintSummary;
    final base =
        'Maintainiac can capture receipts, save proof, and read basic receipt details without any extra download.';
    final optional = footprint.optionalLocalPackBytes > 0
        ? 'Stronger offline receipt help is optional (${footprint.optionalLocalPackSizeLabel}) and downloads only after the user chooses it.'
        : 'No extra offline receipt download is needed for this setup.';
    final storage = switch (defaultDataSaverStorageClass) {
      ReceiptDeviceStorageClass.critical =>
        'When storage is very tight, keep the receipt camera and fuel/simple receipts working first.',
      ReceiptDeviceStorageClass.low =>
        'Low-storage phones keep fuel receipts and basic OCR available without forcing large packs.',
      ReceiptDeviceStorageClass.comfortable =>
        'This phone can be offered stronger receipt help, but the first install stays separate.',
      ReceiptDeviceStorageClass.roomy =>
        'Full offline receipt help can be offered, but it is still a choice.',
      ReceiptDeviceStorageClass.unknown =>
        'Check storage before offering large receipt downloads.',
    };
    final assist = brain.assistFallbackAllowed
        ? 'Assisted reading can be offered later only if the user chooses it and internet is available.'
        : 'This setup stays local by default.';
    final proof =
        'Saved proof copies can be smaller for phone space and backup, but receipt reading still uses the clearest source first. $defaultDataSaverProofTargetSummary';
    return '$base $optional $storage $assist $proof $defaultDataSaverInstallFootprintSummary';
  }
}
