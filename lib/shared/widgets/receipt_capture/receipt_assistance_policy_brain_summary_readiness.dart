part of 'receipt_assistance_policy.dart';

extension ReceiptBrainFootprintSummaryReadiness
    on ReceiptBrainFootprintSummary {
  String get baseReceiptBudgetLabel =>
      _formatReceiptBytes(baseReceiptBudgetBytes);

  String get optionalLocalPackSizeLabel =>
      _formatReceiptBytes(optionalLocalPackBytes);

  String get fullOfflineReceiptBudgetLabel =>
      _formatReceiptBytes(fullOfflineReceiptBudgetBytes);

  bool get baseInstallKeepsReceiptBrainLean {
    return baseCaptureWorksWithoutOptionalPacks &&
        optionalPacksDetachedFromBaseInstall &&
        includedLocalPackBytes == 0 &&
        baseInstallStaysUnderRequiredBudget;
  }

  List<String> get requiredBasePayloadCodes {
    return const [
      'native_receipt_camera',
      'receipt_proof_storage',
      'basic_local_receipt_reader',
      'manual_receipt_entry',
      'data_saver_proof_copies',
    ];
  }

  List<String> get optionalPayloadCodes {
    return List.unmodifiable([
      ...optionalLocalPackCodes,
      ...cloudFallbackPackCodes,
    ]);
  }

  bool get baseInstallCanShipWithoutFullOfflineReceiptBrain {
    return baseCaptureWorksWithoutOptionalPacks &&
        optionalPacksDetachedFromBaseInstall &&
        includedLocalPackBytes == 0 &&
        fullOfflineReceiptBudgetBytes >= baseReceiptBudgetBytes;
  }

  bool get firstInstallExcludesOptionalReceiptBrain {
    return includedLocalPackBytes == 0 &&
        optionalPacksDetachedFromBaseInstall &&
        optionalPayloadCodes.isNotEmpty;
  }

  bool get firstInstallRequiresOnlyBaseReceiptCapabilities {
    return baseCaptureWorksWithoutOptionalPacks &&
        baseLocalReceiptReadingAvailable &&
        includedLocalPackBytes == 0 &&
        optionalPacksDetachedFromBaseInstall;
  }

  bool get firstInstallCanRunOnLowStoragePhones {
    return firstInstallRequiresOnlyBaseReceiptCapabilities &&
        baseInstallStaysUnderRequiredBudget &&
        !baseInstallBlocksLowStorageUsers;
  }

  String get firstInstallReceiptBoundaryCode {
    if (!baseCaptureWorksWithoutOptionalPacks) {
      return 'blocked_capture_depends_on_deferred_pack';
    }
    if (!baseLocalReceiptReadingAvailable) {
      return 'blocked_base_reader_missing';
    }
    if (includedLocalPackBytes > 0) {
      return 'blocked_heavy_pack_in_first_install';
    }
    if (!optionalPacksDetachedFromBaseInstall) {
      return 'blocked_deferred_pack_attached_to_first_install';
    }
    if (!baseInstallStaysUnderRequiredBudget) {
      return 'blocked_first_install_over_100mb';
    }
    if (baseInstallNeedsSizeReview) {
      return 'review_first_install_over_50mb';
    }
    if (optionalLocalPackBytes > 0) {
      return 'ready_base_first_optional_local_pack_later';
    }
    if (cloudFallbackPackCodes.isNotEmpty) {
      return 'ready_base_first_cloud_assist_optional_later';
    }
    return 'ready_base_first_no_extra_receipt_brain';
  }

  String get firstInstallReceiptBoundaryActionCode {
    return switch (firstInstallReceiptBoundaryCode) {
      'blocked_capture_depends_on_deferred_pack' =>
        'restore_capture_before_receipt_pack_download',
      'blocked_base_reader_missing' => 'restore_basic_local_receipt_reader',
      'blocked_heavy_pack_in_first_install' =>
        'move_heavy_ocr_parser_pack_to_optional_download',
      'blocked_deferred_pack_attached_to_first_install' =>
        'detach_deferred_receipt_pack_from_first_install',
      'blocked_first_install_over_100mb' =>
        'reduce_required_receipt_install_before_release',
      'review_first_install_over_50mb' =>
        'review_required_receipt_weight_before_adding_features',
      'ready_base_first_optional_local_pack_later' =>
        'ship_base_then_offer_optional_local_pack',
      'ready_base_first_cloud_assist_optional_later' =>
        'ship_base_then_offer_optional_cloud_assist',
      _ => 'ship_base_receipt_flow',
    };
  }

  String get userFacingFirstInstallReceiptBoundarySummary {
    final required =
        'Required receipt install: $baseReceiptBudgetLabel for camera, proof save, manual entry, and basic local reading.';
    final optional = optionalLocalPackBytes > 0
        ? 'Extra offline receipt intelligence is a later choice ($optionalLocalPackSizeLabel).'
        : 'No extra offline receipt pack is required for this setup.';
    final cloud = cloudFallbackPackCodes.isNotEmpty
        ? 'Cloud assist is optional and cannot be required to capture or save a receipt.'
        : 'No cloud assist is required for this setup.';
    final action = switch (firstInstallReceiptBoundaryCode) {
      'blocked_capture_depends_on_deferred_pack' =>
        'Fix capture so it works before any download.',
      'blocked_base_reader_missing' =>
        'Restore the basic local reader before adding stronger receipt brains.',
      'blocked_heavy_pack_in_first_install' =>
        'Move heavy OCR/parser weight out of the first install.',
      'blocked_deferred_pack_attached_to_first_install' =>
        'Detach optional packs from the first install.',
      'blocked_first_install_over_100mb' =>
        'Reduce the required receipt install before release.',
      'review_first_install_over_50mb' =>
        'Review the required receipt weight before adding more camera/OCR code.',
      _ => 'Low-storage users can start with the base receipt flow.',
    };
    return '$required $optional $cloud $action';
  }

  bool get baseLocalReceiptReadingAvailable {
    return baseCaptureWorksWithoutOptionalPacks &&
        localOcrMode.isNotEmpty &&
        requiredBasePayloadCodes.contains('native_receipt_camera') &&
        requiredBasePayloadCodes.contains('basic_local_receipt_reader') &&
        requiredBasePayloadCodes.contains('manual_receipt_entry');
  }

  bool get baseWorksWithoutCloudAssist {
    return baseLocalReceiptReadingAvailable &&
        parserDepth == ReceiptParserDepth.proofTotalsOnly;
  }

  String get localFirstReadinessCode {
    if (!baseCaptureWorksWithoutOptionalPacks) {
      return 'blocked_capture_requires_optional_pack';
    }
    if (!baseLocalReceiptReadingAvailable) {
      return 'blocked_base_local_reader_missing';
    }
    if (!optionalPacksDetachedFromBaseInstall) {
      return 'blocked_optional_pack_attached_to_base';
    }
    if (includedLocalPackBytes > 0) {
      return 'blocked_parser_pack_in_required_base';
    }
    if (storageClass == ReceiptDeviceStorageClass.critical ||
        storageClass == ReceiptDeviceStorageClass.low ||
        shouldDeferOptionalLocalPacks) {
      return 'lean_local_ready_optional_packs_deferred';
    }
    if (optionalLocalPackBytes > 0) {
      return 'local_ready_optional_offline_pack_available';
    }
    return 'local_ready_base_only';
  }

  String get localFirstReadinessActionCode {
    return switch (localFirstReadinessCode) {
      'blocked_capture_requires_optional_pack' =>
        'restore_capture_without_optional_packs',
      'blocked_base_local_reader_missing' => 'restore_basic_local_reader',
      'blocked_optional_pack_attached_to_base' =>
        'detach_optional_packs_from_base',
      'blocked_parser_pack_in_required_base' =>
        'move_parser_pack_out_of_required_base',
      'lean_local_ready_optional_packs_deferred' =>
        'keep_capture_and_basic_reader_available',
      'local_ready_optional_offline_pack_available' =>
        'offer_optional_pack_after_user_choice',
      _ => 'continue_with_base_local_receipt_flow',
    };
  }

  String get userFacingLocalFirstReadinessSummary {
    final base =
        'Receipt capture, proof storage, manual entry, and basic local reading work from the base app.';
    final optional = optionalLocalPackBytes > 0
        ? 'Stronger offline packs are optional and add about $optionalLocalPackSizeLabel only after the user chooses them.'
        : 'No offline parser pack is required for this storage setup.';
    final fallback = cloudFallbackPackCodes.isEmpty
        ? 'Cloud help is not part of this setup.'
        : 'Assist fallback is optional, requires internet, and must not block local capture.';
    return switch (localFirstReadinessCode) {
      'lean_local_ready_optional_packs_deferred' =>
        '$base $optional $fallback Keep low-storage phones on the lean local receipt flow first.',
      'local_ready_optional_offline_pack_available' =>
        '$base $optional $fallback Offer the pack only after storage and user choice.',
      'local_ready_base_only' => '$base $optional $fallback',
      _ =>
        'Local receipt capture is not safe yet. Restore base capture and basic local reading before optional receipt packs.',
    };
  }
}
