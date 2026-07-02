part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryImportedTextParseActions
    on _ExpenseReceiptEntryScreenState {
  Future<void> _parseImportedReceiptText(String text) async {
    if (!_appAssistedReceiptFillEnabled) return;
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
      );
      unawaited(_recordPrivacySafeParseEvent(parsed));
      _recordParserTelemetry(parsed);
      if (!mounted) return;
      _updateReceiptState(() {
        _scanningReceiptPhotos = false;
      });
      _applyParsedReceipt(parsed);
    } catch (_) {
      if (!mounted) return;
      _updateReceiptState(() {
        _scanningReceiptPhotos = false;
        _receiptReadHandoffStage = 'Needs manual review';
        _receiptReadHandoffRouteResult =
            _receiptUnreadableDetailsRouteResultLabel;
        _lastReceiptParseCompleted = true;
        _lastReceiptParseHadUsableData = false;
        _lastReceiptParseHadSafeLines = false;
      });
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.parserFailed,
        failureKind: 'receipt_parser_exception',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptParser,
          failedAt: 'receipt_parser_exception',
          confirmedCause: 'receipt_parser_exception',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'parser_threw_exception',
          missingEvidence: 'none',
        ),
        metadata: {'source': _receiptPrivacyFeatureArea},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt text could not be parsed. Review manually.'),
        ),
      );
    }
  }
}
