part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryTotalsHelpers on _ExpenseReceiptEntryScreenState {
  double get _businessTotal =>
      _lines
          .where((line) => line.use != _ExpenseLineUse.personal)
          .fold(0.0, (sum, line) => sum + line.businessAmount) +
      _allocatedReceiptAdjustment(_businessAdjustmentBase);

  double get _personalTotal =>
      _lines
          .where((line) => line.use != _ExpenseLineUse.business)
          .fold(0.0, (sum, line) => sum + line.personalAmount) +
      _allocatedReceiptAdjustment(_personalAdjustmentBase);

  double get _receiptTotal =>
      _enteredReceiptTotal ??
      _lineSubtotal + ((_enteredReceiptTax ?? 0) + _subtotalAdjustment);

  double get _lineSubtotal =>
      _lines.fold(0, (sum, line) => sum + line.subtotal);

  double get _businessAdjustmentBase =>
      _lines.fold(0, (sum, line) => sum + math.max(0, line.businessAmount));

  double get _personalAdjustmentBase =>
      _lines.fold(0, (sum, line) => sum + math.max(0, line.personalAmount));

  double get _receiptAdjustmentBase =>
      _businessAdjustmentBase + _personalAdjustmentBase;

  double? get _enteredReceiptSubtotal =>
      _parseMoneyInput(_receiptSubtotalController.text);

  double? get _enteredReceiptTax => _parseMoneyInput(_salesTaxController.text);

  double? get _enteredReceiptTotal =>
      _parseMoneyInput(_receiptTotalController.text);

  double get _subtotalAdjustment {
    final enteredSubtotal = _enteredReceiptSubtotal;
    if (enteredSubtotal == null) return 0;
    return enteredSubtotal - _lineSubtotal;
  }

  double get _receiptAdjustment => _receiptTotal - _lineSubtotal;

  String get _receiptDateLabel {
    final date =
        '${_selectedDate.month.toString().padLeft(2, '0')}/'
        '${_selectedDate.day.toString().padLeft(2, '0')}/'
        '${_selectedDate.year}';
    final time = _selectedTime;
    if (time == null) return date;
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$date $hour:$minute $period';
  }

  String get _receiptStoreAddressLabel {
    return [
      _streetController.text.trim(),
      [
        _cityController.text.trim(),
        _stateController.text.trim(),
        _zipController.text.trim(),
      ].where((part) => part.isNotEmpty).join(' '),
    ].where((part) => part.isNotEmpty).join(', ');
  }

  double _allocatedReceiptAdjustment(double lineAmount) {
    if (_receiptAdjustmentBase <= 0 || _receiptAdjustment == 0) return 0;
    return _receiptAdjustment * (lineAmount / _receiptAdjustmentBase);
  }
}
