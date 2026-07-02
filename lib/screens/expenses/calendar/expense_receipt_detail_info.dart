part of 'expense_calendar.dart';

class _ReceiptInfoPanel extends StatelessWidget {
  const _ReceiptInfoPanel({required this.receipt});

  final ExpenseReceiptRecord receipt;

  @override
  Widget build(BuildContext context) {
    final addressParts = [
      receipt.street,
      receipt.city,
      receipt.state,
      receipt.zip,
    ].where((part) => part.trim().isNotEmpty).join(', ');
    final contactParts = [
      receipt.phone,
      receipt.email,
      receipt.website,
    ].where((part) => part.trim().isNotEmpty).join(' | ');
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Receipt information',
                  style: TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              _SmallCalendarButton(
                label: 'Edit',
                icon: Icons.edit_rounded,
                onTap: () => _editFullReceipt(context, receipt),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoLine(label: 'Store', value: receipt.title),
          _InfoLine(
            label: 'Receipt proof',
            value: receipt.hasReceiptProof ? 'Attached' : 'Not attached',
          ),
          _InfoLine(
            label: 'Line subtotal',
            value: _money(receipt.lineSubtotal),
          ),
          _InfoLine(
            label: 'Receipt subtotal',
            value: _money(receipt.receiptSubtotal),
          ),
          _InfoLine(
            label: 'Sales tax',
            value: receipt.effectiveTaxRate == null
                ? _money(receipt.receiptTax)
                : '${_money(receipt.receiptTax)} | ${_percent(receipt.effectiveTaxRate!)}',
          ),
          _InfoLine(label: 'Receipt total', value: _money(receipt.total)),
          if (addressParts.isNotEmpty)
            _InfoLine(label: 'Address', value: addressParts),
          if (contactParts.isNotEmpty)
            _InfoLine(label: 'Contact', value: contactParts),
          if (receipt.notes.trim().isNotEmpty)
            _InfoLine(label: 'Notes', value: receipt.notes),
        ],
      ),
    );
  }
}

class _ReceiptAllocationPanel extends StatelessWidget {
  const _ReceiptAllocationPanel({required this.receipt});

  final ExpenseReceiptRecord receipt;

  @override
  Widget build(BuildContext context) {
    final businessLines = receipt.lines
        .where((line) => line.use != ExpenseLineUse.personal)
        .length;
    final personalLines = receipt.lines
        .where((line) => line.use != ExpenseLineUse.business)
        .length;
    final splitLines = receipt.lines
        .where((line) => line.use == ExpenseLineUse.split)
        .length;
    final status = receipt.ocrReview.hasData
        ? (receipt.ocrReview.needsReview ? 'Read needs review' : 'Read saved')
        : 'Manual or proof-only';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Receipt breakdown',
            style: TextStyle(
              color: Color(0xFFF0F4F2),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ReceiptBreakdownTile(
                  label: 'Business',
                  value: _money(receipt.businessTotal),
                  detail: '$businessLines lines',
                  color: const Color(0xFF8EF6A4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReceiptBreakdownTile(
                  label: 'Personal',
                  value: _money(receipt.personalTotal),
                  detail: '$personalLines lines',
                  color: const Color(0xFFFFD166),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ReceiptContextChip(
                label: splitLines == 0
                    ? 'No split lines'
                    : '$splitLines split ${splitLines == 1 ? 'line' : 'lines'}',
                icon: Icons.call_split_rounded,
              ),
              _ReceiptContextChip(
                label: receipt.hasReceiptAttachment
                    ? '${receipt.attachments.length} proof ${receipt.attachments.length == 1 ? 'file' : 'files'}'
                    : 'No proof attached',
                icon: receipt.hasReceiptAttachment
                    ? Icons.verified_rounded
                    : Icons.error_outline_rounded,
              ),
              _ReceiptContextChip(
                label: status,
                icon: receipt.ocrReview.needsReview
                    ? Icons.manage_search_rounded
                    : Icons.document_scanner_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptBreakdownTile extends StatelessWidget {
  const _ReceiptBreakdownTile({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFF0F4F2),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptContextChip extends StatelessWidget {
  const _ReceiptContextChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 8, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2226),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF3E4A50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFC8D0D3), size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9FAAAF),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
