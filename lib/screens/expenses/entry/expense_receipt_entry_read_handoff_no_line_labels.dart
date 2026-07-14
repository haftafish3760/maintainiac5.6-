part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryReadHandoffNoLineLabels
    on _ExpenseReceiptEntryScreenState {
  bool get _receiptNoLineHasOcrText =>
      _rawReceiptText.trim().isNotEmpty ||
      (_lastOcrDiagnostics?.hasText ?? false) ||
      (_lastOcrDiagnostics?.rawLineCount ?? 0) > 0;

  String get _receiptNoLineTitleLabel {
    if (_scanningReceiptPhotos && !_receiptReadAttemptedWithoutText) {
      return 'Opening Receipt Details';
    }
    if (_receiptReadAttemptedWithoutText && !_receiptNoLineHasOcrText) {
      return 'No Readable Receipt Text';
    }
    if (_receiptNoLineHasOcrText) {
      return 'Receipt Text Found, Lines Need Help';
    }
    return 'No Receipt Lines Yet';
  }

  String get _receiptNoLineSubtitleLabel {
    if (_scanningReceiptPhotos && !_receiptReadAttemptedWithoutText) {
      return 'Maintainiac is checking the accepted photo now. Keep this screen open; receipt details will appear here when the photo is read.';
    }
    final warning = _primaryNoLineOcrWarning;
    if (warning != null && !_receiptNoLineHasOcrText) {
      return '${warning.label}. The proof image is still saved; retake, add another clearer section, or enter the receipt manually.';
    }
    if (_receiptReadAttemptedWithoutText && !_receiptNoLineHasOcrText) {
      return 'Maintainiac could not find usable receipt text in that photo. The proof image is still saved; retake, add another clearer section, or enter the receipt manually.';
    }
    if (_receiptNoLineHasOcrText) {
      return 'Receipt text was found, but item lines still need review. Use the receipt total if that is enough, or add lines manually.';
    }
    return 'No receipt lines have been created yet. Attach a receipt photo, use the receipt total, or enter the receipt manually.';
  }

  String get _receiptNoLineReasonLabel {
    if (_scanningReceiptPhotos && !_receiptReadAttemptedWithoutText) {
      return 'Checking photo';
    }
    final warning = _primaryNoLineOcrWarning;
    if (warning != null) return warning.label;
    if (_receiptReadAttemptedWithoutText && !_receiptNoLineHasOcrText) {
      return 'No usable receipt text found';
    }
    if (_receiptNoLineHasOcrText) return 'Item lines need review';
    return 'No receipt lines yet';
  }

  String get _receiptNoLineNextStepLabel {
    if (_scanningReceiptPhotos && !_receiptReadAttemptedWithoutText) {
      return 'Keep this screen open. Receipt details appear here as soon as the store, date, total, and item prices are ready.';
    }
    final warning = _primaryNoLineOcrWarning;
    if (warning != null) return warning.actionLabel;
    if (_receiptReadAttemptedWithoutText) {
      return 'Retake the photo, add another receipt photo if the receipt continues, or enter the receipt manually.';
    }
    if (_rawReceiptText.trim().isNotEmpty) {
      return 'Use the total buttons if that is enough, or add receipt lines manually.';
    }
    return 'Attach a clear receipt proof or enter the receipt manually.';
  }

  String get _receiptNoLineOcrOutcomeLabel {
    final diagnostics = _lastOcrDiagnostics;
    if (_scanningReceiptPhotos && !_receiptReadAttemptedWithoutText) {
      return 'Checking photo';
    }
    if (diagnostics == null) {
      return _receiptNoLineHasOcrText ? 'Text entered' : 'Not run yet';
    }
    if (!diagnostics.hasText) return 'No usable text';
    final lineLabel = diagnostics.rawLineCount == 1 ? 'line' : 'lines';
    return '${diagnostics.rawLineCount} receipt $lineLabel found';
  }

  String get _receiptNoLineParserOutcomeLabel {
    final diagnostics = _lastOcrDiagnostics;
    if (_scanningReceiptPhotos && !_receiptReadAttemptedWithoutText) {
      return 'Preparing receipt details';
    }
    if (!_receiptNoLineHasOcrText) return 'Receipt details not started';
    if (diagnostics == null) return 'Needs manual lines';
    return switch (diagnostics.parserReadinessStatus) {
      'receipt_ready' => 'Receipt fields ready',
      'inventory_ready' => 'Item lines need review',
      'missing_vendor' => 'Store name missing',
      'missing_total' => 'Receipt total missing',
      'no_priced_lines' => 'No safe prices',
      'no_item_lines' => 'No safe item lines',
      'no_parser_ready_items' => 'No trusted item lines',
      'needs_review' => 'Needs line review',
      'no_text' => 'No receipt text',
      '' => 'No detail status',
      _ => diagnostics.parserReadinessStatus.replaceAll('_', ' '),
    };
  }

  ReceiptOcrWarning? get _primaryNoLineOcrWarning {
    if (_lastOcrWarnings.isEmpty) return null;
    final warnings = [..._lastOcrWarnings]
      ..sort(ReceiptOcrWarning.compareByPriority);
    return warnings.first;
  }
}
