part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryParseApplyActions
    on _ExpenseReceiptEntryScreenState {
  void _applyParsedReceipt(ExpenseReceiptParseResult parsed) {
    if (!parsed.hasUsableData) {
      _applyUnusableParsedReceipt(parsed);
      return;
    }
    final mergedParsedLines = _mergeParsedReceiptLines(parsed);
    _updateReceiptState(() {
      _applyingParsedFieldValues = true;
      _rawReceiptText = parsed.sourceText;
      _receiptReviewFlowStarted = true;
      _receiptReadAttemptedWithoutText = false;
      _lastReceiptParseCompleted = true;
      _lastReceiptParseHadUsableData = true;
      _lastReceiptParseHadSafeLines = parsed.lines.isNotEmpty;
      _receiptClassification = ExpenseReceiptClassifier.classifyText(
        parsed.sourceText,
      );
      _lastParseQuality = parsed.quality;
      _lastParseDiagnostics = parsed.diagnostics;
      _lastFieldConfidences = parsed.fieldConfidences;
      _maintenanceHints
        ..clear()
        ..addAll(parsed.maintenanceHints);
      _applyDefaultReviewModeForParsedReceipt(parsed);
      if (_usesRebuiltManualDetailedReceiptFlow) {
        // OCR has produced editable values. This is a forward handoff into
        // Review, never a return to the generic Add Receipt surface.
        _manualReceiptStep = _ManualReceiptStep.review;
      }
      final parsedMerchant = (parsed.merchantName ?? '').trim();
      if (_shouldApplyParsedMerchantValue(parsedMerchant)) {
        _storeController.text = parsedMerchant;
        _lastParsedMerchantValue = parsedMerchant;
      }
      final parsedDate = parsed.receiptDate;
      if (parsedDate != null && _shouldApplyParsedDateValue()) {
        _selectedDate = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
        );
      }
      final parsedTime = parsed.receiptTimeMinutes;
      if (parsedTime != null && _shouldApplyParsedTimeValue()) {
        _selectedTime = TimeOfDay(
          hour: parsedTime ~/ 60,
          minute: parsedTime % 60,
        );
      }
      if (parsed.enteredSubtotal != null) {
        final subtotalText = _moneyInputText(parsed.enteredSubtotal);
        if (_shouldApplyParsedSubtotalValue(subtotalText)) {
          _receiptSubtotalController.text = subtotalText;
          _lastParsedSubtotalValue = subtotalText;
        }
      }
      if (parsed.enteredTax != null) {
        final taxText = _moneyInputText(parsed.enteredTax);
        if (_shouldApplyParsedTaxValue(taxText)) {
          _salesTaxController.text = taxText;
          _lastParsedTaxValue = taxText;
        }
      }
      if (parsed.enteredTotal != null) {
        final totalText = _moneyInputText(parsed.enteredTotal);
        if (_shouldApplyParsedTotalValue(totalText)) {
          _receiptTotalController.text = totalText;
          _lastParsedTotalValue = totalText;
        }
      }
      _removeAppAssistedReceiptLines();
      if (_detailEntryMode == _ReceiptDetailEntryMode.detailedItems) {
        for (final line in mergedParsedLines) {
          _lines.add(_ExpenseReceiptLine.fromLedgerLine(line));
        }
      }
      _receiptReadHandoffDecision = _receiptDecisionLabelForParsedReceipt(
        parsed,
      );
      _receiptReadHandoffAction = _receiptActionLabelForParsedReceipt(parsed);
      _receiptReadHandoffStage = _receiptStageLabelForParsedReceipt(parsed);
      _receiptReadHandoffRouteResult =
          _receiptDetailsRouteResultForParsedReceipt(parsed);
      _applyingParsedFieldValues = false;
    });
    _scheduleDraftSave();
    _scrollToReceiptReview();
    _openAppAssistedReceiptPreviewIfReady();
    final warning = _primaryParsedReceiptWarning(parsed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          warning == null
              ? 'Receipt fields filled. Classify it as Business, Personal, or Split, then review the lines before saving.'
              : '$warning Classify the receipt and review every filled line before saving.',
        ),
      ),
    );
  }

  void _openAppAssistedReceiptPreviewIfReady() {
    if (!_usesRebuiltManualDetailedReceiptFlow ||
        !_appAssistedReceiptFillEnabled ||
        _appAssistedReceiptPreviewPresented ||
        !mounted ||
        (_lines.isEmpty &&
            (_enteredReceiptTotal == null || _enteredReceiptTotal! <= 0))) {
      return;
    }
    _appAssistedReceiptPreviewPresented = true;
    _setReceiptEntryState(() => _manualReceiptStep = _ManualReceiptStep.review);
  }

  List<ExpenseReceiptLineRecord> _mergeParsedReceiptLines(
    ExpenseReceiptParseResult parsed,
  ) {
    final parsedLines = <ExpenseReceiptLineRecord>[];
    for (var index = 0; index < parsed.lines.length; index++) {
      final line = _lineFromParsedReceipt(
        parsed.lines[index],
        review: index < parsed.lineReviews.length
            ? parsed.lineReviews[index]
            : null,
      );
      parsedLines.add(line.toLedgerLine(id: line.id));
    }
    final existingAppAssistedLines = _lines
        .where((line) => line.cameFromAppAssistedReceiptRead)
        .map((line) => line.toLedgerLine(id: line.id))
        .toList(growable: false);
    return mergeParsedReceiptLinesWithReviewedLines(
      parsedLines: parsedLines,
      existingLines: existingAppAssistedLines,
    );
  }

  bool _shouldApplyParsedMerchantValue(String parsedMerchant) {
    if (parsedMerchant.isEmpty) return false;
    return !_merchantValueLockedByUser || _storeController.text.trim().isEmpty;
  }

  bool _shouldApplyParsedDateValue() {
    return !_receiptDateLockedByUser;
  }

  bool _shouldApplyParsedTimeValue() {
    return !_receiptTimeLockedByUser || _selectedTime == null;
  }

  bool _shouldApplyParsedSubtotalValue(String subtotalText) {
    return !_receiptSubtotalLockedByUser ||
        _receiptSubtotalController.text.trim().isEmpty;
  }

  bool _shouldApplyParsedTaxValue(String taxText) {
    return !_receiptTaxLockedByUser || _salesTaxController.text.trim().isEmpty;
  }

  bool _shouldApplyParsedTotalValue(String totalText) {
    return !_receiptTotalLockedByUser ||
        _receiptTotalController.text.trim().isEmpty;
  }

  void _applyUnusableParsedReceipt(ExpenseReceiptParseResult parsed) {
    _updateReceiptState(() {
      _rawReceiptText = parsed.sourceText;
      _receiptReviewFlowStarted = true;
      _receiptReadAttemptedWithoutText = true;
      _lastReceiptParseCompleted = true;
      _lastReceiptParseHadUsableData = false;
      _lastReceiptParseHadSafeLines = false;
      _receiptClassification = ExpenseReceiptClassifier.classifyText(
        parsed.sourceText,
      );
      _lastParseQuality = parsed.quality;
      _lastParseDiagnostics = parsed.diagnostics;
      _lastFieldConfidences = parsed.fieldConfidences;
      _maintenanceHints
        ..clear()
        ..addAll(parsed.maintenanceHints);
      _applyDefaultReviewModeForParsedReceipt(parsed);
      _removeAppAssistedReceiptLines();
      _receiptReadHandoffDecision =
          parsed.diagnostics.hasOcrSourceMissingBottomCoverageEvidence
          ? 'Add bottom receipt section'
          : 'Open manual receipt details';
      _receiptReadHandoffAction = _receiptActionLabelForParsedReceipt(parsed);
      _receiptReadHandoffStage = _receiptStageLabelForParsedReceipt(parsed);
      _receiptReadHandoffRouteResult = parsed.sourceText.trim().isEmpty
          ? _receiptUnreadableDetailsRouteResultLabel
          : _receiptDetailsRouteResultForParsedReceipt(parsed);
    });
    _scheduleDraftSave();
    _scrollToReceiptReview();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Receipt was read, but the app could not find usable fields. Keep the image and fill in the receipt manually.',
        ),
      ),
    );
  }

  void _applyDefaultReviewModeForParsedReceipt(
    ExpenseReceiptParseResult parsed,
  ) {
    if (_receiptReviewModeChangedByUser ||
        _detailEntryMode == _ReceiptDetailEntryMode.detailedItems) {
      return;
    }
    final diagnostics = parsed.diagnostics;
    final shouldUseDetailedReview =
        widget.mode != ExpenseReceiptFlowMode.general ||
        diagnostics.hasOcrInventoryPrepSignals ||
        diagnostics.materialLineCount > 0 ||
        parsed.maintenanceHints.isNotEmpty ||
        parsed.lines.isNotEmpty;
    if (shouldUseDetailedReview) {
      _detailEntryMode = _ReceiptDetailEntryMode.detailedItems;
    }
  }

  void _removeAppAssistedReceiptLines() {
    _lines.removeWhere((line) => line.cameFromAppAssistedReceiptRead);
  }

  String? _primaryParsedReceiptWarning(ExpenseReceiptParseResult parsed) {
    final warnings = parsed.warnings
        .map((warning) => warning.trim())
        .where((warning) => warning.isNotEmpty)
        .toList(growable: false);
    if (warnings.isEmpty) return null;
    final blocking = warnings.where((warning) {
      final lower = warning.toLowerCase();
      return lower.contains('missing') ||
          lower.contains('could not') ||
          lower.contains('failed') ||
          lower.contains('low confidence') ||
          lower.contains('mismatch');
    });
    if (blocking.isNotEmpty) return blocking.first;
    return warnings.first;
  }

  _ExpenseReceiptLine _lineFromParsedReceipt(
    ExpenseReceiptLineRecord line, {
    ExpenseReceiptLineReview? review,
  }) {
    return _ExpenseReceiptLine(
      description: line.receiptDisplayText,
      category: _selectedCategoryForParsedReceiptLine(),
      // Parser ownership signals are compatibility evidence for downstream
      // parsers only. The editable Expense record starts unclassified until
      // the user chooses Business, Personal, or Split.
      use: _ExpenseLineUse.unclassified,
      quantity: line.quantity,
      unitsPerPackage: line.unitsPerPackage,
      stockUnit: line.unit,
      subtotal: line.subtotal,
      // A text-reading or downstream interpretation result must never become
      // an ownership allocation. Leave this unset until the user chooses it.
      businessPercent: null,
      odometerReading: line.odometerReading,
      fuelType: line.fuelType,
      fillType: line.fillType,
      unitPrice: line.unitPrice,
      rawReceiptText: line.rawReceiptText,
      sourceReceiptText: line.receiptSourceText,
      normalizedReceiptText: line.normalizedReceiptText,
      receiptInterpretation: line.receiptInterpretation,
      catalogItemId: line.catalogItemId,
      catalogItemName: line.catalogItemName,
      catalogItemPath: line.catalogItemPath,
      catalogMatchConfidence: line.catalogMatchConfidence,
      catalogMatchedTerms: line.catalogMatchedTerms,
      parserConfidence: review?.confidence ?? line.parserConfidence,
      parserReviewLabel: 'Needs classification',
      parserReviewReason:
          'The app read this line but cannot decide whether it is business, personal, or split.',
      parserNeedsReview: true,
      ocrSourceLineId: line.ocrSourceLineId,
      ocrSourceLineNumber: line.ocrSourceLineNumber,
      ocrSourceSectionNumber: line.ocrSourceSectionNumber,
      ocrSourceSectionLineNumber: line.ocrSourceSectionLineNumber,
      parserExpenseFamily: line.parserExpenseFamily,
      parserHint: line.parserHint,
    );
  }

  String _selectedCategoryForParsedReceiptLine() {
    if (!_receiptCategoryAppliesToAll) return 'Uncategorized';
    final selected = _receiptCategory.trim();
    return selected.isEmpty ? 'Uncategorized' : selected;
  }
}
