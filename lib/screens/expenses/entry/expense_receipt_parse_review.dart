part of 'expense_receipt_entry_screen.dart';

class _ReceiptReviewStepMetric extends StatelessWidget {
  const _ReceiptReviewStepMetric({
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptNoLineRecoveryChip extends StatelessWidget {
  const _ReceiptNoLineRecoveryChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: .8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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

class _ReceiptParseReviewDetails extends StatelessWidget {
  const _ReceiptParseReviewDetails({
    required this.quality,
    required this.fieldConfidences,
    required this.ocrDiagnostics,
    required this.ocrWarnings,
    required this.maintenanceHints,
  });

  final ExpenseReceiptParseQuality? quality;
  final Map<String, ExpenseReceiptFieldConfidence> fieldConfidences;
  final ReceiptOcrDiagnostics? ocrDiagnostics;
  final List<ReceiptOcrWarning> ocrWarnings;
  final List<ExpenseReceiptMaintenanceHint> maintenanceHints;

  @override
  Widget build(BuildContext context) {
    final quality = this.quality;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ocrDiagnostics != null)
          _ReceiptOcrReviewRow(
            diagnostics: ocrDiagnostics!,
            warnings: ocrWarnings,
          ),
        if (ocrDiagnostics != null && quality != null)
          const SizedBox(height: 8),
        if (quality != null) _ReceiptParseQualityRow(quality: quality),
        if (fieldConfidences.isNotEmpty) ...[
          if (quality != null || ocrDiagnostics != null)
            const SizedBox(height: 8),
          _ReceiptFieldConfidenceRow(fieldConfidences: fieldConfidences),
        ],
        if (maintenanceHints.isNotEmpty) ...[
          if (quality != null ||
              ocrDiagnostics != null ||
              fieldConfidences.isNotEmpty)
            const SizedBox(height: 8),
          const _ReceiptMaintenanceHintHeader(),
          const SizedBox(height: 6),
          for (final hint in maintenanceHints.take(3)) ...[
            _ReceiptMaintenanceHintRow(hint: hint),
            if (hint != maintenanceHints.take(3).last)
              const SizedBox(height: 6),
          ],
        ],
      ],
    );
  }
}

class _ReceiptFieldConfidenceRow extends StatelessWidget {
  const _ReceiptFieldConfidenceRow({required this.fieldConfidences});

  final Map<String, ExpenseReceiptFieldConfidence> fieldConfidences;

  @override
  Widget build(BuildContext context) {
    final fields = _priorityFields();
    final reviewCount = fields.where((field) => field.needsReview).length;
    final color = reviewCount == 0
        ? const Color(0xFF8EF6A4)
        : reviewCount <= 2
        ? const Color(0xFFFFD166)
        : const Color(0xFFFF8FA3);
    final title = reviewCount == 0
        ? 'Fields to check: all key fields look good'
        : 'Fields to check: $reviewCount need review';
    final detail = fields
        .take(4)
        .map((field) => '${_fieldLabel(field.fieldKey)}: ${field.reason}')
        .join(' ');
    return _ReceiptParseReviewBox(
      icon: reviewCount == 0
          ? Icons.verified_rounded
          : Icons.manage_search_rounded,
      color: color,
      title: title,
      detail: detail,
    );
  }

  List<ExpenseReceiptFieldConfidence> _priorityFields() {
    const order = [
      'merchant',
      'date',
      'total',
      'subtotal',
      'tax',
      'receiptMath',
      'lineItems',
      'time',
    ];
    final ordered = [
      for (final key in order)
        if (fieldConfidences[key] != null) fieldConfidences[key]!,
    ];
    final review = ordered.where((field) => field.needsReview);
    final good = ordered.where((field) => !field.needsReview);
    return [...review, ...good].take(5).toList(growable: false);
  }

  String _fieldLabel(String key) {
    return switch (key) {
      'merchant' => 'Store',
      'date' => 'Date',
      'time' => 'Time',
      'subtotal' => 'Subtotal',
      'tax' => 'Tax',
      'total' => 'Total',
      'receiptMath' => 'Receipt math',
      'lineItems' => 'Line items',
      _ => key,
    };
  }
}

class _ReceiptOcrReviewRow extends StatelessWidget {
  const _ReceiptOcrReviewRow({
    required this.diagnostics,
    required this.warnings,
  });

  final ReceiptOcrDiagnostics diagnostics;
  final List<ReceiptOcrWarning> warnings;

  @override
  Widget build(BuildContext context) {
    final color = switch (diagnostics.severity) {
      ReceiptOcrReviewSeverity.good => const Color(0xFF8EF6A4),
      ReceiptOcrReviewSeverity.review => const Color(0xFFFFD166),
      ReceiptOcrReviewSeverity.partial => const Color(0xFFFFD166),
      ReceiptOcrReviewSeverity.blocked => const Color(0xFFFF8FA3),
    };
    final warning = warnings.isEmpty ? null : warnings.first;
    final detail = [
      diagnostics.readSummaryLabel,
      if (diagnostics.hasText) diagnostics.textSummaryLabel,
      if (warning != null) warning.reviewMessage,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return _ReceiptParseReviewBox(
      icon: switch (diagnostics.severity) {
        ReceiptOcrReviewSeverity.good => Icons.document_scanner_rounded,
        ReceiptOcrReviewSeverity.review => Icons.manage_search_rounded,
        ReceiptOcrReviewSeverity.partial => Icons.warning_amber_rounded,
        ReceiptOcrReviewSeverity.blocked => Icons.error_outline_rounded,
      },
      color: color,
      title: 'OCR read: ${diagnostics.severity.label}',
      detail: detail,
    );
  }
}

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              'Receipt text: $evidence',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ],
          if ((line.parserReviewReason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              line.parserReviewReason!.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

class _ReceiptLineEvidenceActionButton extends StatelessWidget {
  const _ReceiptLineEvidenceActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: .72)),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ReceiptParseQualityRow extends StatelessWidget {
  const _ReceiptParseQualityRow({required this.quality});

  final ExpenseReceiptParseQuality quality;

  @override
  Widget build(BuildContext context) {
    final color = quality.label == 'Good'
        ? const Color(0xFF8EF6A4)
        : quality.label == 'Review'
        ? const Color(0xFFFFD166)
        : const Color(0xFFFF8FA3);
    return _ReceiptParseReviewBox(
      icon: Icons.fact_check_rounded,
      color: color,
      title: 'Receipt fill: ${quality.confidencePercentLabel} ${quality.label}',
      detail: quality.reasons.take(2).join(' '),
    );
  }
}

class _ReceiptMaintenanceHintHeader extends StatelessWidget {
  const _ReceiptMaintenanceHintHeader();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Possible maintenance details found. Nothing is logged to maintenance until you choose that later.',
      style: TextStyle(
        color: Color(0xFFC8D0D3),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: 0,
      ),
    );
  }
}

class _ReceiptMaintenanceHintRow extends StatelessWidget {
  const _ReceiptMaintenanceHintRow({required this.hint});

  final ExpenseReceiptMaintenanceHint hint;

  @override
  Widget build(BuildContext context) {
    final details = [
      if ((hint.detail ?? '').trim().isNotEmpty) hint.detail!.trim(),
      if ((hint.oilWeight ?? '').trim().isNotEmpty) hint.oilWeight!.trim(),
      if (hint.serviceOdometer != null) 'odo ${hint.serviceOdometer}',
      if (hint.dueOdometer != null) 'due ${hint.dueOdometer}',
      if (hint.intervalMiles != null) '${hint.intervalMiles} mi interval',
      if (hint.intervalMonths != null) '${hint.intervalMonths} mo interval',
    ];
    final color = hint.label == 'Good'
        ? const Color(0xFF8EF6A4)
        : hint.label == 'Review'
        ? const Color(0xFFFFD166)
        : const Color(0xFFFF8FA3);
    return _ReceiptParseReviewBox(
      icon: Icons.build_rounded,
      color: color,
      title:
          '${hint.itemName} - ${hint.serviceType} (${(hint.confidence * 100).round()}% ${hint.label})',
      detail: details.isEmpty
          ? hint.evidence.take(2).join(', ')
          : details.join(' | '),
    );
  }
}

class _ReceiptParseReviewBox extends StatelessWidget {
  const _ReceiptParseReviewBox({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1114),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: .55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                if (detail.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC8D0D3),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
