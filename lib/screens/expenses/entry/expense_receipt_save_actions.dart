part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptSaveActions on _ExpenseReceiptEntryScreenState {
  Future<void> _saveReceipt() async {
    if (_lines.isEmpty) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.validationError,
        validationErrorKind: 'missing_receipt_lines',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.lineReview,
          failedAt: 'before_receipt_save',
          confirmedCause: 'missing_receipt_lines',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'receipt_line_count_zero',
          missingEvidence: 'none',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one receipt line first.')),
      );
      return;
    }
    final readinessIssues = _receiptSaveReadinessIssues();
    if (readinessIssues.isNotEmpty) {
      final shouldSave = await _showReceiptSaveReadinessDialog(readinessIssues);
      if (!mounted) return;
      if (!shouldSave) {
        _scrollToReceiptReview();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Review the filled receipt lines, then save when everything looks right.',
            ),
          ),
        );
        if (_isEditingReceipt) return;
        final issueKinds = readinessIssues.map((issue) => issue.kind).join(',');
        ExpenseScreenTelemetryRecorder.record(
          context,
          ExpenseTelemetryEventType.addExpenseAbandoned,
          diagnostic: ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.lineReview,
            failedAt: 'receipt_save_readiness_dialog',
            confirmedCause: 'user_left_receipt_save_readiness',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: issueKinds,
            missingEvidence: 'none',
            abandoned: true,
          ),
          metadata: {
            'entryMode': _detailEntryMode.name,
            'source': _receiptPrivacyFeatureArea,
          },
        );
        return;
      }
    }
    final ledger = ExpenseLedgerScope.of(context);
    var receipt = _buildReceiptForSave();
    final duplicateCheck = ledger.checkDuplicatesFor(receipt);
    receipt = receipt.copyWith(
      fileHashSha256: duplicateCheck.fileHashSha256,
      duplicateCheckStatus: duplicateCheck.status,
      duplicateCandidates: duplicateCheck.candidates,
      duplicateCheckedAt: duplicateCheck.checkedAt,
    );
    while (duplicateCheck.hasCandidates) {
      final choice = await _showDuplicateReceiptDialog(duplicateCheck);
      if (choice == null || choice.shouldKeepEditingCurrent) return;
      if (choice.shouldViewExistingFirst) {
        await _showExistingDuplicateReceipt(duplicateCheck.candidates.first);
        if (!mounted) return;
        continue;
      }
      receipt = receipt.copyWith(
        duplicateOverride: true,
        duplicateOverrideReason: choice.overrideReason.trim(),
        duplicateCheckStatus: ExpenseDuplicateCheckStatus.overrideSaved,
      );
      break;
    }
    final promotedAttachments = await _persistReceiptProofs(receipt);
    if (promotedAttachments == null) return;
    if (!mounted) return;
    receipt = receipt.copyWith(
      attachments: List.unmodifiable(promotedAttachments),
      hasReceiptProof:
          promotedAttachments.isNotEmpty || receipt.hasReceiptProof,
    );
    _updateReceiptState(() {
      _receiptAttachments
        ..clear()
        ..addAll(promotedAttachments);
      _hasReceipt = promotedAttachments.isNotEmpty || _hasReceipt;
    });
    final saved = await _saveReceiptToLedger(ledger, receipt);
    if (saved == null) return;
    await _syncMaterialsReceipt(saved);
    if (!mounted) return;
    _savedReceipt = true;
    _telemetryAddFlowFinished = true;
    ExpenseScreenTelemetryRecorder.record(
      context,
      _isEditingReceipt
          ? ExpenseTelemetryEventType.editExpenseSaved
          : ExpenseTelemetryEventType.addExpenseCompleted,
      metadata: {
        'entryMode': _detailEntryMode.name,
        'source': _receiptPrivacyFeatureArea,
      },
    );
    if (!_isEditingReceipt) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.receiptExpenseCreated,
        categoryGroup: saved.lines.isEmpty ? null : saved.lines.first.category,
        metadata: {'saveDestination': 'local_first'},
      );
    }
    await _drafts?.deleteDraft(_draftId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  List<_ReceiptSaveReadinessIssue> _receiptSaveReadinessIssues() {
    final issues = <_ReceiptSaveReadinessIssue>[];
    final unreviewedCount = _unreviewedParsedLineCount;
    if (unreviewedCount > 0) {
      issues.add(
        _ReceiptSaveReadinessIssue(
          kind: 'unreviewed_app_filled_lines',
          title: 'App-filled lines still need review',
          detail: unreviewedCount == 1
              ? 'One receipt line was filled by the app and has not been confirmed or corrected yet.'
              : '$unreviewedCount receipt lines were filled by the app and have not been confirmed or corrected yet.',
        ),
      );
    }

    final splitPercentMissingCount = _splitLinesMissingBusinessPercentCount;
    if (splitPercentMissingCount > 0) {
      issues.add(
        _ReceiptSaveReadinessIssue(
          kind: 'mixed_receipt_split_percent_missing',
          title: 'Mixed receipt split needs a percent',
          detail: splitPercentMissingCount == 1
              ? 'One mixed receipt line still needs a business percent before the app can split business and personal totals cleanly.'
              : '$splitPercentMissingCount mixed receipt lines still need business percents before the app can split business and personal totals cleanly.',
        ),
      );
    }

    final ocrDiagnostics = _lastOcrDiagnostics;
    if (ocrDiagnostics != null) {
      if (!ocrDiagnostics.hasText) {
        issues.add(
          const _ReceiptSaveReadinessIssue(
            kind: 'receipt_ocr_no_readable_text',
            title: 'No readable receipt text was found',
            detail:
                'The receipt proof can still be saved, but the app could not fill the receipt from OCR.',
          ),
        );
      } else if (ocrDiagnostics.hasBlockingWarnings) {
        issues.add(
          _ReceiptSaveReadinessIssue(
            kind: 'receipt_ocr_blocking_warnings',
            title: 'Receipt reading needs attention',
            detail: _primaryOcrWarningMessage(
              fallback:
                  'The receipt was attached, but at least one source could not be read safely.',
            ),
          ),
        );
      } else if (ocrDiagnostics.hasPartialWarnings) {
        issues.add(
          _ReceiptSaveReadinessIssue(
            kind: 'receipt_ocr_partial_read',
            title: 'Only part of the receipt was read',
            detail: _primaryOcrWarningMessage(
              fallback:
                  'Some receipt proof was saved without being used for app-assisted filling.',
            ),
          ),
        );
      } else if (ocrDiagnostics.hasReviewWarnings) {
        issues.add(
          _ReceiptSaveReadinessIssue(
            kind: 'receipt_ocr_review_warnings',
            title: 'Receipt reading should be checked',
            detail: _primaryOcrWarningMessage(
              fallback:
                  'The app found receipt text, but it flagged something worth reviewing before save.',
            ),
          ),
        );
      }
    }

    final subtotalIssue = _receiptSubtotalReadinessIssue();
    if (subtotalIssue != null) issues.add(subtotalIssue);

    return issues;
  }

  int get _splitLinesMissingBusinessPercentCount {
    return _lines
        .where(
          (line) =>
              line.use == _ExpenseLineUse.split &&
              (line.businessPercent == null ||
                  line.businessPercent! <= 0 ||
                  line.businessPercent! >= 1),
        )
        .length;
  }

  _ReceiptSaveReadinessIssue? _receiptSubtotalReadinessIssue() {
    final enteredSubtotal = _enteredReceiptSubtotal;
    if (enteredSubtotal == null || _lines.isEmpty) return null;
    final delta = enteredSubtotal - _lineSubtotal;
    if (delta.abs() < .02) return null;
    return _ReceiptSaveReadinessIssue(
      kind: 'receipt_subtotal_line_mismatch',
      title: 'Receipt subtotal does not match the lines',
      detail:
          'Line subtotal is ${_money(_lineSubtotal)}, but the receipt subtotal is ${_money(enteredSubtotal)}. Check for missing items, discounts, fees, or returns.',
    );
  }

  String _primaryOcrWarningMessage({required String fallback}) {
    if (_lastOcrWarnings.isEmpty) return fallback;
    final prioritizedWarnings = _lastOcrWarnings.toList(growable: false)
      ..sort(ReceiptOcrWarning.compareByPriority);
    final warning = prioritizedWarnings.first;
    final extraWarningCount = prioritizedWarnings.length - 1;
    final parts = <String>[
      warning.reviewMessage,
      if (warning.reviewInstruction.isNotEmpty) warning.reviewInstruction,
      '${warning.reviewTargetLabel}.',
      warning.reviewTargetInstruction,
      if (extraWarningCount > 0)
        '$extraWarningCount more OCR ${extraWarningCount == 1 ? 'warning also needs' : 'warnings also need'} review.',
    ];
    return parts.where((part) => part.trim().isNotEmpty).join(' ');
  }

  Future<bool> _showReceiptSaveReadinessDialog(
    List<_ReceiptSaveReadinessIssue> issues,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1F2528),
        title: const Text(
          'Review receipt before saving?',
          style: TextStyle(
            color: Color(0xFFE8ECEE),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Maintainiac found something that should be checked before this receipt is saved. You can review it now or save anyway if you already verified the receipt.',
                style: TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              for (final issue in issues.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFFFD166),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue.title,
                              style: const TextStyle(
                                color: Color(0xFFE8ECEE),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              issue.detail,
                              style: const TextStyle(
                                color: Color(0xFFAEB9BE),
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Review Receipt'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save Anyway'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  ExpenseReceiptRecord _buildReceiptForSave() {
    final editing = _editingReceipt;
    final activeVehicle = AppStateScope.of(context).activeVehicle;
    return ExpenseReceiptRecord(
      id: editing?.id ?? 'EXP-${DateTime.now().microsecondsSinceEpoch}',
      receiptDate: _selectedDate,
      receiptTimeMinutes: _selectedTime == null
          ? null
          : (_selectedTime!.hour * 60) + _selectedTime!.minute,
      merchantName: _storeController.text.trim(),
      phone: _phoneController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      zip: _zipController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      notes: _storeNotesController.text.trim(),
      hasReceiptProof: _hasReceipt || _receiptAttachments.isNotEmpty,
      attachments: List.unmodifiable(_receiptAttachments),
      rawOcrText: _rawReceiptText,
      ocrReview: _currentOcrReview(),
      enteredSubtotal: _enteredReceiptSubtotal,
      enteredTax: _enteredReceiptTax,
      enteredTotal: _enteredReceiptTotal,
      trackMaterialsInInventory: _trackMaterialsInInventory,
      vehicleId:
          editing?.vehicleId ??
          (activeVehicle == null
              ? null
              : odometerVehicleIdForLabel(activeVehicle.nickname)),
      sourceScreen:
          editing?.sourceScreen ??
          (_isMaterialsFlow
              ? 'materials_expense_receipt'
              : _isMaintenanceRepairFlow
              ? 'maintenance_repair_expense_receipt'
              : 'expenses'),
      createdAt: editing?.createdAt,
      updatedAt: editing?.updatedAt,
      auditEvents: editing?.auditEvents ?? const [],
      lines: [
        for (var index = 0; index < _lines.length; index++)
          _lines[index].toLedgerLine(
            id:
                _lines[index].id ??
                'EXPL-${DateTime.now().microsecondsSinceEpoch}-$index',
          ),
      ],
    );
  }

  Future<List<ReceiptAttachmentRecord>?> _persistReceiptProofs(
    ExpenseReceiptRecord receipt,
  ) async {
    try {
      return ReceiptProofStorage.instance.persistAttachments(
        receipt.attachments
            .map(
              (attachment) => attachment.copyWith(
                linkedModule: receipt.sourceScreen,
                linkedRecordId: receipt.id,
              ),
            )
            .toList(growable: false),
      );
    } on ReceiptProofStorageException catch (error) {
      if (!mounted) return null;
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.imageAttachFailure,
        failureKind: 'proof_storage',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptAttachment,
          failedAt: 'persist_receipt_proofs',
          confirmedCause: 'proof_storage',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'receipt_proof_storage_exception',
          missingEvidence: 'none',
        ),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return null;
    } catch (_) {
      if (!mounted) return null;
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.imageAttachFailure,
        failureKind: 'proof_storage_unknown',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptAttachment,
          failedAt: 'persist_receipt_proofs',
          confirmedCause: 'cause_not_confirmed_proof_storage_unknown',
          causeStatus: ExpenseFailureCauseStatus.notConfirmed,
          evidence: 'untyped_exception',
          missingEvidence: 'exception_type_and_storage_state',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That receipt proof could not be saved.')),
      );
      return null;
    }
  }

  Future<ExpenseReceiptRecord?> _saveReceiptToLedger(
    ExpenseLedgerController ledger,
    ExpenseReceiptRecord receipt,
  ) async {
    try {
      return ledger.saveReceipt(receipt);
    } catch (_) {
      if (!mounted) return null;
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.saveFailure,
        failureKind: 'ledger_save_failed',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.saveExpense,
          failedAt: 'ledger_save_receipt',
          confirmedCause: 'cause_not_confirmed_ledger_save_failed',
          causeStatus: ExpenseFailureCauseStatus.notConfirmed,
          evidence: 'ledger_save_threw_exception',
          missingEvidence: 'exception_type_and_hive_box_state',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That receipt could not be saved. Try again.'),
        ),
      );
      return null;
    }
  }

  Future<void> _syncMaterialsReceipt(ExpenseReceiptRecord saved) async {
    try {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.syncPending,
        metadata: {'syncState': 'materials_bridge'},
      );
      await (await ExpenseMaterialsReceiptBridge.create()).syncReceipt(saved);
      if (!mounted) return;
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.synced,
        metadata: {'syncState': 'materials_bridge'},
      );
    } catch (_) {
      if (!mounted) return;
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.syncFailed,
        failureKind: 'materials_bridge',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.materialsBridge,
          failedAt: 'after_expense_save_materials_sync',
          confirmedCause: 'cause_not_confirmed_materials_bridge',
          causeStatus: ExpenseFailureCauseStatus.notConfirmed,
          evidence: 'materials_bridge_sync_threw_exception',
          missingEvidence: 'exception_type_and_bridge_stage',
        ),
        metadata: {'syncState': 'materials_bridge'},
      );
    }
  }
}

class _ReceiptSaveReadinessIssue {
  const _ReceiptSaveReadinessIssue({
    required this.kind,
    required this.title,
    required this.detail,
  });

  final String kind;
  final String title;
  final String detail;
}
