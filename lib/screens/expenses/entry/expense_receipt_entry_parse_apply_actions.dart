part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryParseApplyActions
    on _ExpenseReceiptEntryScreenState {
  void _applyParsedReceipt(ExpenseReceiptParseResult parsed) {
    if (!parsed.hasUsableData) {
      _applyUnusableParsedReceipt(parsed);
      return;
    }
    _updateReceiptState(() {
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
      if ((parsed.merchantName ?? '').trim().isNotEmpty) {
        _storeController.text = parsed.merchantName!.trim();
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
      if (parsed.enteredSubtotal != null) {
        _receiptSubtotalController.text = _moneyInputText(
          parsed.enteredSubtotal,
        );
      }
      if (parsed.enteredTax != null) {
        _salesTaxController.text = _moneyInputText(parsed.enteredTax);
      }
      if (parsed.enteredTotal != null) {
        _receiptTotalController.text = _moneyInputText(parsed.enteredTotal);
      }
      _removeAppAssistedReceiptLines();
      for (var index = 0; index < parsed.lines.length; index++) {
        _lines.add(
          _lineFromParsedReceipt(
            parsed.lines[index],
            review: index < parsed.lineReviews.length
                ? parsed.lineReviews[index]
                : null,
          ),
        );
      }
      _receiptReadHandoffDecision = _receiptDecisionLabelForParsedReceipt(
        parsed,
      );
      _receiptReadHandoffAction = _receiptActionLabelForParsedReceipt(parsed);
      _receiptReadHandoffStage = _receiptStageLabelForParsedReceipt(parsed);
      _receiptReadHandoffRouteResult =
          _receiptDetailsRouteResultForParsedReceipt(parsed);
    });
    _scheduleDraftSave();
    _scrollToReceiptReview();
    final warning = _primaryParsedReceiptWarning(parsed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          warning == null
              ? 'Receipt fields filled. Classify it as Business, Personal, or Mixed, then review the lines before saving.'
              : '$warning Classify the receipt and review every filled line before saving.',
        ),
      ),
    );
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
          'Receipt was read, but the app could not find usable fields. Keep the proof and fill in the receipt manually.',
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
        parsed.maintenanceHints.isNotEmpty;
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
      description: line.description,
      category: line.category,
      use: switch (line.use) {
        ExpenseLineUse.business => _ExpenseLineUse.business,
        ExpenseLineUse.personal => _ExpenseLineUse.personal,
        ExpenseLineUse.split => _ExpenseLineUse.split,
      },
      quantity: line.quantity,
      unitsPerPackage: line.unitsPerPackage,
      stockUnit: line.unit,
      subtotal: line.subtotal,
      businessPercent: line.businessPercent,
      odometerReading: line.odometerReading,
      fuelType: line.fuelType,
      fillType: line.fillType,
      unitPrice: line.unitPrice,
      rawReceiptText: line.receiptEvidenceText,
      catalogItemId: line.catalogItemId,
      catalogItemName: line.catalogItemName,
      catalogItemPath: line.catalogItemPath,
      catalogMatchConfidence: line.catalogMatchConfidence,
      catalogMatchedTerms: line.catalogMatchedTerms,
      parserConfidence: review?.confidence ?? line.parserConfidence,
      parserReviewLabel: review?.label ?? line.parserReviewLabel,
      parserReviewReason: review?.reason ?? line.parserReviewReason,
      parserNeedsReview: review?.needsReview ?? line.parserNeedsReview,
      ocrSourceLineId: line.ocrSourceLineId,
      ocrSourceLineNumber: line.ocrSourceLineNumber,
      ocrSourceSectionNumber: line.ocrSourceSectionNumber,
      ocrSourceSectionLineNumber: line.ocrSourceSectionLineNumber,
      parserExpenseFamily: line.parserExpenseFamily,
      parserHint: line.parserHint,
    );
  }
}
