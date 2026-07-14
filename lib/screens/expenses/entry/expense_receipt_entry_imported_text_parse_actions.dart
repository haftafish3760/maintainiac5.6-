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
    final ocr = _matchingReceiptOcrResultFor(text);
    await _parseReceiptForEditableReview(
      (capability) => ocr == null
          ? parseExpenseReceiptTextWithLocalMemory(
              text,
              fallbackDate: _selectedDate,
              parserDepth: capability.parserDepth,
              maxCatalogCandidates: capability.maxLocalCatalogMatches,
            )
          : _parseReceiptOcrResultForEditableReview(
              ocr,
              capability: capability,
            ),
    );
  }

  Future<void> _parseReceiptOcrResultForAttachmentReview(
    ReceiptOcrResult ocr,
  ) async {
    if (!_appAssistedReceiptFillEnabled) {
      _handleReceiptParseFailure(
        failureKind: 'assistance_policy_blocked',
        evidence: 'receipt_assist_disabled_before_structured_ocr_handoff',
        userMessage:
            'Receipt text is ready, but Receipt Assist is turned off for Expenses. Turn it on in Receipt Settings or continue manually.',
      );
      return;
    }
    return _parseReceiptForEditableReview(
      (capability) =>
          _parseReceiptOcrResultForEditableReview(ocr, capability: capability),
    );
  }

  Future<void> _parseReceiptForEditableReview(
    Future<ExpenseReceiptParseResult> Function(
      ReceiptDeviceCapability capability,
    )
    parse,
  ) async {
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
      final parsed = await parse(
        capability,
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

  ReceiptOcrResult? _matchingReceiptOcrResultFor(String text) {
    final ocr = _latestOcrResultForReceiptHandoff;
    if (ocr == null || ocr.appFillText != text) return null;
    return ocr;
  }

  Future<ExpenseReceiptParseResult> _parseReceiptOcrResultForEditableReview(
    ReceiptOcrResult ocr, {
    required ReceiptDeviceCapability capability,
  }) async {
    final handoff = ReceiptOcrHandoff.forUserSelection(
      ocr: ocr,
      selectedCategory: widget.initialCategory,
      inventoryRequested: _isMaterialsFlow || _trackMaterialsInInventory,
    );
    final parsed = await _receiptOcrHandoffRouter(capability).dispatch(handoff);
    return fillMissingExpenseReceiptFieldsFromOcrCandidates(parsed, ocr.layout);
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
