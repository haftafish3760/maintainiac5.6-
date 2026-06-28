part of 'work_supply_add_items_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _WorkSupplyAddItemsReceiptParserActions
    on _WorkSupplyAddItemsScreenState {
  void _parseImportedMaterialsReceiptText(String text) {
    unawaited(_parseImportedMaterialsReceiptTextWithMemory(text));
  }

  Future<void> _parseImportedMaterialsReceiptTextWithMemory(String text) async {
    final sourceText = text.trim();
    if (sourceText.isEmpty || sourceText == _lastImportedReceiptText) return;
    final capability =
        ReceiptCaptureSettingsScope.maybeOf(context)?.deviceCapability ??
        const ReceiptDeviceCapability.standard();
    final parserProfile = WorkSupplyParserDeviceProfile.fromCapability(
      capability,
    );
    final parsed = await parseExpenseReceiptTextWithLocalMemory(
      sourceText,
      fallbackDate: _selectedDate,
      parserDepth: parserProfile.parserDepth,
      maxCatalogCandidates: parserProfile.maxCatalogCandidates,
    );
    unawaited(_recordMaterialsPrivacySafeParseEvent(parsed));
    if (!mounted) return;
    if (!parsed.hasUsableData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No usable receipt fields were found in that text.'),
        ),
      );
      return;
    }
    final inventoryStorageArea = _parsedReceiptInventoryStorageArea;
    final staged = buildWorkSupplyParsedReceiptDraft(
      parsed: parsed,
      receiptId: _intakeId,
      loggedAt: _loggedAt,
      storageArea: inventoryStorageArea,
      merchantName: (parsed.merchantName ?? _storeController.text).trim(),
      startingLineNumber: _lineSequence + 1,
      customCatalogItems: widget.customCatalogItems,
    );
    if (!staged.hasLines) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Receipt text was read, but no line items were ready to stage.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _lastImportedReceiptText = sourceText;
      _hasReceipt = true;
      final merchant = parsed.merchantName?.trim();
      if (merchant != null && merchant.isNotEmpty) {
        _storeController.text = merchant;
      }
      final parsedDate = parsed.receiptDate;
      if (parsedDate != null) {
        _selectedDate = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
        );
      }
      final parsedTime = parsed.receiptTimeMinutes;
      if (parsedTime != null) {
        _selectedTime = TimeOfDay(
          hour: parsedTime ~/ 60,
          minute: parsedTime % 60,
        );
      }
      if (_storageArea == _chooseInventoryDestinationLabel) {
        _storageArea = inventoryStorageArea;
      }
      _stagedReceiptLines.addAll(staged.lines);
      _stagedInventoryLines.addAll(staged.inventoryRecords);
      _lineSequence += staged.lines.length;
      _parsedReceiptReview = _ParsedMaterialsReceiptReviewSummary(
        qualityLabel: parsed.quality.label,
        confidenceLabel: parsed.quality.confidencePercentLabel,
        needsReview:
            parsed.quality.needsReview ||
            unconfirmedAssistedInventoryLineCount(staged.lines) > 0,
        warning: parsed.warnings.isEmpty ? null : parsed.warnings.first,
      );
    });
    final warning = parsed.warnings.isEmpty ? null : parsed.warnings.first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          warning == null
              ? _parsedReceiptStageMessage(staged)
              : '$warning ${_parsedReceiptStageMessage(staged)}',
        ),
      ),
    );
  }

  String get _parsedReceiptInventoryStorageArea {
    final resolved = _resolvedStorageArea.trim();
    if (resolved.isEmpty || resolved == _chooseInventoryDestinationLabel) {
      return workSupplyCompanyInventoryLabel;
    }
    return resolved;
  }

  Future<void> _recordMaterialsPrivacySafeParseEvent(
    ExpenseReceiptParseResult result,
  ) async {
    try {
      final store = await PrivacySafeReceiptEventStore.create();
      await store.enqueue(
        PrivacySafeReceiptEvent.fromParseResult(
          result: result,
          featureArea: 'materials_inventory',
        ),
      );
    } catch (_) {
      // Receipt diagnostics must never interrupt the inventory receipt flow.
    }
  }

  String _parsedReceiptStageMessage(WorkSupplyParsedReceiptDraft staged) {
    return [
      'Staged ${staged.lines.length} receipt line${staged.lines.length == 1 ? '' : 's'} for review.',
      if (staged.inventoryLineCount > 0)
        '${staged.inventoryLineCount} inventory',
      if (staged.businessOnlyLineCount > 0)
        '${staged.businessOnlyLineCount} business-only',
      if (staged.personalLineCount > 0) '${staged.personalLineCount} personal',
      if (staged.splitLineCount > 0) '${staged.splitLineCount} split',
    ].join(' ');
  }
}
