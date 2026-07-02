part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryCoreHelpers on _ExpenseReceiptEntryScreenState {
  bool get _isEditingReceipt => widget.receiptId != null;

  bool get _hasAppAssistedReceiptReview {
    return _receiptReviewFlowStarted ||
        _receiptClassification != null ||
        _lines.isNotEmpty ||
        _rawReceiptText.trim().isNotEmpty ||
        _receiptReadAttemptedWithoutText ||
        _lastParseQuality != null ||
        _lastParseDiagnostics != null ||
        _lastFieldConfidences.isNotEmpty ||
        _lastOcrDiagnostics != null ||
        _lastOcrWarnings.isNotEmpty;
  }

  bool get _shouldShowReceiptReadHandoffPanel {
    if (_scanningReceiptPhotos) return true;
    if (!_receiptReviewFlowStarted) return false;
    return _receiptReadHandoffProofCount > 0 ||
        _receiptReadHandoffOcrSourceCount > 0 ||
        _receiptReadHandoffDecision.trim().isNotEmpty ||
        _receiptReadHandoffAction.trim().isNotEmpty ||
        _receiptReadHandoffRouteResult.trim().isNotEmpty ||
        _receiptReadHandoffCoverageWarning.trim().isNotEmpty;
  }

  bool get _shouldShowCollapsedReceiptPhotoRecovery {
    return _receiptReviewFlowStarted &&
        !_scanningReceiptPhotos &&
        (_receiptReadAttemptedWithoutText ||
            _receiptReadHandoffCoverageWarning.trim().isNotEmpty ||
            (_lastOcrWarnings.isNotEmpty &&
                _lastOcrWarnings.any(
                  (warning) =>
                      warning.isBlocking ||
                      warning.isPartial ||
                      warning.needsReview,
                )));
  }

  int get _unreviewedParsedLineCount {
    return _lines.where((line) => line.parserNeedsReview).length;
  }

  ExpenseFailureDiagnostic get _abandonedReceiptEntryDiagnostic {
    if (_scanningReceiptPhotos) {
      return const ExpenseFailureDiagnostic(
        workflowStep: ExpenseWorkflowStep.receiptOcr,
        failedAt: 'receipt_ocr_in_progress',
        confirmedCause: 'user_left_during_receipt_ocr',
        causeStatus: ExpenseFailureCauseStatus.confirmed,
        evidence: 'ocr_scan_active_when_screen_closed',
        missingEvidence: 'none',
        abandoned: true,
      );
    }
    if (!_hasReceipt &&
        _receiptAttachments.isEmpty &&
        _rawReceiptText.isEmpty) {
      return const ExpenseFailureDiagnostic(
        workflowStep: ExpenseWorkflowStep.receiptAttachment,
        failedAt: 'before_receipt_attachment',
        confirmedCause: 'user_left_before_receipt_attachment',
        causeStatus: ExpenseFailureCauseStatus.confirmed,
        evidence: 'no_receipt_proof_or_imported_text',
        missingEvidence: 'none',
        abandoned: true,
      );
    }
    if (_lines.isEmpty) {
      return const ExpenseFailureDiagnostic(
        workflowStep: ExpenseWorkflowStep.lineReview,
        failedAt: 'before_first_receipt_line',
        confirmedCause: 'user_left_before_first_receipt_line',
        causeStatus: ExpenseFailureCauseStatus.confirmed,
        evidence: 'receipt_line_count_zero',
        missingEvidence: 'none',
        abandoned: true,
      );
    }
    if (_unreviewedParsedLineCount > 0) {
      return const ExpenseFailureDiagnostic(
        workflowStep: ExpenseWorkflowStep.lineReview,
        failedAt: 'unreviewed_parsed_lines',
        confirmedCause: 'user_left_with_unreviewed_parsed_lines',
        causeStatus: ExpenseFailureCauseStatus.confirmed,
        evidence: 'unreviewed_line_count_positive',
        missingEvidence: 'none',
        abandoned: true,
      );
    }
    return const ExpenseFailureDiagnostic(
      workflowStep: ExpenseWorkflowStep.saveExpense,
      failedAt: 'before_receipt_save',
      confirmedCause: 'user_left_before_receipt_save',
      causeStatus: ExpenseFailureCauseStatus.confirmed,
      evidence: 'receipt_lines_present_not_saved',
      missingEvidence: 'none',
      abandoned: true,
    );
  }

  bool get _isMaterialsFlow =>
      widget.mode == ExpenseReceiptFlowMode.materials ||
      _editingReceipt?.sourceScreen == 'materials_expense_receipt';

  bool get _isMaintenanceRepairFlow =>
      widget.mode == ExpenseReceiptFlowMode.maintenanceRepair ||
      _editingReceipt?.sourceScreen == 'maintenance_repair_expense_receipt';

  ReceiptCaptureArea get _receiptCaptureArea {
    if (_isMaterialsFlow) return ReceiptCaptureArea.materialsInventory;
    if (_isMaintenanceRepairFlow) return ReceiptCaptureArea.maintenanceRepair;
    return ReceiptCaptureArea.expenses;
  }

  void _updateReceiptState(VoidCallback update) {
    _setReceiptEntryState(update);
  }

  void _scrollToReceiptReview({int attempt = 0}) {
    _scrollToReceiptFlowKey(_receiptReviewKey, attempt: attempt);
  }

  void _scrollToReceiptCapture({int attempt = 0}) {
    _scrollToReceiptFlowKey(_receiptReadHandoffKey, attempt: attempt);
  }

  void _scrollToReceiptPhotoRecovery({int attempt = 0}) {
    _scrollToReceiptFlowKey(_receiptPhotoRecoveryKey, attempt: attempt);
  }

  void _addBusinessReceiptLineFromOcrAction() {
    unawaited(
      _addReceiptLineForMode(
        use: _ExpenseLineUse.business,
        category: widget.initialCategory ?? 'Uncategorized',
      ),
    );
  }

  void _useReceiptTotalAsBusinessFromOcrAction() {
    _addReceiptTotalLine(
      use: _ExpenseLineUse.business,
      category: widget.initialCategory ?? 'Uncategorized',
    );
  }

  Map<String, VoidCallback> get _ocrReviewActionCallbacks {
    void review() => _scrollToReceiptReview();
    void capture() => _scrollToReceiptCapture();
    final addLine = _addBusinessReceiptLineFromOcrAction;
    final useTotal = _useReceiptTotalAsBusinessFromOcrAction;
    return {
      'Review filled fields': review,
      'Classify Business/Personal/Mixed': review,
      'Check store name': review,
      'Edit if wrong': review,
      'Check receipt total': review,
      'Edit total': review,
      'Check subtotal': review,
      'Check tax': review,
      'Check total': review,
      'Review item lines': review,
      'Check material matches': review,
      'Review line prices': review,
      'Edit item lines': review,
      'Review receipt details': review,
      'Add line manually': addLine,
      'Enter manually': addLine,
      'Use receipt total': useTotal,
      'Retake/add photo': capture,
      'Check photo order': capture,
      'Add missing section': capture,
      'Retake section': capture,
      'Retake photo': capture,
      'Add clearer photo': capture,
    };
  }

  void _scrollToReceiptFlowKey(GlobalKey key, {int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reviewContext = key.currentContext;
      if (reviewContext == null) {
        if (attempt < 4) {
          Future<void>.delayed(const Duration(milliseconds: 80), () {
            if (mounted) _scrollToReceiptFlowKey(key, attempt: attempt + 1);
          });
        }
        return;
      }
      Scrollable.ensureVisible(
        reviewContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  void _markReceiptReadStarted() {
    if (!mounted || _scanningReceiptPhotos) return;
    _updateReceiptState(() {
      _scanningReceiptPhotos = true;
      _receiptReviewFlowStarted = true;
      _receiptReadAttemptedWithoutText = false;
      _receiptReadHandoffStage = 'Preparing receipt details';
      _lastReceiptParseCompleted = false;
      _lastReceiptParseHadUsableData = false;
      _lastReceiptParseHadSafeLines = false;
    });
    _scrollToReceiptCapture();
  }

  void _markReceiptPhotoReviewAccepted(ReceiptPhotoReviewResult result) {
    if (!mounted) return;
    final handoffWarnings = <String>[
      if (result.usedSavedProofAsOcrSourceFallback)
        'Receipt reader is using the saved proof copy because a clearer OCR source was not available. Review the filled lines carefully before saving.',
      if (result.hasPossiblePartialReceiptPhotos)
        'One receipt photo may be incomplete. Review the filled lines against the saved proof before saving.',
    ].join(' ');
    _updateReceiptState(() {
      _scanningReceiptPhotos = true;
      _receiptReviewFlowStarted = true;
      _receiptReadAttemptedWithoutText = false;
      _receiptReadHandoffProofCount = result.photoPaths.length;
      _receiptReadHandoffOcrSourceCount = result.ocrSourcePhotoPaths.length;
      _receiptReadHandoffDecision = result.nextReviewHandoffLabel;
      _receiptReadHandoffAction = result.acceptedPhotoHandoffActionLabel;
      _receiptReadHandoffRouteResult =
          result.acceptedPhotoHandoffRouteResultLabel;
      _receiptReadHandoffStage = 'Opening receipt details from accepted photo';
      _receiptReadHandoffCoverageWarning = handoffWarnings;
      _receiptBrainLowStorageDownloadRiskCounts =
          result.receiptBrainLowStorageDownloadRiskCounts;
      _receiptBrainFullOfflineMustStayOptionalCounts =
          result.receiptBrainFullOfflineMustStayOptionalCounts;
      _receiptBrainFullOfflineExceedsBaseGuardrailCounts =
          result.receiptBrainFullOfflineExceedsBaseGuardrailCounts;
      _receiptInstallRequiredSegmentCounts =
          result.receiptInstallRequiredSegmentCounts;
      _receiptInstallFullOfflineSegmentCounts =
          result.receiptInstallFullOfflineSegmentCounts;
      _receiptInstallLowStorageImpactCounts =
          result.receiptInstallLowStorageImpactCounts;
      _receiptInstallRecommendedDistributionCounts =
          result.receiptInstallRecommendedDistributionCounts;
      _receiptInstallCameraShellParserFreeCounts =
          result.receiptInstallCameraShellParserFreeCounts;
      _receiptInstallBaseUsefulOnTinyPhonesCounts =
          result.receiptInstallBaseUsefulOnTinyPhonesCounts;
      _receiptInstallOptionalPacksRequireConsentCounts =
          result.receiptInstallOptionalPacksRequireConsentCounts;
    });
    _scheduleDraftSave();
    _recordReceiptPhotoPreparationTelemetry(result);
    _scrollToReceiptCapture();
  }
}
