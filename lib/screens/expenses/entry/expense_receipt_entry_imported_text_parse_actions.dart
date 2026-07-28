part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryImportedTextParseActions
    on _ExpenseReceiptEntryScreenState {
  Duration _receiptParserTimeout(ReceiptDeviceCapability capability) {
    return switch (capability.tier) {
      ReceiptCapabilityTier.heavyweight => const Duration(seconds: 18),
      ReceiptCapabilityTier.medium => const Duration(seconds: 24),
      ReceiptCapabilityTier.light => const Duration(seconds: 30),
    };
  }

  Future<void> _parseImportedReceiptText(String text) async {
    if (!_appAssistedReceiptFillEnabled) {
      _handleReceiptParseFailure(
        failureKind: 'assistance_policy_blocked',
        evidence: 'receipt_assist_disabled_before_imported_text_handoff',
        userMessage:
            'Receipt text is ready, but Receipt Assist is turned off for Expenses. Turn it on in Receipt Settings or continue manually.',
      );
      return;
    }
    await _parseImportedReceiptTextWithMemory(text);
  }

  Future<void> _parseImportedReceiptTextWithMemory(String text) async {
    if (mounted) {
      _updateReceiptState(() {
        _scanningReceiptPhotos = true;
        _receiptReviewFlowStarted = true;
        _receiptReadHandoffStage = 'Filling receipt details';
        _lastReceiptParseCompleted = false;
        _lastReceiptParseHadUsableData = false;
        _lastReceiptParseHadSafeLines = false;
      });
    }
    final capability =
        ReceiptCaptureSettingsScope.maybeOf(context)?.deviceCapability ??
        const ReceiptDeviceCapability.standard();
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.parserStarted,
      metadata: {
        'source': _receiptPrivacyFeatureArea,
        'parserDepth': capability.parserDepth.name,
      },
    );
    try {
      final parsed = await parseExpenseReceiptTextWithLocalMemory(
        text,
        fallbackDate: _selectedDate,
        // Generic Expenses reconstructs printed receipt lines only. Product
        // matching belongs to the separately routed Inventory handoff.
        parserDepth: ReceiptParserDepth.lineItems,
        maxCatalogCandidates: 0,
      ).timeout(_receiptParserTimeout(capability));
      unawaited(_recordPrivacySafeParseEvent(parsed));
      _recordParserTelemetry(parsed);
      if (!mounted) return;
      _updateReceiptState(() {
        _scanningReceiptPhotos = false;
      });
      _applyParsedReceipt(parsed);
    } on TimeoutException {
      _handleReceiptParseFailure(
        failureKind: 'receipt_parser_timeout',
        evidence: 'parser_exceeded_device_timeout',
        userMessage:
            'Receipt details took too long to prepare. Continue manually or retry the receipt photos.',
      );
    } catch (_) {
      _handleReceiptParseFailure(
        failureKind: 'receipt_parser_exception',
        evidence: 'parser_threw_exception',
        userMessage: 'Receipt text could not be parsed. Review manually.',
      );
    }
  }

  /// Builds the editable expense review directly from the OCR document so the
  /// parser retains line locations and source evidence instead of receiving a
  /// flattened text-only copy.
  Future<void> _parseReceiptOcrResultFromCapture(
    ReceiptOcrResult ocr,
    String traceId,
  ) async {
    if (!_appAssistedReceiptFillEnabled) {
      _handleReceiptParseFailure(
        failureKind: 'assistance_policy_blocked',
        evidence: 'receipt_assist_disabled_before_ocr_result_handoff',
        userMessage:
            'Receipt text is ready, but Receipt Assist is turned off for Expenses. Turn it on in Receipt Settings or continue manually.',
      );
      return;
    }
    // The capture reader can report a completed OCR operation even when the
    // provider supplied no usable printable receipt evidence. Do not enter the
    // parser worker for that result: it cannot fill editable fields and used
    // to leave the review surface misleadingly stuck on preparation.
    if (ocr.appFillText.trim().isEmpty) {
      _handleReceiptParseFailure(
        failureKind: 'receipt_ocr_no_usable_text',
        evidence: 'ocr_result_app_fill_text_empty',
        userMessage:
            'No readable receipt text was found. Keep the saved photo and enter the receipt manually, or retake a clearer photo.',
      );
      return;
    }
    if (mounted) {
      _updateReceiptState(() {
        _scanningReceiptPhotos = true;
        _receiptReviewFlowStarted = true;
        _receiptReadHandoffStage = 'Filling receipt details';
        _lastReceiptParseCompleted = false;
        _lastReceiptParseHadUsableData = false;
        _lastReceiptParseHadSafeLines = false;
      });
    }
    final capability =
        ReceiptCaptureSettingsScope.maybeOf(context)?.deviceCapability ??
        const ReceiptDeviceCapability.standard();
    final traceStopwatch = Stopwatch()..start();
    traceReceiptPipelineStage(
      'expense_review_prepare_started',
      traceId: traceId,
      deviceTier: capability.tier.name,
    );
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.parserStarted,
      metadata: {
        'source': _receiptPrivacyFeatureArea,
        'parserDepth': capability.parserDepth.name,
        'receiptEvidence': 'ocr_document_with_layout',
      },
    );
    final handoff = ReceiptOcrHandoff.forUserSelection(
      ocr: ocr,
      selectedCategory: widget.initialCategory,
      inventoryRequested: _isMaterialsFlow || _trackMaterialsInInventory,
    );
    PreparedExpenseReceiptOcrReview? preparedExpenseReview;
    try {
      final routed = await _receiptOcrHandoffRouter(
        capability,
        traceId: traceId,
        onExpensePrepared: (prepared) => preparedExpenseReview = prepared,
      ).dispatch(handoff).timeout(_receiptParserTimeout(capability));
      traceReceiptPipelineStage(
        'expense_review_worker_returned',
        traceId: traceId,
        elapsedMs: traceStopwatch.elapsedMilliseconds,
        destination: handoff.destination.name,
      );
      final parsed = fillMissingExpenseReceiptFieldsFromOcrCandidates(
        routed,
        ocr.layout,
      );
      unawaited(_recordPrivacySafeParseEvent(parsed));
      _recordParserTelemetry(parsed);
      final ocrDiagnostics = preparedExpenseReview?.ocrDiagnostics;
      final ocrWarnings =
          preparedExpenseReview?.ocrWarnings ?? ocr.structuredWarnings;
      if (!mounted) return;
      _updateReceiptState(() {
        _scanningReceiptPhotos = false;
        _lastOcrDiagnostics = ocrDiagnostics;
        _lastOcrWarnings = ocrWarnings;
      });
      _applyParsedReceipt(parsed);
      traceReceiptPipelineStage(
        'expense_review_fields_applied',
        traceId: traceId,
        elapsedMs: traceStopwatch.elapsedMilliseconds,
        destination: handoff.destination.name,
      );
    } on TimeoutException {
      _handleReceiptParseFailure(
        failureKind: 'receipt_parser_timeout',
        evidence: 'ocr_document_parser_exceeded_device_timeout',
        userMessage:
            'Receipt details took too long to prepare. Continue manually or retry the receipt photos.',
      );
    } catch (_) {
      _handleReceiptParseFailure(
        failureKind: 'receipt_parser_exception',
        evidence: 'ocr_document_parser_threw_exception',
        userMessage: 'Receipt text could not be parsed. Review manually.',
      );
    }
  }

  void _handleReceiptParseFailure({
    required String failureKind,
    required String evidence,
    required String userMessage,
  }) {
    if (!mounted) return;
    _updateReceiptState(() {
      _scanningReceiptPhotos = false;
      _receiptReadHandoffDecision = 'Open manual receipt details';
      _receiptReadHandoffAction = userMessage;
      _receiptReadHandoffStage = 'Receipt details need manual entry';
      _receiptReadHandoffRouteResult = _receiptManualDetailsRouteResultLabel;
      _lastReceiptParseCompleted = true;
      _lastReceiptParseHadUsableData = false;
      _lastReceiptParseHadSafeLines = false;
    });
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.parserFailed,
      failureKind: failureKind,
      diagnostic: ExpenseFailureDiagnostic(
        workflowStep: ExpenseWorkflowStep.receiptParser,
        failedAt: failureKind,
        confirmedCause: failureKind,
        causeStatus: ExpenseFailureCauseStatus.confirmed,
        evidence: evidence,
        missingEvidence: 'none',
      ),
      metadata: {'source': _receiptPrivacyFeatureArea},
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(userMessage)));
    _scrollToReceiptReview();
  }
}
