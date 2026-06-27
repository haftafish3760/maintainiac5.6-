part of 'expense_receipt_entry_screen.dart';

class _ReceiptClassificationReviewPanel extends StatelessWidget {
  const _ReceiptClassificationReviewPanel({
    required this.classification,
    required this.parseQuality,
    required this.fieldConfidences,
    required this.ocrDiagnostics,
    required this.ocrWarnings,
    required this.maintenanceHints,
    required this.onApplyCategory,
  });

  final ExpenseReceiptClassification classification;
  final ExpenseReceiptParseQuality? parseQuality;
  final Map<String, ExpenseReceiptFieldConfidence> fieldConfidences;
  final ReceiptOcrDiagnostics? ocrDiagnostics;
  final List<ReceiptOcrWarning> ocrWarnings;
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
      title: 'What Maintainiac Found',
      subtitle:
          'Review the store, date, totals, and line confidence before saving.',
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
              if (parseQuality != null ||
                  ocrDiagnostics != null ||
                  maintenanceHints.isNotEmpty) ...[
                const SizedBox(height: 9),
                _ReceiptParseReviewDetails(
                  quality: parseQuality,
                  fieldConfidences: fieldConfidences,
                  ocrDiagnostics: ocrDiagnostics,
                  ocrWarnings: ocrWarnings,
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

class _ReceiptWholeUseReviewPanel extends StatelessWidget {
  const _ReceiptWholeUseReviewPanel({
    required this.lines,
    required this.onMarkBusiness,
    required this.onMarkPersonal,
    required this.onMarkMixed,
  });

  final List<_ExpenseReceiptLine> lines;
  final VoidCallback onMarkBusiness;
  final VoidCallback onMarkPersonal;
  final VoidCallback onMarkMixed;

  @override
  Widget build(BuildContext context) {
    final businessCount = lines
        .where((line) => line.use == _ExpenseLineUse.business)
        .length;
    final personalCount = lines
        .where((line) => line.use == _ExpenseLineUse.personal)
        .length;
    final splitCount = lines
        .where((line) => line.use == _ExpenseLineUse.split)
        .length;
    final hasLines = lines.isNotEmpty;
    return ReceiptFormPanel(
      title: 'Classify This Receipt',
      subtitle:
          'Choose Business, Personal, or Mixed. If it is Mixed, review each line below.',
      icon: Icons.rule_folder_rounded,
      accentColor: const Color(0xFFFFD166),
      children: [
        Row(
          children: [
            Expanded(
              child: _ReceiptWholeUseButton(
                label: 'All Business',
                helper: 'Every parsed line counts for work.',
                icon: Icons.business_center_rounded,
                color: const Color(0xFF34A9E8),
                onPressed: hasLines ? onMarkBusiness : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptWholeUseButton(
                label: 'All Personal',
                helper: 'Nothing on this receipt counts for work.',
                icon: Icons.person_rounded,
                color: const Color(0xFF8F9BA1),
                onPressed: hasLines ? onMarkPersonal : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ReceiptWholeUseButton(
          label: 'Mixed Receipt',
          helper:
              'Review each line below and mark Business, Personal, or Split. Split starts at 50/50 and can be edited.',
          icon: Icons.call_split_rounded,
          color: const Color(0xFF3B7C73),
          onPressed: hasLines ? onMarkMixed : null,
        ),
        const SizedBox(height: 8),
        Text(
          hasLines
              ? 'Current lines: $businessCount business, $personalCount personal, $splitCount split.'
              : 'After the receipt is read, the parsed lines will appear here for review.',
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ReceiptWholeUseButton extends StatelessWidget {
  const _ReceiptWholeUseButton({
    required this.label,
    required this.helper,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String helper;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            helper,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: const Color(0xFF76848A),
        side: BorderSide(
          color: onPressed == null
              ? const Color(0xFF526168)
              : color.withValues(alpha: .72),
        ),
        alignment: Alignment.centerLeft,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

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
  final ValueChanged<int> onEdit;
  final FutureOr<void> Function(int index, _ExpenseLineUse use) onSetUse;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final showLineUseControls = _showLineUseControls(lines);
    return ReceiptFormPanel(
      title: 'Receipt Recap',
      subtitle: showLineUseControls
          ? 'Mixed receipt: classify each line. Tap a line to edit details.'
          : 'Tap Mixed Receipt above if only some lines are for work.',
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
            onEdit: onEdit,
            onSetUse: onSetUse,
            onDelete: onDelete,
          ),
      ],
    );
  }

  static bool _showLineUseControls(List<_ExpenseReceiptLine> lines) {
    final hasBusiness = lines.any(
      (line) => line.use == _ExpenseLineUse.business,
    );
    final hasPersonal = lines.any(
      (line) => line.use == _ExpenseLineUse.personal,
    );
    final hasSplit = lines.any((line) => line.use == _ExpenseLineUse.split);
    return hasSplit || (hasBusiness && hasPersonal);
  }
}

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
            const SizedBox(height: 4),
            const Text(
              'Mixed totals include each line share plus allocated tax or receipt adjustment. Returns reduce their side but do not receive extra tax allocation.',
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
    required this.showLineUseControls,
    required this.onEdit,
    required this.onSetUse,
    required this.onDelete,
  });

  final int lineNumber;
  final _ExpenseReceiptLine line;
  final bool showLineUseControls;
  final VoidCallback onEdit;
  final FutureOr<void> Function(_ExpenseLineUse use) onSetUse;
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
                    if (showLineUseControls) ...[
                      const SizedBox(height: 6),
                      _ReceiptLineUseSegment(
                        selected: line.use,
                        onSelected: onSetUse,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      line.allocationDetail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF62584C),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
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

class _ReceiptLineUseSegment extends StatelessWidget {
  const _ReceiptLineUseSegment({
    required this.selected,
    required this.onSelected,
  });

  final _ExpenseLineUse selected;
  final FutureOr<void> Function(_ExpenseLineUse use) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _ReceiptLineUseChip(
          label: 'Business',
          use: _ExpenseLineUse.business,
          selected: selected == _ExpenseLineUse.business,
          color: const Color(0xFF1F6FA8),
          onSelected: onSelected,
        ),
        _ReceiptLineUseChip(
          label: 'Personal',
          use: _ExpenseLineUse.personal,
          selected: selected == _ExpenseLineUse.personal,
          color: const Color(0xFF5D666D),
          onSelected: onSelected,
        ),
        _ReceiptLineUseChip(
          label: 'Split',
          use: _ExpenseLineUse.split,
          selected: selected == _ExpenseLineUse.split,
          color: const Color(0xFF2E756C),
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _ReceiptLineUseChip extends StatelessWidget {
  const _ReceiptLineUseChip({
    required this.label,
    required this.use,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String label;
  final _ExpenseLineUse use;
  final bool selected;
  final Color color;
  final FutureOr<void> Function(_ExpenseLineUse use) onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => unawaited(Future<void>.value(onSelected(use))),
      borderRadius: BorderRadius.circular(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? color : const Color(0x1A25211A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? color : const Color(0x66756B5D)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF25211A),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
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
