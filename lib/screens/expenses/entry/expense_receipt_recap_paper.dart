part of 'expense_receipt_entry_screen.dart';

class _ReceiptPaperRecap extends StatelessWidget {
  const _ReceiptPaperRecap({
    required this.lines,
    required this.storeName,
    required this.storeAddress,
    required this.receiptDateLabel,
    required this.receiptSubtotal,
    required this.salesTax,
    required this.receiptTotal,
    required this.showLineUseControls,
    required this.showItemDetails,
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
  final bool showLineUseControls;
  final bool showItemDetails;
  final ValueChanged<int> onEdit;
  final FutureOr<void> Function(int index, _ExpenseLineUse use) onSetUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'RECEIPT DETAILS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            storeName.trim().isEmpty ? 'STORE NOT FILLED YET' : storeName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          if (storeAddress.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              storeAddress,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            receiptDateLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 7),
          for (var index = 0; index < lines.length; index++) ...[
            _ReceiptPaperLineRow(
              lineNumber: index + 1,
              line: lines[index],
              showLineUseControls: showLineUseControls,
              showItemDetails: showItemDetails,
              onEdit: () => onEdit(index),
              onSetUse: (use) => onSetUse(index, use),
            ),
            if (index != lines.length - 1)
              const Divider(height: 14, color: Color(0xFF445159)),
          ],
          const Divider(height: 18, color: Color(0xFF69767D), thickness: 1.1),
          if (receiptSubtotal != null)
            _ReceiptPaperTotalLine(
              label: 'Subtotal',
              value: _money(receiptSubtotal!),
            ),
          if (salesTax != null)
            _ReceiptPaperTotalLine(label: 'Tax', value: _money(salesTax!)),
          const Divider(height: 12, color: Color(0xFF445159)),
          _ReceiptPaperTotalLine(
            label: 'Receipt Total',
            value: _money(receiptTotal),
            strong: true,
          ),
        ],
      ),
    );
  }
}
