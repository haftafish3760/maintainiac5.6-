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
    required this.businessTotal,
    required this.personalTotal,
    required this.showLineUseControls,
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
  final bool showLineUseControls;
  final ValueChanged<int> onEdit;
  final FutureOr<void> Function(int index, _ExpenseLineUse use) onSetUse;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE7E0D3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFB8AD9B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'SCANNED RECEIPT REVIEW',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF25211A),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            storeName.trim().isEmpty ? 'STORE NOT FILLED YET' : storeName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF25211A),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF62584C),
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
              color: Color(0xFF62584C),
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
              onEdit: () => onEdit(index),
              onSetUse: (use) => onSetUse(index, use),
              onDelete: () => onDelete(index),
            ),
            if (index != lines.length - 1)
              const Divider(height: 9, color: Color(0x66756B5D)),
          ],
          const Divider(height: 16, color: Color(0x99756B5D), thickness: 1.1),
          if (receiptSubtotal != null)
            _ReceiptPaperTotalLine(
              label: 'Subtotal',
              value: _money(receiptSubtotal!),
            ),
          if (salesTax != null)
            _ReceiptPaperTotalLine(label: 'Tax', value: _money(salesTax!)),
          _ReceiptPaperTotalLine(
            label: 'Business',
            value: _money(businessTotal),
          ),
          _ReceiptPaperTotalLine(
            label: 'Personal',
            value: _money(personalTotal),
          ),
          const Divider(height: 12, color: Color(0x66756B5D)),
          _ReceiptPaperTotalLine(
            label: 'Receipt Total',
            value: _money(receiptTotal),
            strong: true,
          ),
          if (showLineUseControls) ...[
            const Divider(height: 14, color: Color(0x66756B5D)),
            _ReceiptMixedAllocationReview(
              lines: lines,
              businessTotal: businessTotal,
              personalTotal: personalTotal,
            ),
            const SizedBox(height: 4),
            const Text(
              'Mixed totals include each line share plus allocated sales tax, fees, discounts, or receipt adjustments. Returns reduce their side but do not receive extra tax allocation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF62584C),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
