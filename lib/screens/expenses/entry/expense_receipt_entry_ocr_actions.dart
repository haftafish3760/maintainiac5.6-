part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryOcrActions on _ExpenseReceiptEntryScreenState {
  Duration _receiptOcrDeadline(ReceiptDeviceCapability capability) {
    return switch (capability.tier) {
      // A current flagship should either produce text or offer recovery within
      // twenty seconds. Older devices receive a proportionate ceiling.
      ReceiptCapabilityTier.heavyweight => const Duration(seconds: 20),
      ReceiptCapabilityTier.medium => const Duration(seconds: 25),
      ReceiptCapabilityTier.light => const Duration(seconds: 30),
    };
  }

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
    if (signature.isEmpty ||
        signature == _lastReceiptScanSignature ||
        signature == _pendingReceiptScanSignature) {
      return;
    }
    if (_scanningReceiptPhotos) {
      _pendingReceiptScanSignature = signature;
      return;
    }
    _lastReceiptScanSignature = signature;
    unawaited(_scanAttachedReceiptAttachments());
  }

  Future<void> _scanAttachedReceiptAttachments() async {
    if (!_appAssistedReceiptFillEnabled) return;
    if (_scanningReceiptPhotos) return;
    try {
      await _performReceiptAttachmentScan();
    } catch (_) {
      _handleReceiptOcrReadFailure();
    } finally {
      if (mounted) {
        if (_scanningReceiptPhotos) {
          _updateReceiptState(() => _scanningReceiptPhotos = false);
        }
        final pendingSignature = _pendingReceiptScanSignature;
        _pendingReceiptScanSignature = '';
        if (pendingSignature.isNotEmpty &&
            pendingSignature != _lastReceiptScanSignature) {
          _lastReceiptScanSignature = pendingSignature;
          unawaited(_scanAttachedReceiptAttachments());
        }
      }
    }
  }

  Future<void> _performReceiptAttachmentScan() async {
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
    final deadline = _receiptOcrDeadline(capability);
    final stopwatch = Stopwatch()..start();
    late final ReceiptOcrResult ocr;
    try {
      ocr = await ReceiptOcrService.forDevice(
        capability,
      ).recognizeTextFromAttachments(_receiptAttachments).timeout(deadline);
    } on TimeoutException {
      _handleReceiptOcrDeadlineExceeded();
      return;
    } catch (_) {
      _handleReceiptOcrReadFailure();
      return;
    }
    final failureDiagnostic = ocr.hasText
        ? null
        : ExpenseOcrFailureDiagnostics.fromOcrResult(ocr);
    if (!mounted) return;
    final handoff = ReceiptOcrHandoff.forUserSelection(
      ocr: ocr,
      selectedCategory: widget.initialCategory,
      inventoryRequested: _isMaterialsFlow || _trackMaterialsInInventory,
    );
    PreparedExpenseReceiptOcrReview? preparedExpenseReview;
    final handoffRouter = _receiptOcrHandoffRouter(
      capability,
      onExpensePrepared: (prepared) => preparedExpenseReview = prepared,
    );
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
        'receiptOcrHandoffDestination': handoff.destination.name,
        'receiptOcrHandoffConsumer':
            handoffRouter.hasDedicatedHandlerFor(handoff.destination)
            ? 'dedicated'
            : 'expense_review_fallback',
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
      // Keep the progress surface active after text extraction. The downstream
      // receipt-detail handoff is still running, and showing empty review
      // fields here makes a healthy handoff look stalled or incomplete.
      if (!ocr.hasText) _scanningReceiptPhotos = false;
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
    _updateReceiptState(() {
      _receiptReadHandoffStage = 'Preparing editable receipt details';
    });
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.parserStarted,
      metadata: {
        'source': _receiptPrivacyFeatureArea,
        'parserDepth': capability.parserDepth.name,
        'localParserScope': capability.cloudAssistPlan.localParserScopeCode,
      },
    );
    final remaining = deadline - stopwatch.elapsed;
    if (remaining <= Duration.zero) {
      _handleReceiptParseFailure(
        failureKind: 'receipt_handoff_deadline_exceeded',
        evidence: 'ocr_completed_without_time_remaining_for_downstream_handoff',
        userMessage:
            'Receipt text was found, but preparing the editable details took too long. Continue manually or retry the receipt photo.',
      );
      return;
    }
    late ExpenseReceiptParseResult parsed;
    try {
      parsed = _withReceiptBrainHandoffDiagnostics(
        await handoffRouter.dispatch(handoff).timeout(remaining),
      );
      parsed = fillMissingExpenseReceiptFieldsFromOcrCandidates(
        parsed,
        ocr.layout,
      );
    } on TimeoutException {
      _handleReceiptParseFailure(
        failureKind: 'receipt_handoff_deadline_exceeded',
        evidence: 'downstream_receipt_handoff_exceeded_device_deadline',
        userMessage:
            'Receipt text was found, but preparing the editable details took too long. Continue manually or retry the receipt photo.',
      );
      return;
    } catch (_) {
      _handleReceiptParseFailure(
        failureKind: 'receipt_handoff_failed',
        evidence: 'downstream_receipt_handoff_threw_exception',
        userMessage:
            'Receipt text was found, but the editable details could not be prepared. Continue manually or retry the receipt photo.',
      );
      return;
    }
    unawaited(_recordPrivacySafeParseEvent(parsed));
    _recordParserTelemetry(parsed);
    if (!mounted) return;
    final preparedDiagnostics = preparedExpenseReview?.ocrDiagnostics;
    final preparedWarnings = preparedExpenseReview?.ocrWarnings;
    _updateReceiptState(() {
      // The generic receipt handoff does not always create a separate
      // prepared-review diagnostic. Keep ML Kit's completed read evidence in
      // that case so the review screen never calls a successful read
      // "not measured."
      _lastOcrDiagnostics = preparedDiagnostics ?? ocr.diagnostics;
      _lastOcrWarnings = preparedWarnings ?? ocr.structuredWarnings;
    });
    try {
      _applyParsedReceipt(parsed);
    } catch (_) {
      _handleReceiptParseFailure(
        failureKind: 'receipt_review_apply_failed',
        evidence: 'receipt_ocr_result_could_not_apply_to_editable_review',
        userMessage:
            'Receipt text was found, but editable receipt details could not open. Continue manually or retry the receipt photo.',
      );
      return;
    }
    _updateReceiptState(() => _scanningReceiptPhotos = false);
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

  ReceiptOcrHandoffRouter<ExpenseReceiptParseResult> _receiptOcrHandoffRouter(
    ReceiptDeviceCapability capability, {
    String? traceId,
    required ValueChanged<PreparedExpenseReceiptOcrReview> onExpensePrepared,
  }) {
    return ReceiptOcrHandoffRouter(
      expenseReview: (handoff) async {
        final prepared = await prepareGenericExpenseReceiptOcrReviewInWorker(
          handoff.ocr,
          fallbackDate: _selectedDate,
          capability: capability,
          traceId: traceId,
        );
        onExpensePrepared(prepared);
        return prepared.parsed;
      },
      fuel: widget.fuelOcrHandoff,
      inventory: widget.inventoryOcrHandoff,
    );
  }

  void _handleReceiptOcrDeadlineExceeded() {
    if (!mounted) return;
    _updateReceiptState(() {
      _scanningReceiptPhotos = false;
      _receiptReadAttemptedWithoutText = true;
      _receiptReadHandoffStage = 'Receipt text needs manual review';
      _receiptReadHandoffDecision = 'Open manual receipt details';
      _receiptReadHandoffAction =
          'Receipt reading took too long on this device. Add a clearer photo or enter the receipt manually.';
      _receiptReadHandoffRouteResult = _receiptManualDetailsRouteResultLabel;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Receipt reading took too long. Add a clearer photo or continue manually.',
        ),
      ),
    );
  }

  void _handleReceiptOcrReadFailure() {
    if (!mounted) return;
    _updateReceiptState(() {
      _scanningReceiptPhotos = false;
      _receiptReadAttemptedWithoutText = true;
      _receiptReadHandoffStage = 'Receipt text needs manual review';
      _receiptReadHandoffDecision = 'Open manual receipt details';
      _receiptReadHandoffAction =
          'The receipt could not be read. Add a clearer photo or enter the receipt manually.';
      _receiptReadHandoffRouteResult = _receiptManualDetailsRouteResultLabel;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The receipt could not be read. Add a clearer photo or continue manually.',
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
