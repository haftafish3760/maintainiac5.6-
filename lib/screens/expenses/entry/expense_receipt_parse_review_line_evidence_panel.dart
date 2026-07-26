part of 'expense_receipt_entry_screen.dart';

class _ReceiptLineEvidenceReviewPanel extends StatelessWidget {
  const _ReceiptLineEvidenceReviewPanel({
    required this.lines,
    required this.onConfirm,
    required this.onEdit,
    required this.onMarkExpenseOnly,
  });

  final List<_ExpenseReceiptLine> lines;
  final ValueChanged<int> onConfirm;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onMarkExpenseOnly;

  @override
  Widget build(BuildContext context) {
    final reviewed = [
      for (var index = 0; index < lines.length; index++)
        if (lines[index].hasParserReview) (index: index, line: lines[index]),
    ];
    final needsReview = reviewed
        .where((entry) => entry.line.parserNeedsReview)
        .length;
    final matched = reviewed
        .where((entry) => entry.line.catalogItemId != null)
        .length;
    final unmatched = reviewed.length - matched;
    final priorityLines = [
      ...reviewed.where((entry) => entry.line.parserNeedsReview),
      ...reviewed.where((entry) => !entry.line.parserNeedsReview),
    ].take(4).toList(growable: false);

    return ReceiptFormPanel(
      title: 'Line Review',
      subtitle: 'Check the original receipt text against the filled lines.',
      icon: Icons.rule_rounded,
      accentColor: needsReview > 0
          ? const Color(0xFFFFD166)
          : const Color(0xFF8EF6A4),
      children: [
        Row(
          children: [
            Expanded(
              child: _ReceiptLineEvidenceMetric(
                label: 'Review',
                value: '$needsReview',
                color: const Color(0xFFFFD166),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptLineEvidenceMetric(
                label: 'Matched',
                value: '$matched',
                color: const Color(0xFF8EF6A4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptLineEvidenceMetric(
                label: 'Unmatched',
                value: '$unmatched',
                color: const Color(0xFFFF8FA3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < priorityLines.length; index++) ...[
          _ReceiptLineEvidenceRow(
            line: priorityLines[index].line,
            onConfirm: () => onConfirm(priorityLines[index].index),
            onEdit: () => onEdit(priorityLines[index].index),
            onMarkExpenseOnly: () =>
                onMarkExpenseOnly(priorityLines[index].index),
          ),
          if (index != priorityLines.length - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _ReceiptLineEvidenceMetric extends StatelessWidget {
  const _ReceiptLineEvidenceMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
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

class _ReceiptLineEvidenceRow extends StatelessWidget {
  const _ReceiptLineEvidenceRow({
    required this.line,
    required this.onConfirm,
    required this.onEdit,
    required this.onMarkExpenseOnly,
  });

  final _ExpenseReceiptLine line;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onMarkExpenseOnly;

  @override
  Widget build(BuildContext context) {
    final color = line.parserBadgeColor;
    final evidence = line.receiptEvidenceText;
    final sourceLineLabel = line.ocrSourceLineLabel;
    final proofLineLabel = line.receiptProofLineReferenceLabel;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1114),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                line.parserNeedsReview
                    ? Icons.warning_amber_rounded
                    : Icons.verified_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  line.parserReviewActionText,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                line.parserReviewSummary,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            line.description.trim().isEmpty
                ? line.displayDescription
                : line.description.trim(),
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              sourceLineLabel.isEmpty
                  ? 'Receipt text: $evidence'
                  : '$sourceLineLabel: $evidence',
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ],
          if (line.hasParserClassification || line.hasOcrSourceLine) ...[
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [
                if (line.parserExpenseFamilyLabel.isNotEmpty)
                  _ReceiptLineEvidenceChip(
                    icon: Icons.category_rounded,
                    label: line.parserExpenseFamilyLabel,
                    color: const Color(0xFF34A9E8),
                  ),
                if (line.parserHintLabel.isNotEmpty)
                  _ReceiptLineEvidenceChip(
                    icon: Icons.rule_folder_rounded,
                    label: line.parserHintLabel,
                    color: const Color(0xFF8EF6A4),
                  ),
                if (sourceLineLabel.isNotEmpty)
                  _ReceiptLineEvidenceChip(
                    icon: Icons.subject_rounded,
                    label: sourceLineLabel,
                    color: const Color(0xFF34A9E8),
                  ),
                _ReceiptLineEvidenceChip(
                  icon: Icons.fact_check_rounded,
                  label:
                      '$proofLineLabel proof | ${line.clientProofReviewLabel}',
                  color: line.redactsFromClientProofByDefault
                      ? const Color(0xFFFFD166)
                      : const Color(0xFF34A9E8),
                ),
              ],
            ),
          ],
          if ((line.parserReviewReason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              line.parserReviewReason!.trim(),
              style: const TextStyle(
                color: Color(0xFF96A3A8),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              _ReceiptLineEvidenceActionButton(
                icon: Icons.check_circle_rounded,
                label: 'Confirm',
                color: const Color(0xFF8EF6A4),
                onPressed: onConfirm,
              ),
              _ReceiptLineEvidenceActionButton(
                icon: Icons.edit_rounded,
                label: 'Edit',
                color: const Color(0xFF34A9E8),
                onPressed: onEdit,
              ),
              if (line.category == 'Materials' || line.catalogItemId != null)
                _ReceiptLineEvidenceActionButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'Expense Only',
                  color: const Color(0xFFFFD166),
                  onPressed: onMarkExpenseOnly,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
