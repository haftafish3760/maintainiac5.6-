part of 'expense_receipt_entry_screen.dart';

class _ReceiptClassificationReviewPanel extends StatelessWidget {
  const _ReceiptClassificationReviewPanel({
    required this.classification,
    required this.parseQuality,
    required this.maintenanceHints,
    required this.onApplyCategory,
  });

  final ExpenseReceiptClassification classification;
  final ExpenseReceiptParseQuality? parseQuality;
  final List<ExpenseReceiptMaintenanceHint> maintenanceHints;
  final ValueChanged<String> onApplyCategory;

  @override
  Widget build(BuildContext context) {
    final color = classification.confidence >= .84
        ? const Color(0xFF8EF6A4)
        : classification.confidence >= .58
        ? const Color(0xFFFFD166)
        : const Color(0xFFFF8FA3);
    final category = classification.category;
    return ReceiptFormPanel(
      title: 'Receipt Fill Review',
      subtitle: 'Maintainiac made a best guess. You stay in control.',
      icon: Icons.fact_check_rounded,
      accentColor: color,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF11181B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: .72)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_classificationIcon(classification.kind), color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      classification.title,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${classification.confidencePercentLabel} ${classification.confidenceLabel}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                classification.detail,
                style: const TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: 0,
                ),
              ),
              if (category != null) ...[
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Suggested category: $category',
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => onApplyCategory(category),
                      icon: const Icon(Icons.check_circle_rounded, size: 17),
                      label: const Text('Apply'),
                      style: TextButton.styleFrom(
                        foregroundColor: color,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Only blank categories are updated.',
                  style: TextStyle(
                    color: color.withValues(alpha: .82),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
              if (parseQuality != null || maintenanceHints.isNotEmpty) ...[
                const SizedBox(height: 9),
                _ReceiptParseReviewDetails(
                  quality: parseQuality,
                  maintenanceHints: maintenanceHints,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static IconData _classificationIcon(ExpenseReceiptClassificationKind kind) {
    return switch (kind) {
      ExpenseReceiptClassificationKind.fuel => Icons.local_gas_station_rounded,
      ExpenseReceiptClassificationKind.materials => Icons.inventory_2_rounded,
      ExpenseReceiptClassificationKind.maintenance ||
      ExpenseReceiptClassificationKind.repair => Icons.build_rounded,
      ExpenseReceiptClassificationKind.cellPhone => Icons.phone_android_rounded,
      ExpenseReceiptClassificationKind.jobDocument =>
        Icons.request_quote_rounded,
      ExpenseReceiptClassificationKind.otherDocument =>
        Icons.description_rounded,
      ExpenseReceiptClassificationKind.expenseReceipt =>
        Icons.receipt_long_rounded,
    };
  }
}

class _ReceiptRecapPanel extends StatelessWidget {
  const _ReceiptRecapPanel({
    required this.lines,
    required this.receiptTotal,
    required this.businessTotal,
    required this.personalTotal,
    required this.onEdit,
    required this.onDelete,
  });

  final List<_ExpenseReceiptLine> lines;
  final double receiptTotal;
  final double businessTotal;
  final double personalTotal;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return ReceiptFormPanel(
      title: 'Receipt Recap',
      subtitle:
          'Tap a line to edit it. This preview is laid out like a receipt.',
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
            receiptTotal: receiptTotal,
            businessTotal: businessTotal,
            personalTotal: personalTotal,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
      ],
    );
  }
}

class _ReceiptPaperRecap extends StatelessWidget {
  const _ReceiptPaperRecap({
    required this.lines,
    required this.receiptTotal,
    required this.businessTotal,
    required this.personalTotal,
    required this.onEdit,
    required this.onDelete,
  });

  final List<_ExpenseReceiptLine> lines;
  final double receiptTotal;
  final double businessTotal;
  final double personalTotal;
  final ValueChanged<int> onEdit;
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
            'RECEIPT LINES',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF25211A),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 7),
          for (var index = 0; index < lines.length; index++) ...[
            _ReceiptPaperLineRow(
              lineNumber: index + 1,
              line: lines[index],
              onEdit: () => onEdit(index),
              onDelete: () => onDelete(index),
            ),
            if (index != lines.length - 1)
              const Divider(height: 9, color: Color(0x66756B5D)),
          ],
          const Divider(height: 16, color: Color(0x99756B5D), thickness: 1.1),
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
        ],
      ),
    );
  }
}

class _ReceiptPaperTotalLine extends StatelessWidget {
  const _ReceiptPaperTotalLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: strong ? 4 : 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: const Color(0xFF25211A),
                fontSize: strong ? 13 : 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF25211A),
              fontSize: strong ? 15 : 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptPaperLineRow extends StatelessWidget {
  const _ReceiptPaperLineRow({
    required this.lineNumber,
    required this.line,
    required this.onEdit,
    required this.onDelete,
  });

  final int lineNumber;
  final _ExpenseReceiptLine line;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '$lineNumber.',
                  style: const TextStyle(
                    color: Color(0xFF25211A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF25211A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${line.allocationSummary} | ${line.category} | ${line.packageSummary}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF62584C),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    if (line.hasParserReview) ...[
                      const SizedBox(height: 3),
                      _ReceiptParserBadge(line: line),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(line.subtotal),
                    style: const TextStyle(
                      color: Color(0xFF25211A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LineButton(icon: Icons.edit_rounded, onTap: onEdit),
                      _LineButton(
                        icon: Icons.delete_outline_rounded,
                        color: Color(0xFFD85B4A),
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptParserBadge extends StatelessWidget {
  const _ReceiptParserBadge({required this.line});

  final _ExpenseReceiptLine line;

  @override
  Widget build(BuildContext context) {
    final color = line.parserBadgeColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: .75)),
      ),
      child: Text(
        line.parserReviewSummary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _LineButton extends StatelessWidget {
  const _LineButton({
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF34A9E8),
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
