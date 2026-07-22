part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryImportedTextParseActions
    on _ExpenseReceiptEntryScreenState {
  Duration _receiptParserTimeout(ReceiptDeviceCapability capability) {
    return switch (capability.tier) {
      ReceiptCapabilityTier.heavyweight => const Duration(seconds: 18),
      ReceiptCapabilityTier.medium => const Duration(seconds: 28),
      ReceiptCapabilityTier.light => const Duration(seconds: 42),
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
        parserDepth: capability.parserDepth,
        maxCatalogCandidates: capability.maxLocalCatalogMatches,
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
  Future<void> _parseReceiptOcrResultFromCapture(ReceiptOcrResult ocr) async {
    if (!_appAssistedReceiptFillEnabled) {
      _handleReceiptParseFailure(
        failureKind: 'assistance_policy_blocked',
        evidence: 'receipt_assist_disabled_before_ocr_result_handoff',
        userMessage:
            'Receipt text is ready, but Receipt Assist is turned off for Expenses. Turn it on in Receipt Settings or continue manually.',
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
    try {
      final routed = await _receiptOcrHandoffRouter(
        capability,
      ).dispatch(handoff).timeout(_receiptParserTimeout(capability));
      final parsed = fillMissingExpenseReceiptFieldsFromOcrCandidates(
        routed,
        ocr.layout,
      );
      unawaited(_recordPrivacySafeParseEvent(parsed));
      _recordParserTelemetry(parsed);
      if (!mounted) return;
      _updateReceiptState(() => _scanningReceiptPhotos = false);
      _applyParsedReceipt(parsed);
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
