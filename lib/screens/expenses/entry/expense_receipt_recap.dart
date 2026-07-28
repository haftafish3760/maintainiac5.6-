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
    required this.businessTotal,
    required this.personalTotal,
    required this.detailMode,
    required this.onEdit,
    required this.onSetUse,
    required this.onDelete,
  });

  final List<_ExpenseReceiptLine> lines;
  final String storeName;
  final String storeAddress;
  final String receiptDateLabel;
  final double? receiptSubtotal;
  final double? salesTax;
  final double receiptTotal;
  final double businessTotal;
  final double personalTotal;
  final _ReceiptDetailEntryMode detailMode;
  final ValueChanged<int> onEdit;
  final FutureOr<void> Function(int index, _ExpenseLineUse use) onSetUse;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final showLineUseControls = _showLineUseControls(lines);
    return ReceiptFormPanel(
      title: 'Receipt Items',
      subtitle: showLineUseControls
          ? 'Review each numbered line. Change its category or business allocation at any time.'
          : 'Review each numbered line. Tap any item to edit its description, quantity, category, or price.',
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
            businessTotal: businessTotal,
            personalTotal: personalTotal,
            showLineUseControls: showLineUseControls,
            showItemDetails:
                detailMode == _ReceiptDetailEntryMode.detailedItems,
            onEdit: onEdit,
            onSetUse: onSetUse,
            onDelete: onDelete,
          ),
      ],
    );
  }

  static bool _showLineUseControls(List<_ExpenseReceiptLine> lines) {
    // Every detailed line remains independently classifiable. Hiding these
    // controls on an all-business or all-personal receipt would force the user
    // to reclassify the entire receipt just to correct one item.
    return lines.isNotEmpty;
  }
}
