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
    final invalidSplitCount = _splitLinesMissingBusinessPercentCount;
    if (invalidSplitCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            invalidSplitCount == 1
                ? 'Confirm the business allocation for the split line before saving.'
                : 'Confirm the business allocation for all $invalidSplitCount split lines before saving.',
          ),
        ),
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
    try {
      await ledger.ensureStorageForLocalSave();
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      return;
    }
    var receipt = _buildReceiptForSave();
    final odometerCommit = await _prepareReceiptOdometerCommit(receipt);
    if (!mounted || odometerCommit == null) return;
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
    final stagedRecoveryAttachments = receipt.attachments
        .where(
          (attachment) =>
              attachment.storageState == ReceiptAttachmentStorageState.staged,
        )
        .toList(growable: false);
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
    if (!await _saveDraftNow()) return;
    final draftCheckpointUpdatedAt = _drafts?.draftById(_draftId)?.updatedAt;
    await ReceiptProofStorage.instance.deleteStagedAttachments(
      stagedRecoveryAttachments,
    );
    final saved = await _saveReceiptToLedger(ledger, receipt);
    if (saved == null) return;
    if (!mounted) return;
    final odometerResult = odometerCommit.commit();
    if (!odometerResult.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            odometerResult.message ??
                'The receipt saved, but its odometer history needs review.',
          ),
        ),
      );
    }
    final cloudBackup = ExpenseCloudBackupScope.maybeOf(context);
    if (cloudBackup != null) {
      unawaited(cloudBackup.queueReceipt(saved.id));
    }
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
    if (draftCheckpointUpdatedAt != null) {
      await _drafts?.deleteDraftIfUnchanged(
        _draftId,
        expectedUpdatedAt: draftCheckpointUpdatedAt,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  ExpenseReceiptRecord _buildReceiptForSave() {
    final editing = _editingReceipt;
    final activeVehicle = AppStateScope.of(context).activeVehicle;
    final activeWorkProfile = ExpenseWorkProfileScope.of(
      context,
    ).activeWorkProfile;
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
              : odometerVehicleIdForVehicleId(
                  activeVehicle.id,
                  fallbackLabel: activeVehicle.nickname,
                )),
      workProfileId: editing?.workProfileId ?? activeWorkProfile.id,
      contextSnapshot: editing?.contextSnapshot ?? _expenseContext,
      odometerReading: _expenseOdometerReading,
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
        retainStagedSources: true,
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
    } catch (error) {
      if (!mounted) return null;
      final storageMessage = error is StateError
          ? error.message.toString()
          : null;
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.saveFailure,
        failureKind: 'ledger_save_failed',
        diagnostic: ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.saveExpense,
          failedAt: 'ledger_save_receipt',
          confirmedCause: storageMessage == null
              ? 'cause_not_confirmed_ledger_save_failed'
              : 'device_storage_insufficient',
          causeStatus: storageMessage == null
              ? ExpenseFailureCauseStatus.notConfirmed
              : ExpenseFailureCauseStatus.confirmed,
          evidence: storageMessage == null
              ? 'ledger_save_threw_exception'
              : 'storage_guard_blocked_local_record_save',
          missingEvidence: storageMessage == null
              ? 'exception_type_and_hive_box_state'
              : 'none',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            storageMessage ?? 'That receipt could not be saved. Try again.',
          ),
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
