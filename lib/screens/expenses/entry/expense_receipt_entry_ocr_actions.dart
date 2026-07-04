part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryOcrActions on _ExpenseReceiptEntryScreenState {
  void _scanReceiptAttachmentsIfNeeded() {
    if (!_appAssistedReceiptFillEnabled) return;
    final signature = _receiptAttachments
        .where(
          (attachment) =>
              (attachment.isPhoto && attachment.path.trim().isNotEmpty) ||
              (attachment.isPdf && attachment.path.trim().isNotEmpty) ||
              (attachment.isImportedText &&
                  attachment.importedText.trim().isNotEmpty),
        )
        .map(
          (attachment) => [
            attachment.id,
            attachment.kind.name,
            attachment.path.trim(),
            attachment.importedText.trim(),
          ].join(':'),
        )
        .join('|');
    if (signature.isEmpty || signature == _lastReceiptScanSignature) return;
    _lastReceiptScanSignature = signature;
    unawaited(_scanAttachedReceiptAttachments());
  }

  Future<void> _scanAttachedReceiptAttachments() async {
    if (!_appAssistedReceiptFillEnabled) return;
    if (_scanningReceiptPhotos) return;
    final readableAttachments = _receiptAttachments
        .where(
          (attachment) =>
              (attachment.isPhoto && attachment.path.trim().isNotEmpty) ||
              (attachment.isPdf && attachment.path.trim().isNotEmpty) ||
              (attachment.isImportedText &&
                  attachment.importedText.trim().isNotEmpty),
        )
        .toList(growable: false);
    if (readableAttachments.isEmpty) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.validationError,
        validationErrorKind: 'missing_receipt_attachment',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptAttachment,
          failedAt: 'before_ocr_start',
          confirmedCause: 'missing_receipt_attachment',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'readable_attachment_count_zero',
          missingEvidence: 'none',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attach a receipt photo, PDF, or pasted text first.'),
        ),
      );
      return;
    }
    _updateReceiptState(() {
      _scanningReceiptPhotos = true;
      _receiptReviewFlowStarted = true;
      _receiptReadHandoffStage =
          'Reading receipt proof before filling receipt details';
      _lastReceiptParseCompleted = false;
      _lastReceiptParseHadUsableData = false;
      _lastReceiptParseHadSafeLines = false;
    });
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    final capability =
        settings?.deviceCapability ?? const ReceiptDeviceCapability.standard();
    final cloudAssistPlan = capability.cloudAssistPlanFor(
      dataSaverLevel:
          settings?.defaultDataSaverLevel ?? ReceiptDataSaverLevel.balanced,
    );
    final cloudAssistMetadata = cloudAssistPlan.toPrivacySafeDiagnostics();
    final policy = ReceiptAssistancePolicy(
      device: capability,
      cloudAssistedAvailable: cloudAssistPlan.cloudOcrOptional,
    );
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.ocrStarted,
      metadata: {'source': _receiptPrivacyFeatureArea, ...cloudAssistMetadata},
    );
    final decision = policy.decideForAttachments(readableAttachments);
    if (decision.mode == ReceiptAssistanceMode.proofOnly ||
        decision.mode == ReceiptAssistanceMode.cloudCandidate) {
      final warning = decision.warnings.isEmpty
          ? decision.reason
          : '${decision.reason} ${decision.warnings.first}';
      if (!mounted) return;
      _updateReceiptState(() {
        _scanningReceiptPhotos = false;
        _receiptReadHandoffStage = 'Needs manual review';
        _receiptReadHandoffRouteResult = _receiptManualDetailsRouteResultLabel;
      });
      _lastOcrDiagnostics = null;
      _lastOcrWarnings = const [];
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.ocrFailed,
        failureKind: 'assistance_policy_blocked',
        diagnostic: ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptOcr,
          failedAt: 'before_ocr_start',
          confirmedCause: 'assistance_policy_blocked',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: decision.mode.name,
          missingEvidence: 'none',
        ),
        metadata: {
          'source': _receiptPrivacyFeatureArea,
          ...cloudAssistMetadata,
        },
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(warning)));
      return;
    }
    final ocr = await ReceiptOcrService.forDevice(
      capability,
    ).recognizeTextFromAttachments(_receiptAttachments);
    final failureDiagnostic = ocr.hasText
        ? null
        : ExpenseOcrFailureDiagnostics.fromOcrResult(ocr);
    if (!mounted) return;
    ExpenseScreenTelemetryRecorder.record(
      context,
      ocr.hasText
          ? ExpenseTelemetryEventType.ocrCompleted
          : ExpenseTelemetryEventType.ocrFailed,
      failureKind: failureDiagnostic?.confirmedCause,
      diagnostic: failureDiagnostic,
      metadata: {
        'source': _receiptPrivacyFeatureArea,
        'ocrEngine': capability.tier.name,
        'parserDepth': capability.parserDepth.name,
        'count': readableAttachments.length,
        ..._ocrCompletionReviewMetadata(ocr.diagnostics),
        'ocrSourceHandoffStatus': ocr.diagnostics.ocrSourceHandoffStatus,
        if (ocr.diagnostics.ocrSourceHandoffSignalCounts.isNotEmpty)
          'ocrSourceHandoffSignalCounts':
              ocr.diagnostics.ocrSourceHandoffSignalCounts,
        if (ocr.diagnostics.ocrSourceReviewDepthSignalCounts.isNotEmpty)
          'ocrSourceReviewDepthSignalCounts':
              ocr.diagnostics.ocrSourceReviewDepthSignalCounts,
        if (ocr.diagnostics.ocrSourceReviewDepthStatus.trim().isNotEmpty)
          'ocrSourceReviewDepthStatus':
              ocr.diagnostics.ocrSourceReviewDepthStatus,
        if (ocr.diagnostics.ocrSourceStitchSignalCounts.isNotEmpty)
          'ocrSourceStitchSignalCounts':
              ocr.diagnostics.ocrSourceStitchSignalCounts,
        if (ocr.diagnostics.ocrSourceScannerDecisionCounts.isNotEmpty)
          'ocrSourceScannerDecisionCounts':
              ocr.diagnostics.ocrSourceScannerDecisionCounts,
        if (ocr.diagnostics.ocrSourceCaptureSourceSignalCounts.isNotEmpty)
          'ocrSourceCaptureSourceSignalCounts':
              ocr.diagnostics.ocrSourceCaptureSourceSignalCounts,
        if (ocr.diagnostics.ocrSourcePhotoQualityRiskCounts.isNotEmpty)
          'ocrSourcePhotoQualityRiskCounts':
              ocr.diagnostics.ocrSourcePhotoQualityRiskCounts,
        ..._ocrSourceQualityReviewMetadata(
          ocr.diagnostics.ocrSourceHandoffContract,
        ),
        ...cloudAssistMetadata,
      },
    );
    unawaited(_recordPrivacySafeOcrEvent(ocr, capability: capability));
    final receiptMissingBottomEdgeAndTotals =
        ocr.diagnostics.receiptMissingBottomEdgeAndTotals;
    final receiptMayNeedBottomSection =
        ocr.diagnostics.receiptMayNeedBottomSection;
    _updateReceiptState(() {
      _scanningReceiptPhotos = false;
      _receiptReadHandoffStage = ocr.hasText
          ? ocr.diagnostics.receiptPostCaptureRouteStatus ==
                    'parsed_receipt_review'
                ? 'Filling receipt details from accepted proof'
                : _receiptPostCaptureRouteStageLabel(ocr.diagnostics)
          : 'Needs manual review';
      _receiptReadHandoffAction =
          ocr.diagnostics.receiptPostCaptureRouteStatus !=
              'parsed_receipt_review'
          ? ocr.diagnostics.receiptPostCaptureRouteLabel
          : _receiptReadHandoffAction;
      if (!ocr.hasText) {
        _receiptReadHandoffRouteResult =
            _receiptUnreadableDetailsRouteResultLabel;
      } else {
        _receiptReadHandoffRouteResult = _receiptPostCaptureRouteResultLabel(
          ocr.diagnostics,
        );
      }
      if (receiptMissingBottomEdgeAndTotals) {
        _receiptReadHandoffCoverageWarning =
            _receiptMissingBottomEdgeAndTotalsRouteResultLabel;
      } else if (receiptMayNeedBottomSection) {
        _receiptReadHandoffCoverageWarning =
            _receiptMissingTotalsCoverageWarningLabel;
      }
    });
    if (!ocr.hasText) {
      _lastOcrDiagnostics = ocr.diagnostics;
      _lastOcrWarnings = ocr.structuredWarnings;
      final warning = ocr.strongestActionMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(warning)));
      return;
    }
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.parserStarted,
      metadata: {
        'source': _receiptPrivacyFeatureArea,
        'parserDepth': capability.parserDepth.name,
        'localParserScope': capability.cloudAssistPlan.localParserScopeCode,
      },
    );
    final parsed = _withReceiptBrainHandoffDiagnostics(
      await parseExpenseReceiptOcrResultWithLocalMemory(
        ocr,
        fallbackDate: _selectedDate,
        capability: capability,
      ),
    );
    unawaited(_recordPrivacySafeParseEvent(parsed));
    _recordParserTelemetry(parsed);
    if (!mounted) return;
    _updateReceiptState(() {
      _lastOcrDiagnostics = ocr.diagnostics;
      _lastOcrWarnings = ocr.structuredWarnings;
    });
    _applyParsedReceipt(parsed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ocr.reviewMessage(
            successMessage:
                'Receipt filled. Review the store, date, totals, and lines below before saving.',
          ),
        ),
      ),
    );
  }

  bool get _appAssistedReceiptFillEnabled {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    return settings?.appAssistedEnabledFor(_receiptCaptureArea) != false;
  }

  Future<void> _recordPrivacySafeOcrEvent(
    ReceiptOcrResult result, {
    required ReceiptDeviceCapability capability,
  }) async {
    try {
      final store = await PrivacySafeReceiptEventStore.create();
      await store.enqueue(
        PrivacySafeReceiptEvent.fromOcrResult(
          result: result,
          featureArea: _receiptPrivacyFeatureArea,
          capability: capability,
        ),
      );
    } catch (_) {
      // Receipt diagnostics must never interrupt the user's receipt workflow.
    }
  }

  Future<void> _recordPrivacySafeParseEvent(
    ExpenseReceiptParseResult result,
  ) async {
    try {
      final store = await PrivacySafeReceiptEventStore.create();
      await store.enqueue(
        PrivacySafeReceiptEvent.fromParseResult(
          result: result,
          featureArea: _receiptPrivacyFeatureArea,
        ),
      );
    } catch (_) {
      // Receipt diagnostics must never interrupt the user's receipt workflow.
    }
  }
}
