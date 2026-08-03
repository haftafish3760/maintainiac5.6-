part of 'expense_receipt_entry_screen.dart';

extension _ReceiptOcrReviewPhotoHelpers on _ReceiptOcrReviewRow {
  String _receiptFootprintReviewCueFor(
    BuildContext context,
    ExpenseReceiptParseDiagnostics? parseDiagnostics,
  ) {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (settings == null) return '';
    final footprint = settings.defaultDataSaverFootprintSummary;
    final installChoice = settings.defaultDataSaverParserPackInstallChoice;
    final acceptanceGate = settings.defaultDataSaverLocalOnlyAcceptanceGate;
    final firstInstallSummary =
        settings.defaultDataSaverFirstInstallBoundarySummary;
    if (acceptanceGate.blocksLowStorageUsers) {
      return 'Storage cue: the base receipt flow must be fixed before release. Capture, proof save, and basic local review cannot depend on heavy offline packs or cloud assist. $firstInstallSummary';
    }
    final actionCode = parseDiagnostics?.parserCategoryReviewActionCode ?? '';
    if (actionCode == 'optional_parser_pack_available') {
      if (footprint.shouldDeferOptionalLocalPacks) {
        return 'Storage cue: optional receipt detail packs are deferred on this phone. '
            'Continue with the filled receipt, add lines by hand, or use '
            'assisted help later only if you choose it. Deferred pack budget: '
            '${footprint.optionalLocalPackSizeLabel}. '
            '${acceptanceGate.userFacingSummary} $firstInstallSummary';
      }
      if (settings.defaultDataSaverShouldOfferOptionalLocalParserPacks) {
        return 'Storage cue: optional offline receipt detail add-ons may help this '
            'category (${installChoice.optionalLocalDownloadSizeLabel}). '
            'Receipt capture, receipt reading, and manual line review still work '
            'without downloading them. ${acceptanceGate.userFacingSummary} '
            '$firstInstallSummary';
      }
      if (installChoice.hasCloudFallback) {
        return 'Storage cue: local receipt detail add-ons are not available for this '
            'setup. Optional assisted help can be offered later only when the '
            'user chooses it and has internet. '
            '${acceptanceGate.userFacingSummary} $firstInstallSummary';
      }
    }
    if (acceptanceGate.baseFlowCanRunLocallyNow) {
      return 'Storage cue: receipt capture, proof save, and basic local review '
          'stay available now. Saved proof size does not change the clear '
          'source used for receipt review. ${acceptanceGate.userFacingSummary} '
          '$firstInstallSummary';
    }
    return '';
  }

  List<String> _receiptFootprintActionLabelsFor(
    BuildContext context,
    ExpenseReceiptParseDiagnostics? parseDiagnostics,
  ) {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (settings == null) return const [];
    final actionCode = parseDiagnostics?.parserCategoryReviewActionCode ?? '';
    final acceptanceGate = settings.defaultDataSaverLocalOnlyAcceptanceGate;
    if (acceptanceGate.blocksLowStorageUsers) {
      return const ['Keep local proof path', 'Fix base receipt flow'];
    }
    if (actionCode != 'optional_parser_pack_available') {
      return acceptanceGate.baseFlowCanRunLocallyNow
          ? const ['Continue local review', 'Save proof']
          : const [];
    }
    final footprint = settings.defaultDataSaverFootprintSummary;
    final installChoice = settings.defaultDataSaverParserPackInstallChoice;
    if (footprint.shouldDeferOptionalLocalPacks) {
      return const ['Continue without add-on', 'Review by hand'];
    }
    if (settings.defaultDataSaverShouldOfferOptionalLocalParserPacks) {
      return [
        'Continue without add-on',
        installChoice.optionalLocalDownloadPackCodes.length > 1
            ? 'Optional add-ons later'
            : 'Optional add-on later',
      ];
    }
    if (installChoice.hasCloudFallback) {
      return const ['Continue without add-on', 'Use assisted help later'];
    }
    return const [];
  }

  List<String> _ocrStructureActionLabelsFor(ReceiptOcrDiagnostics diagnostics) {
    if (diagnostics.hasOcrSourceGhostSliceContinuation) {
      return const [
        'Add bottom receipt section',
        'Repeat 3-5 lines in top ghost slice',
        'Review totals after receipt reading',
      ];
    }
    if (diagnostics.receiptMissingBottomEdgeAndTotals) {
      return const [
        'Add bottom receipt section',
        'Use top ghost slice',
        'Review totals after receipt reading',
      ];
    }
    if (diagnostics.receiptMayNeedBottomSection) {
      return const [
        'Check for missing bottom',
        'Add next receipt section',
        'Enter total manually',
      ];
    }
    return switch (diagnostics.ocrReceiptStructureStatus) {
      'ready_for_parser' => const [
        'Review filled fields',
        'Classify Business/Personal/Split',
      ],
      'missing_vendor' => const ['Check store name', 'Edit if wrong'],
      'no_items' => const [
        'Add line manually',
        'Use receipt total',
        'Retake/add photo',
      ],
      'missing_total' => const ['Check receipt total', 'Edit total'],
      'line_sequence_review' => const [
        'Check photo order',
        'Add missing section',
        'Retake section',
      ],
      'summary_math_review' => const [
        'Check subtotal',
        'Check tax',
        'Check total',
      ],
      'line_item_review' => const ['Review line prices', 'Edit item lines'],
      'no_text' => const [
        'Retake photo',
        'Add clearer photo',
        'Enter manually',
      ],
      _ => const ['Review receipt details'],
    };
  }

  List<String> _ocrAcceptedPhotoActionLabelsFor(
    ReceiptOcrDiagnostics diagnostics,
  ) {
    return switch (_ocrAcceptedPhotoWarningCueStatus(diagnostics)) {
      'saved_photo_darker_than_preview' ||
      'saved_photo_brightness_assist_failed_dark' => const [
        'Check totals before save',
        'Retake if text is hard to read',
      ],
      'saved_photo_brighter_than_preview' || 'saved_photo_glare_risk' => const [
        'Check washed-out prices',
        'Retake if glare hides totals',
      ],
      'saved_photo_soft_blur_risk' => const [
        'Check item prices',
        'Retake if text is fuzzy',
      ],
      'saved_photo_bottom_too_dark' || 'saved_photo_bottom_soft' => const [
        'Check bottom totals',
        'Add another bottom photo if needed',
      ],
      'saved_photo_dimmer_than_preview' ||
      'saved_photo_brightness_assist_still_dim' => const [
        'Check dim receipt text',
      ],
      _ => const [],
    };
  }

  String _ocrAcceptedPhotoCueFor(ReceiptOcrDiagnostics diagnostics) {
    return switch (_ocrAcceptedPhotoWarningCueStatus(diagnostics)) {
      'saved_photo_darker_than_preview' =>
        'Photo cue: saved darker than preview. Check the store, date, total, tax, and item prices before saving.',
      'saved_photo_brightness_assist_failed_dark' =>
        'Photo cue: brightness assist could not make the saved photo bright enough. Retake unless every key line is readable.',
      'saved_photo_brighter_than_preview' =>
        'Photo cue: saved brighter than preview. Check for washed-out totals, tax, and item prices before saving.',
      'saved_photo_glare_risk' =>
        'Photo cue: glare may hide totals or prices. Verify the filled receipt before saving.',
      'saved_photo_soft_blur_risk' =>
        'Photo cue: the accepted photo may be soft. Check item prices and totals before saving.',
      'saved_photo_bottom_too_dark' =>
        'Photo cue: bottom lines may be dark. Check the total, tax, barcode area, and final lines.',
      'saved_photo_bottom_soft' =>
        'Photo cue: bottom lines may be fuzzy. Check lower item prices and totals.',
      'saved_photo_dimmer_than_preview' ||
      'saved_photo_brightness_assist_still_dim' =>
        'Photo cue: the saved receipt was dim. Check the filled receipt before saving.',
      _ => '',
    };
  }

  String _ocrAcceptedPhotoWarningCueStatus(ReceiptOcrDiagnostics diagnostics) {
    final cue = diagnostics.ocrSourceHandoffContract['reviewCueStatus']
        ?.toString()
        .trim();
    if (cue != null && cue.isNotEmpty) return cue;
    for (final token in diagnostics.ocrSourceHandoffWarningProfileCounts.keys) {
      if (!token.startsWith('receipt_handoff_warning_')) continue;
      return token.replaceFirst('receipt_handoff_warning_', '');
    }
    return '';
  }
}
