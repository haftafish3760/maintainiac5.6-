part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptSaveActions on _ExpenseReceiptEntryScreenState {
  Future<void> _saveReceipt() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one receipt line first.')),
      );
      return;
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
    _savedReceipt = true;
    await _drafts?.deleteDraft(_draftId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  ExpenseReceiptRecord _buildReceiptForSave() {
    final editing = _editingReceipt;
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
      enteredSubtotal: _enteredReceiptSubtotal,
      enteredTax: _enteredReceiptTax,
      enteredTotal: _enteredReceiptTotal,
      trackMaterialsInInventory: _trackMaterialsInInventory,
      vehicleId: editing?.vehicleId,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return null;
    } catch (_) {
      if (!mounted) return null;
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
      await (await ExpenseMaterialsReceiptBridge.create()).syncReceipt(saved);
    } catch (_) {}
  }
}
