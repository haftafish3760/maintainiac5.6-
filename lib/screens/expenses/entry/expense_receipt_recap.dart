part of 'expense_receipt_entry_screen.dart';

class _ReceiptRecapPanel extends StatelessWidget {
  const _ReceiptRecapPanel({
    required this.lines,
    required this.storeName,
    required this.storeAddress,
    required this.receiptDateLabel,
    required this.receiptSubtotal,
    required this.salesTax,
    required this.receiptTotal,
    required this.detailMode,
    required this.onEdit,
    required this.onSetUse,
  });

  final List<_ExpenseReceiptLine> lines;
  final String storeName;
  final String storeAddress;
  final String receiptDateLabel;
  final double? receiptSubtotal;
  final double? salesTax;
  final double receiptTotal;
  final _ReceiptDetailEntryMode detailMode;
  final ValueChanged<int> onEdit;
  final FutureOr<void> Function(int index, _ExpenseLineUse use) onSetUse;

  @override
  Widget build(BuildContext context) {
    final showLineUseControls = _showLineUseControls(lines);
    return ReceiptFormPanel(
      title: 'Receipt Details',
      subtitle: showLineUseControls
          ? 'Review the receipt, then tap a line to change it if needed.'
          : 'Review the receipt, then tap a line to edit it if needed.',
      icon: Icons.receipt_rounded,
      accentColor: const Color(0xFF34A9E8),
      children: [
        if (lines.isEmpty)
          const Text(
            'No receipt lines added yet.',
            style: TextStyle(
              color: Color(0xFFC8D0D3),
              fontWeight: FontWeight.w800,
            ),
          )
        else
          _ReceiptPaperRecap(
            lines: lines,
            storeName: storeName,
            storeAddress: storeAddress,
            receiptDateLabel: receiptDateLabel,
            receiptSubtotal: receiptSubtotal,
            salesTax: salesTax,
            receiptTotal: receiptTotal,
            showLineUseControls: showLineUseControls,
            showItemDetails:
                detailMode == _ReceiptDetailEntryMode.detailedItems,
            onEdit: onEdit,
            onSetUse: onSetUse,
          ),
      ],
    );
  }

  static bool _showLineUseControls(List<_ExpenseReceiptLine> lines) {
    // Business or Personal is receipt-wide. Only a split receipt needs
    // per-line classification controls, so the saved receipt stays compact.
    return lines.any(
      (line) =>
          line.use == _ExpenseLineUse.split ||
          line.use == _ExpenseLineUse.unclassified,
    );
  }
}
