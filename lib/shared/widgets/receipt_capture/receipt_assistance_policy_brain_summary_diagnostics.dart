part of 'receipt_assistance_policy.dart';

extension ReceiptBrainFootprintSummaryDiagnostics
    on ReceiptBrainFootprintSummary {
  bool get optionalParserPacksRequireUserChoice {
    return optionalLocalPackBytes == 0 || requiresExplicitDownload;
  }

  bool get baseInstallStaysUnderRequiredBudget {
    return baseReceiptBudgetBytes <=
        ReceiptBrainFootprintSummary.maxRequiredBaseReceiptBudgetBytes;
  }

  bool get baseInstallNeedsSizeReview {
    return baseReceiptBudgetBytes >
        ReceiptBrainFootprintSummary.reviewRequiredBaseReceiptBudgetBytes;
  }

  bool get baseInstallBlocksLowStorageUsers {
    return baseReceiptBudgetBytes >
            ReceiptBrainFootprintSummary.maxRequiredBaseReceiptBudgetBytes ||
        includedLocalPackBytes > 0 ||
        !baseCaptureWorksWithoutOptionalPacks ||
        !optionalPacksDetachedFromBaseInstall;
  }

  bool get fullOfflineReceiptBrainExceedsRequiredBaseGuardrail {
    return fullOfflineReceiptBudgetBytes >
        ReceiptBrainFootprintSummary.maxRequiredBaseReceiptBudgetBytes;
  }

  bool get fullOfflineReceiptBrainMustStayOptional {
    return optionalLocalPackBytes > 0 ||
        cloudFallbackPackCodes.isNotEmpty ||
        includedLocalPackBytes > 0 ||
        fullOfflineReceiptBrainExceedsRequiredBaseGuardrail ||
        !baseInstallCanShipWithoutFullOfflineReceiptBrain;
  }

  String get lowStorageDownloadRiskCode {
    if (baseInstallBlocksLowStorageUsers) {
      return 'base_install_blocks_low_storage_users';
    }
    if (storageClass == ReceiptDeviceStorageClass.critical ||
        storageClass == ReceiptDeviceStorageClass.low) {
      if (fullOfflineReceiptBrainExceedsRequiredBaseGuardrail) {
        return 'full_offline_too_large_for_low_storage';
      }
      if (optionalLocalPackBytes > 0 || cloudFallbackPackCodes.isNotEmpty) {
        return 'base_safe_optional_brain_deferred_for_low_storage';
      }
      return 'base_only_safe_for_low_storage';
    }
    if (fullOfflineReceiptBrainExceedsRequiredBaseGuardrail) {
      return 'full_offline_large_optional_only';
    }
    if (requiresExplicitDownload) {
      return 'optional_download_user_choice_required';
    }
    return 'base_receipt_footprint_ready';
  }

  String get userFacingLowStorageDownloadWarning {
    final base =
        'Required receipt camera and basic reading: $baseReceiptBudgetLabel.';
    final full =
        'Full offline receipt intelligence: $fullOfflineReceiptBudgetLabel.';
    return switch (lowStorageDownloadRiskCode) {
      'base_install_blocks_low_storage_users' =>
        '$base This required download is too heavy for low-storage users. Move receipt OCR/parser weight into optional packs before release.',
      'full_offline_too_large_for_low_storage' =>
        '$base $full Keep the full offline receipt brain optional or cloud-assisted for low-storage phones.',
      'base_safe_optional_brain_deferred_for_low_storage' =>
        '$base Keep optional receipt packs deferred unless the user chooses them and has room.',
      'base_only_safe_for_low_storage' =>
        '$base This low-storage setup can use the base receipt flow without extra downloads.',
      'full_offline_large_optional_only' =>
        '$base $full Full offline receipt intelligence is large and must remain an explicit optional download.',
      'optional_download_user_choice_required' =>
        '$base Offline receipt add-ons require explicit user choice before download.',
      _ => '$base The receipt footprint is ready for the base app.',
    };
  }

  String get baseInstallSizeDecisionCode {
    if (!baseInstallStaysUnderRequiredBudget) {
      return 'block_base_over_100mb';
    }
    if (includedLocalPackBytes > 0) {
      return 'block_included_parser_pack_in_base';
    }
    if (!baseCaptureWorksWithoutOptionalPacks) {
      return 'block_base_requires_optional_pack';
    }
    if (!optionalPacksDetachedFromBaseInstall) {
      return 'block_optional_pack_attached_to_base';
    }
    if (baseInstallNeedsSizeReview) {
      return 'review_base_over_50mb';
    }
    return 'base_size_ready';
  }

  String get userFacingBaseSizeDecisionLabel {
    return switch (baseInstallSizeDecisionCode) {
      'block_base_over_100mb' =>
        'The required receipt camera and reader are too large for release. Move heavy OCR/parser work into optional packs.',
      'block_included_parser_pack_in_base' =>
        'Parser packs are inside the required base app and must be optional before release.',
      'block_base_requires_optional_pack' =>
        'Receipt capture must work before any optional receipt pack is installed.',
      'block_optional_pack_attached_to_base' =>
        'Optional receipt packs must be detached from the first install.',
      'review_base_over_50mb' =>
        'The required receipt camera and reader are above the 50 MB review point. Do not add more base receipt weight without approval.',
      _ =>
        'The required receipt camera and reader are within the lean base size target.',
    };
  }

  String get baseInstallBudgetTierCode {
    if (baseReceiptBudgetBytes <=
        ReceiptBrainFootprintSummary.leanBaseReceiptBudgetBytes) {
      return 'lean_base_under_40mb';
    }
    if (baseReceiptBudgetBytes <=
        ReceiptBrainFootprintSummary.reviewRequiredBaseReceiptBudgetBytes) {
      return 'base_40_to_50mb_watch';
    }
    if (baseInstallStaysUnderRequiredBudget) {
      return 'base_over_50mb_review_required';
    }
    return 'base_over_100mb_block_required_install';
  }

  String get baseInstallBudgetLabel {
    if (baseReceiptBudgetBytes <=
        ReceiptBrainFootprintSummary.leanBaseReceiptBudgetBytes) {
      return 'Lean required receipt base: $baseReceiptBudgetLabel.';
    }
    if (baseInstallStaysUnderRequiredBudget) {
      return 'Required receipt base is $baseReceiptBudgetLabel. Keep watching app size before adding more local receipt work.';
    }
    return 'Required receipt base is $baseReceiptBudgetLabel, which is over the 100 MB guardrail. Move heavy receipt work into optional packs before release.';
  }

  String get requiredBaseReleaseActionCode {
    if (!baseInstallStaysUnderRequiredBudget) {
      return 'move_heavy_receipt_work_to_optional_packs_before_release';
    }
    if (includedLocalPackBytes > 0) {
      return 'remove_included_parser_packs_from_required_base';
    }
    if (!baseCaptureWorksWithoutOptionalPacks) {
      return 'restore_base_capture_without_optional_packs';
    }
    if (!optionalPacksDetachedFromBaseInstall) {
      return 'detach_optional_receipt_packs_from_required_base';
    }
    if (shouldDeferOptionalLocalPacks) {
      return 'ship_lean_base_and_defer_optional_receipt_packs';
    }
    if (requiresExplicitDownload) {
      return 'ship_lean_base_offer_explicit_receipt_pack_download';
    }
    return 'ship_lean_base_receipt_capture';
  }

  String get installDistributionModeCode {
    if (!baseInstallStaysUnderRequiredBudget) {
      return 'required_base_blocked_until_optionalized';
    }
    return switch (storageClass) {
      ReceiptDeviceStorageClass.critical =>
        'base_app_only_optional_cloud_assist',
      ReceiptDeviceStorageClass.low =>
        optionalLocalPackBytes > 0
            ? 'base_app_small_optional_receipt_pack'
            : 'base_app_cloud_assist_or_later_download',
      ReceiptDeviceStorageClass.comfortable =>
        optionalLocalPackBytes > 0
            ? 'base_app_explicit_optional_receipt_packs'
            : 'base_app_local_reader_sufficient',
      ReceiptDeviceStorageClass.roomy =>
        optionalLocalPackBytes > 0
            ? 'base_app_full_offline_optional'
            : 'base_app_full_local_reader_sufficient',
      ReceiptDeviceStorageClass.unknown => 'base_app_until_storage_is_checked',
    };
  }

  String get userFacingRequiredBaseGuardrailSummary {
    final guardrail =
        'The required receipt camera stays under ${_formatReceiptBytes(ReceiptBrainFootprintSummary.maxRequiredBaseReceiptBudgetBytes)}.';
    final optional = optionalLocalPackBytes > 0
        ? 'The extra offline receipt brain is optional ($optionalLocalPackSizeLabel) and is not part of the first install.'
        : 'No extra offline receipt brain is required for this setup.';
    final action = switch (requiredBaseReleaseActionCode) {
      'move_heavy_receipt_work_to_optional_packs_before_release' =>
        'This cannot ship as a required download until heavy receipt work is moved out of the base app.',
      'remove_included_parser_packs_from_required_base' =>
        'Parser packs should be moved out of the required base app.',
      'restore_base_capture_without_optional_packs' =>
        'Receipt capture must work before any optional pack is installed.',
      'detach_optional_receipt_packs_from_required_base' =>
        'Optional receipt packs must be detached from the required install.',
      'ship_lean_base_and_defer_optional_receipt_packs' =>
        'Ship the lean base first and defer larger packs until the user has room.',
      'ship_lean_base_offer_explicit_receipt_pack_download' =>
        'Ship the lean base first and offer stronger packs only after the user chooses them.',
      _ => 'Ship the lean base receipt camera.',
    };
    return '$guardrail $optional $action';
  }

  String get userFacingBaseVersusFullOfflineSummary {
    final base =
        'First install needs the receipt camera, proof storage, data saver copies, manual entry, and basic local reading only ($baseReceiptBudgetLabel).';
    final full = optionalLocalPackBytes > 0
        ? 'Full offline receipt intelligence can add about $optionalLocalPackSizeLabel later.'
        : 'This setup does not need a separate full-offline receipt download right now.';
    final choice = baseInstallCanShipWithoutFullOfflineReceiptBrain
        ? 'Do not block receipt capture behind optional OCR/parser packs.'
        : 'Move heavy OCR/parser work out of the required base before release.';
    return '$base $full $choice';
  }

  String get userFacingInstallChoiceSummary {
    final base =
        'Base receipt capture and basic local reading stay around $baseReceiptBudgetLabel.';
    final optional = optionalLocalPackBytes > 0
        ? 'This setup may offer about $optionalLocalPackSizeLabel of optional offline receipt help.'
        : 'This setup should not offer extra offline receipt downloads right now.';
    final full =
        'The full offline receipt setup would be about $fullOfflineReceiptBudgetLabel.';
    final choice =
        'Only the base capture reader is required; stronger receipt intelligence is optional.';
    return switch (storageClass) {
      ReceiptDeviceStorageClass.critical =>
        '$base $optional $full $choice Keep the phone lean first.',
      ReceiptDeviceStorageClass.low =>
        '$base $optional $full $choice Larger packs should wait or use assist fallback.',
      ReceiptDeviceStorageClass.comfortable =>
        '$base $optional $full $choice Let the user choose before downloading more.',
      ReceiptDeviceStorageClass.roomy =>
        '$base $optional $full $choice Full offline can be offered, but it is still a choice.',
      ReceiptDeviceStorageClass.unknown =>
        '$base $optional $full $choice Wait for a storage check before offering larger packs.',
    };
  }
}
