part of 'work_supply_add_items_screen.dart';

class _InventoryReceiptPreview extends StatelessWidget {
  const _InventoryReceiptPreview({
    required this.lines,
    required this.currentLine,
    required this.onEdit,
    required this.onRemove,
  });

  final List<ReceiptLineDraft> lines;
  final ReceiptLineDraft? currentLine;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final previewLines = [...lines, ?currentLine];
    final subtotal = previewLines.fold<double>(
      0,
      (sum, line) => sum + line.subtotal,
    );
    final tax = previewLines.fold<double>(
      0,
      (sum, line) => sum + line.taxAmount,
    );
    final total = subtotal + tax;
    final inferredTaxRate = subtotal <= 0 ? 0.0 : (tax / subtotal) * 100;
    return _BorderPanel(
      label: 'Receipt Preview',
      surfaceColor: const Color(0xFF1F241D),
      borderColor: const Color(0xFFD2B45A),
      labelColor: const Color(0xFFFFD166),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Receipt lines added so far',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'This preview keeps the receipt readable while you add items. Save the receipt after every line is listed.',
            style: TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          if (previewLines.isEmpty)
            const _EmptyReceiptPreview()
          else ...[
            for (var index = 0; index < previewLines.length; index++)
              _ReceiptPreviewLine(
                index: index,
                line: previewLines[index],
                pending:
                    currentLine != null &&
                    index == previewLines.length - 1 &&
                    !lines.contains(previewLines[index]),
                onEdit: onEdit,
                onRemove: onRemove,
              ),
            const Divider(color: Color(0xFF59666D), height: 18),
            _ReceiptPreviewTotalRow(label: 'Subtotal', value: _money(subtotal)),
            _ReceiptPreviewTotalRow(
              label: 'Tax',
              value: '${_money(tax)} (${_formatPercent(inferredTaxRate)})',
            ),
            _ReceiptPreviewTotalRow(
              label: 'Total',
              value: _money(total),
              emphasized: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyReceiptPreview extends StatelessWidget {
  const _EmptyReceiptPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151811),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF75672D)),
      ),
      child: const Text(
        'No receipt lines added yet.',
        style: TextStyle(
          color: Color(0xFFC7D0D4),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReceiptPreviewLine extends StatelessWidget {
  const _ReceiptPreviewLine({
    required this.index,
    required this.line,
    required this.pending,
    required this.onEdit,
    required this.onRemove,
  });

  final int index;
  final ReceiptLineDraft line;
  final bool pending;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
      decoration: BoxDecoration(
        color: pending ? const Color(0xFF173143) : const Color(0xFF141811),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: pending ? const Color(0xFF8FD3FF) : const Color(0xFF786A35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}.',
                style: const TextStyle(
                  color: Color(0xFF8FD3FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.description,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _ReceiptUseBadge(line: line),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatNumber(line.quantity)} ${line.purchaseType} x ${_formatNumber(line.unitsPerPackage)} ${line.unit} = ${_formatNumber(line.totalUnits)} ${line.unit}',
                      style: const TextStyle(
                        color: Color(0xFFC7D0D4),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (line.storageArea.trim().isNotEmpty ||
                        line.storageDetail.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (line.storageArea.trim().isNotEmpty)
                            line.storageArea.trim(),
                          if (line.storageDetail.trim().isNotEmpty)
                            line.storageDetail.trim(),
                        ].join(' - '),
                        style: const TextStyle(
                          color: Color(0xFFA9DFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (pending)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text(
                    'typing',
                    style: TextStyle(
                      color: Color(0xFF8FD3FF),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit line',
                      onPressed: () => onEdit(index),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF8FD3FF),
                        size: 18,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete line',
                      onPressed: () => onRemove(index),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFF8A8A),
                        size: 18,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _MiniReceiptStat(
                  label: 'Before tax',
                  value: _money(line.subtotal),
                ),
              ),
              Expanded(
                child: _MiniReceiptStat(
                  label: 'Tax',
                  value: _money(line.taxAmount),
                ),
              ),
              Expanded(
                child: _MiniReceiptStat(
                  label: 'Unit cost',
                  value: _money(line.unitCostWithTax),
                ),
              ),
              Expanded(
                child: _MiniReceiptStat(
                  label: 'Use',
                  value: _businessUsePreviewLabel(line),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptUseBadge extends StatelessWidget {
  const _ReceiptUseBadge({required this.line});

  final ReceiptLineDraft line;

  @override
  Widget build(BuildContext context) {
    final label = _businessUsePreviewLabel(line);
    final color = switch (line.businessUse) {
      'personal' => const Color(0xFFE0A7FF),
      'split' => const Color(0xFFFFD166),
      _ => const Color(0xFF63B3E6),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF07100A),
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

String _businessUsePreviewLabel(ReceiptLineDraft line) {
  return switch (line.businessUse) {
    'personal' => 'Personal',
    'split' => 'Split ${_formatPercent(line.businessPercent * 100)}',
    _ => 'Business',
  };
}

class _MiniReceiptStat extends StatelessWidget {
  const _MiniReceiptStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8F9A9F),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ReceiptPreviewTotalRow extends StatelessWidget {
  const _ReceiptPreviewTotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasized
                    ? const Color(0xFFE8ECEE)
                    : const Color(0xFFC7D0D4),
                fontSize: emphasized ? 14 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasized
                  ? const Color(0xFFA9DFFF)
                  : const Color(0xFFE8ECEE),
              fontSize: emphasized ? 15 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
