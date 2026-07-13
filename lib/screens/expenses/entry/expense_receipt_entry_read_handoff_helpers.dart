part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryReadHandoffHelpers
    on _ExpenseReceiptEntryScreenState {
  void _markReceiptReadFinished(bool didRead) {
    if (!mounted) return;
    if (didRead) {
      _updateReceiptState(() {
        final diagnostics = _lastOcrDiagnostics;
        final missingBottomEdgeAndTotals =
            diagnostics?.receiptMissingBottomEdgeAndTotals == true;
        final mayNeedBottomSection =
            diagnostics?.receiptMayNeedBottomSection == true;
        final parseCompleted = _lastReceiptParseCompleted;
        final parseHasUsableDetails = _lastReceiptParseHadUsableData;
        final parseHasSafeLines = _lastReceiptParseHadSafeLines;
        // A photo read can finish before its receipt-detail handoff. Keep one
        // unambiguous progress state visible until that handoff has resolved.
        _scanningReceiptPhotos = !parseCompleted;
        _receiptReviewFlowStarted = true;
        _receiptReadAttemptedWithoutText = false;
        if (!parseCompleted) {
          _receiptReadHandoffDecision = 'Preparing receipt details';
          _receiptReadHandoffAction =
              'Keep this screen open while OCR and parsing finish filling the receipt review.';
          _receiptReadHandoffStage = 'Receipt details still being filled';
          _receiptReadHandoffRouteResult =
              'Receipt details are still being prepared from the accepted proof.';
        } else if (missingBottomEdgeAndTotals) {
          _receiptReadHandoffDecision = 'Add bottom receipt section';
          _receiptReadHandoffAction =
              diagnostics?.receiptCompletionReviewActionLabel ??
              _receiptMissingTotalsHandoffActionLabel;
          _receiptReadHandoffStage = 'Receipt details need bottom section';
          _receiptReadHandoffRouteResult =
              _receiptMissingBottomEdgeAndTotalsRouteResultLabel;
          _receiptReadHandoffCoverageWarning =
              _receiptMissingBottomEdgeAndTotalsRouteResultLabel;
        } else if (mayNeedBottomSection || _ocrTotalsEvidenceMissing) {
          _receiptReadHandoffDecision = mayNeedBottomSection
              ? 'Add bottom receipt section'
              : _receiptFilledReviewDecisionLabel;
          _receiptReadHandoffAction =
              diagnostics?.receiptCompletionReviewActionLabel ??
              _receiptMissingTotalsHandoffActionLabel;
          _receiptReadHandoffStage = mayNeedBottomSection
              ? 'Receipt details need bottom section'
              : 'Receipt details need bottom check';
          _receiptReadHandoffRouteResult =
              _receiptMissingTotalsRouteResultLabel;
          _receiptReadHandoffCoverageWarning =
              _receiptMissingTotalsCoverageWarningLabel;
        } else if (!parseHasUsableDetails) {
          _receiptReadAttemptedWithoutText = true;
          _receiptReadHandoffDecision = 'Open manual receipt details';
          _receiptReadHandoffAction =
              'OCR finished, but the parser did not find safe receipt fields. Keep the proof and fill in the details manually.';
          _receiptReadHandoffStage = 'Receipt details need manual entry';
          _receiptReadHandoffRouteResult =
              _receiptManualDetailsRouteResultLabel;
        } else {
          _receiptReadHandoffDecision = _receiptFilledReviewDecisionLabel;
          _receiptReadHandoffAction = parseHasSafeLines
              ? _receiptFilledReviewActionLabel
              : 'Review parsed store, date, tax, and totals, then add item prices if needed.';
          _receiptReadHandoffStage = _receiptReviewReadyStageLabel;
          _receiptReadHandoffRouteResult =
              _receiptParsedDetailsRouteResultLabel;
        }
      });
      _scrollToReceiptReview();
      return;
    }
    _updateReceiptState(() {
      _scanningReceiptPhotos = false;
      _receiptReviewFlowStarted = true;
      _receiptReadAttemptedWithoutText = true;
      _receiptReadHandoffStage = 'Needs manual review';
      _receiptReadHandoffRouteResult =
          _receiptUnreadableDetailsRouteResultLabel;
    });
    _scrollToReceiptReview();
  }

  void _markReceiptOcrCompleted(ReceiptOcrResult result) {
    if (!mounted) return;
    final diagnostics = result.diagnostics;
    ExpenseScreenTelemetryRecorder.record(
      context,
      result.hasText
          ? ExpenseTelemetryEventType.ocrCompleted
          : ExpenseTelemetryEventType.ocrFailed,
      metadata: {
        'source': _receiptPrivacyFeatureArea,
        'captureFlow': 'receipt_attachment_panel',
        ..._ocrCompletionReviewMetadata(diagnostics),
      },
    );
    _updateReceiptState(() {
      _lastOcrDiagnostics = diagnostics;
      _lastOcrWarnings = result.structuredWarnings;
      if (result.hasText) {
        _receiptReviewFlowStarted = true;
        _receiptReadAttemptedWithoutText = false;
        _receiptReadHandoffStage = _receiptPostCaptureRouteStageLabel(
          diagnostics,
        );
        _receiptReadHandoffAction =
            diagnostics.receiptPostCaptureRouteStatus != 'parsed_receipt_review'
            ? diagnostics.receiptPostCaptureRouteLabel
            : _receiptReadHandoffAction;
        _receiptReadHandoffRouteResult = _receiptPostCaptureRouteResultLabel(
          diagnostics,
        );
        if (diagnostics.receiptMissingBottomEdgeAndTotals) {
          _receiptReadHandoffCoverageWarning =
              _receiptMissingBottomEdgeAndTotalsRouteResultLabel;
        } else if (diagnostics.receiptMayNeedBottomSection) {
          _receiptReadHandoffCoverageWarning =
              _receiptMissingTotalsCoverageWarningLabel;
        }
      } else {
        _receiptReviewFlowStarted = true;
        _receiptReadAttemptedWithoutText = true;
        final primaryWarning = result.primaryWarning;
        _receiptReadHandoffStage = primaryWarning == null
            ? 'Needs manual review'
            : 'Needs manual review: ${primaryWarning.label}';
        _receiptReadHandoffRouteResult =
            _receiptUnreadableDetailsRouteResultLabel;
      }
    });
    _scrollToReceiptReview();
  }

  String _receiptPostCaptureRouteStageLabel(ReceiptOcrDiagnostics diagnostics) {
    return switch (diagnostics.receiptPostCaptureRouteStatus) {
      'add_next_receipt_section' => 'Receipt details need next section',
      'parsed_receipt_review_check_total' =>
        'Receipt details need bottom check',
      'parsed_receipt_review_check_vendor' =>
        'Receipt details need store check',
      'parsed_receipt_review_manual_check' => 'Receipt details need review',
      'parsed_receipt_review_user_confirmed_complete' =>
        'Receipt details need user-confirmed total check',
      'retake_or_manual_entry' => 'Needs manual review',
      _ => 'Opening receipt details from accepted photo',
    };
  }

  String _receiptPostCaptureRouteResultLabel(
    ReceiptOcrDiagnostics diagnostics,
  ) {
    return switch (diagnostics.receiptPostCaptureRouteStatus) {
      'add_next_receipt_section' =>
        _receiptMissingBottomEdgeAndTotalsRouteResultLabel,
      'parsed_receipt_review_check_total' =>
        _receiptMissingTotalsRouteResultLabel,
      'parsed_receipt_review_check_vendor' =>
        'Receipt details review opened, but the store name needs review before saving.',
      'parsed_receipt_review_manual_check' =>
        _receiptManualDetailsRouteResultLabel,
      'parsed_receipt_review_user_confirmed_complete' =>
        'Receipt details review opened with user-confirmed receipt coverage; check totals before saving.',
      'retake_or_manual_entry' => _receiptUnreadableDetailsRouteResultLabel,
      _ => _receiptManualDetailsRouteResultLabel,
    };
  }

  String get _receiptReviewReadyStageLabel {
    if (_lines.isNotEmpty) {
      final lineLabel = _lines.length == 1
          ? '1 receipt line'
          : '${_lines.length} receipt lines';
      final reviewLabel = _unreviewedParsedLineCount == 0
          ? 'ready to classify'
          : 'need review';
      return 'Receipt details ready: $lineLabel $reviewLabel';
    }
    if (_receiptTotalController.text.trim().isNotEmpty ||
        _storeController.text.trim().isNotEmpty ||
        _rawReceiptText.trim().isNotEmpty) {
      return 'Receipt details ready: check fields and add lines if needed';
    }
    return 'Receipt details ready';
  }

  String get _receiptFilledReviewDecisionLabel => 'Open receipt details';

  String get _receiptFilledReviewActionLabel =>
      'Review store, date, tax, total, item prices, and Business/Personal/Mixed';

  String _receiptDecisionLabelForParsedReceipt(
    ExpenseReceiptParseResult parsed,
  ) {
    if (parsed.diagnostics.shouldSuggestLowerReceiptSection ||
        parsed.diagnostics.hasOcrSourceMissingBottomCoverageEvidence ||
        parsed.diagnostics.hasOcrSourceBottomOverlapGhostContinuation) {
      return 'Add bottom receipt section';
    }
    return _receiptFilledReviewDecisionLabel;
  }

  String _receiptActionLabelForParsedReceipt(ExpenseReceiptParseResult parsed) {
    if (parsed.diagnostics.hasOcrSourceBottomOverlapGhostContinuation) {
      return parsed.diagnostics.ocrSourceContinuationReviewActionLabel;
    }
    if (parsed.diagnostics.hasOcrSourceMissingBottomCoverageEvidence) {
      return parsed.diagnostics.ocrSourceCoverageReviewActionLabel;
    }
    if (parsed.diagnostics.shouldSuggestLowerReceiptSection) {
      return 'Add the lower receipt section, or continue and enter the total manually if this is the full receipt.';
    }
    return parsed.diagnostics.localReceiptParserRoutingActionLabel;
  }

  String _receiptStageLabelForParsedReceipt(ExpenseReceiptParseResult parsed) {
    if (parsed.diagnostics.shouldSuggestLowerReceiptSection ||
        parsed.diagnostics.hasOcrSourceMissingBottomCoverageEvidence ||
        parsed.diagnostics.hasOcrSourceBottomOverlapGhostContinuation) {
      return 'Receipt details need bottom section';
    }
    return _receiptReviewReadyStageLabel;
  }

  bool get _ocrTotalsEvidenceMissing =>
      _lastOcrDiagnostics?.receiptTotalsTextEvidenceStatus == 'missing';

  String get _receiptMissingTotalsHandoffActionLabel =>
      'Check the bottom of the receipt. Add the next section if it continues, or enter the total manually.';

  String get _receiptMissingTotalsCoverageWarningLabel =>
      'Subtotal/total lines were not found. If this photo does not include the bottom of the receipt, use Add / Retake to add the next receipt section.';

  String get _receiptMissingBottomEdgeAndTotalsRouteResultLabel =>
      'Receipt details are waiting on the bottom receipt section because bottom-edge evidence and subtotal/total text indicate the next section may be missing.';

  String get _receiptParsedDetailsRouteResultLabel =>
      'Receipt details review opened with parsed receipt fields';

  String get _receiptMissingTotalsRouteResultLabel =>
      'Receipt details need a bottom check because subtotal/total evidence is missing and may need another receipt section.';

  String get _receiptManualDetailsRouteResultLabel =>
      'Receipt details review opened for manual receipt line review';

  String get _receiptTotalsOnlyDetailsRouteResultLabel =>
      'Receipt details review opened with parsed totals and no safe item lines';

  String get _receiptUnreadableDetailsRouteResultLabel =>
      'Receipt details review opened with saved proof and no readable text';

  String _receiptDetailsRouteResultForParsedReceipt(
    ExpenseReceiptParseResult parsed,
  ) {
    final routeSummary =
        parsed.diagnostics.localReceiptParserRoutingSummaryLabel;
    final bottomEvidence =
        parsed.diagnostics.missingBottomTotalsLocalEvidenceReviewLabel;
    if (parsed.diagnostics.shouldSuggestLowerReceiptSection ||
        parsed.diagnostics.hasOcrSourceMissingBottomCoverageEvidence ||
        parsed.diagnostics.hasOcrSourceBottomOverlapGhostContinuation) {
      final evidence = bottomEvidence.isEmpty
          ? '${parsed.diagnostics.lowerReceiptSectionReviewLabel}: ${parsed.diagnostics.ocrSourceSectionReviewLabel}'
          : bottomEvidence;
      return '$_receiptMissingBottomEdgeAndTotalsRouteResultLabel: $evidence';
    }
    if (parsed.lines.isNotEmpty) {
      return '$_receiptParsedDetailsRouteResultLabel: $routeSummary';
    }
    if (parsed.enteredTotal != null ||
        parsed.enteredSubtotal != null ||
        parsed.enteredTax != null) {
      return '$_receiptTotalsOnlyDetailsRouteResultLabel: $routeSummary';
    }
    return '$_receiptManualDetailsRouteResultLabel: $routeSummary';
  }
}
