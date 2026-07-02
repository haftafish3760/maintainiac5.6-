part of 'work_supply_add_items_screen.dart';

class _InventoryReceiptPreview extends StatelessWidget {
  const _InventoryReceiptPreview({
    required this.lines,
    required this.currentLine,
    required this.parsedReview,
    required this.onConfirmAll,
    required this.onConfirmLine,
    required this.onEdit,
    required this.onRemove,
  });

  final List<ReceiptLineDraft> lines;
  final ReceiptLineDraft? currentLine;
  final _ParsedMaterialsReceiptReviewSummary? parsedReview;
  final VoidCallback onConfirmAll;
  final ValueChanged<int> onConfirmLine;
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
    final inventoryCount = previewLines
        .where((line) => line.isInventory)
        .length;
    final businessOnlyCount = previewLines
        .where((line) => line.isExpense && line.isBusinessUse)
        .length;
    final personalCount = previewLines
        .where((line) => line.isExpense && line.isPersonalUse)
        .length;
    final splitCount = previewLines.where((line) => line.isSplitUse).length;
    final confirmNeededCount = previewLines
        .where((line) => line.requiresInventoryConfirmation)
        .length;
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
            'Review each receipt line as inventory, business-only, personal, or split before saving.',
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
            if (parsedReview != null) ...[
              _ParsedReceiptReviewBanner(
                summary: parsedReview!,
                onConfirmAll: onConfirmAll,
              ),
              const SizedBox(height: 10),
            ],
            _ReceiptPreviewBreakdown(
              inventoryCount: inventoryCount,
              businessOnlyCount: businessOnlyCount,
              personalCount: personalCount,
              splitCount: splitCount,
              confirmNeededCount: confirmNeededCount,
            ),
            const SizedBox(height: 10),
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
                onConfirm: onConfirmLine,
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

class _ParsedReceiptReviewBanner extends StatelessWidget {
  const _ParsedReceiptReviewBanner({
    required this.summary,
    required this.onConfirmAll,
  });

  final _ParsedMaterialsReceiptReviewSummary summary;
  final VoidCallback onConfirmAll;

  @override
  Widget build(BuildContext context) {
    final color = summary.needsReview
        ? const Color(0xFFFFD166)
        : const Color(0xFF7EE0A1);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF171C14),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            summary.needsReview
                ? Icons.manage_search_rounded
                : Icons.fact_check_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App-assisted receipt review',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    '${summary.qualityLabel} read',
                    summary.confidenceLabel,
                    if ((summary.warning ?? '').trim().isNotEmpty)
                      summary.warning!.trim(),
                  ].join(' - '),
                  style: const TextStyle(
                    color: Color(0xFFD6DEE2),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (summary.needsReview) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Confirm all parsed lines',
              onPressed: onConfirmAll,
              icon: const Icon(Icons.done_all_rounded),
              color: const Color(0xFF07100A),
              style: IconButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(34, 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
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
    required this.onConfirm,
  });

  final int index;
  final ReceiptLineDraft line;
  final bool pending;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
      decoration: BoxDecoration(
        color: pending
            ? const Color(0xFF173143)
            : line.requiresInventoryConfirmation
            ? const Color(0xFF201B10)
            : const Color(0xFF141811),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: pending
              ? const Color(0xFF8FD3FF)
              : line.requiresInventoryConfirmation
              ? const Color(0xFFFFD166)
              : const Color(0xFF786A35),
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
                      line.displayDescription,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _ReceiptLaneBadge(line: line),
                        _ReceiptUseBadge(line: line),
                      ],
                    ),
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
                    if (line.hasAssistedReview) ...[
                      const SizedBox(height: 6),
                      _ReceiptLineReviewDetail(line: line),
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
                    if (line.canConfirmAssistedReview)
                      IconButton(
                        tooltip: 'Confirm parsed line',
                        onPressed: () => onConfirm(index),
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFF7EE0A1),
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
                  value: line.businessUseLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
