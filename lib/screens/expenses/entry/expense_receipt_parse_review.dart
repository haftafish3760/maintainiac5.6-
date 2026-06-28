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

class _ReceiptAppAssistedReviewIntroPanel extends StatelessWidget {
  const _ReceiptAppAssistedReviewIntroPanel({
    required this.lineCount,
    required this.unreviewedLineCount,
    required this.receiptTotalLabel,
    required this.detailMode,
    required this.ocrDiagnostics,
    required this.ocrWarnings,
  });

  final int lineCount;
  final int unreviewedLineCount;
  final String receiptTotalLabel;
  final _ReceiptDetailEntryMode detailMode;
  final ReceiptOcrDiagnostics? ocrDiagnostics;
  final List<ReceiptOcrWarning> ocrWarnings;

  @override
  Widget build(BuildContext context) {
    final hasWarnings = ocrWarnings.isNotEmpty;
    final needsLineReview = unreviewedLineCount > 0;
    final accent = hasWarnings || needsLineReview
        ? const Color(0xFFFFD166)
        : const Color(0xFF8EF6A4);
    return ReceiptFormPanel(
      title: 'Review What The App Filled In',
      subtitle:
          'Check the store, date, total, tax, and item prices. Then classify the receipt as Business, Personal, or Mixed before saving.',
      icon: Icons.fact_check_rounded,
      accentColor: accent,
      children: [
        Row(
          children: [
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Lines Found',
                value: '$lineCount',
                color: const Color(0xFFFFD166),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Needs Review',
                value: '$unreviewedLineCount',
                color: needsLineReview
                    ? const Color(0xFFFFD166)
                    : const Color(0xFF8EF6A4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Total',
                value: receiptTotalLabel,
                color: const Color(0xFF34A9E8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _ReceiptReviewInstructionChip(
              icon: Icons.receipt_long_rounded,
              label: _modeLabel,
              color: const Color(0xFF34A9E8),
            ),
            _ReceiptReviewInstructionChip(
              icon: needsLineReview
                  ? Icons.manage_search_rounded
                  : Icons.verified_rounded,
              label: needsLineReview
                  ? 'Check highlighted lines'
                  : 'No line warnings',
              color: needsLineReview
                  ? const Color(0xFFFFD166)
                  : const Color(0xFF8EF6A4),
            ),
            _ReceiptReviewInstructionChip(
              icon: hasWarnings
                  ? Icons.warning_amber_rounded
                  : Icons.document_scanner_rounded,
              label: _ocrStatusLabel,
              color: hasWarnings
                  ? const Color(0xFFFFD166)
                  : const Color(0xFF8EF6A4),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          lineCount <= 0
              ? 'If the app could not build safe line items, use the total buttons below or add lines manually.'
              : detailMode == _ReceiptDetailEntryMode.quickClassify
              ? 'Simple review shows prices first. Tap Mixed if any line needs its own business/personal choice.'
              : 'Detailed review keeps item descriptions visible so you can edit anything the app read wrong.',
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            height: 1.22,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  String get _modeLabel {
    return switch (detailMode) {
      _ReceiptDetailEntryMode.quickClassify => 'Simple price review',
      _ReceiptDetailEntryMode.detailedItems => 'Detailed item review',
    };
  }

  String get _ocrStatusLabel {
    final diagnostics = ocrDiagnostics;
    if (diagnostics == null) return 'OCR not measured';
    if (ocrWarnings.isNotEmpty) {
      return '${ocrWarnings.length} OCR ${ocrWarnings.length == 1 ? 'warning' : 'warnings'}';
    }
    return diagnostics.severity == ReceiptOcrReviewSeverity.good
        ? 'OCR looked good'
        : 'OCR needs review';
  }
}

class _ReceiptReviewInstructionChip extends StatelessWidget {
  const _ReceiptReviewInstructionChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .65)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptReadHandoffPanel extends StatelessWidget {
  const _ReceiptReadHandoffPanel({
    required this.savedProofCount,
    required this.ocrSourceCount,
    required this.decisionLabel,
  });

  final int savedProofCount;
  final int ocrSourceCount;
  final String decisionLabel;

  @override
  Widget build(BuildContext context) {
    final proofLabel = savedProofCount <= 0
        ? 'Receipt photo saved'
        : savedProofCount == 1
        ? '1 saved proof photo'
        : '$savedProofCount saved proof photos';
    final sourceLabel = ocrSourceCount <= 0
        ? 'checking readable source'
        : ocrSourceCount == 1
        ? '1 clear OCR source'
        : '$ocrSourceCount clear OCR sources';
    final decision = decisionLabel.trim();
    return ReceiptFormPanel(
      title: 'Reading Receipt Details',
      subtitle:
          'Your receipt photo is saved. Maintainiac is reading the clearest image now; next it opens the filled receipt details review.',
      icon: Icons.document_scanner_rounded,
      accentColor: const Color(0xFFFFD166),
      children: [
        Row(
          children: [
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Saved Proof',
                value: proofLabel,
                color: const Color(0xFF8EF6A4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Receipt Reader',
                value: sourceLabel,
                color: const Color(0xFF34A9E8),
              ),
            ),
          ],
        ),
        if (decision.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ReceiptReviewInstructionChip(
            icon: Icons.route_rounded,
            label: decision,
            color: const Color(0xFFFFD166),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Do not go back unless you want to keep checking the photo. When reading finishes, review the store, date, total, tax, and item prices before saving.',
          style: TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            height: 1.22,
            letterSpacing: 0,
          ),
        ),
      ],
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
    final prioritizedWarnings = warnings.toList(growable: false)
      ..sort(ReceiptOcrWarning.compareByPriority);
    final warning = prioritizedWarnings.isEmpty
        ? null
        : prioritizedWarnings.first;
    final secondaryTargets = prioritizedWarnings
        .skip(1)
        .take(2)
        .map((warning) => warning.reviewTargetLabel)
        .toList(growable: false);
    final hiddenWarningCount = prioritizedWarnings.length > 1
        ? prioritizedWarnings.length - 1
        : 0;
    final recoverySummary = _ocrRecoverySummaryFor(warning, diagnostics.source);
    final detail = [
      diagnostics.readSummaryLabel,
      if (diagnostics.hasText) diagnostics.textSummaryLabel,
      if (warning != null) '${warning.reviewTargetLabel}.',
      if (warning != null) warning.reviewMessage,
      if (recoverySummary.isNotEmpty) 'Next step: $recoverySummary',
      if (warning != null && warning.reviewInstruction.isNotEmpty)
        warning.reviewInstruction,
      if (warning != null) warning.reviewTargetInstruction,
      if (secondaryTargets.isNotEmpty)
        'Next checks: ${secondaryTargets.join('; ')}.',
      if (hiddenWarningCount > 0)
        '$hiddenWarningCount more OCR ${hiddenWarningCount == 1 ? 'warning needs' : 'warnings need'} review.',
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return _ReceiptParseReviewBox(
      icon: switch (diagnostics.severity) {
        ReceiptOcrReviewSeverity.good => Icons.document_scanner_rounded,
        ReceiptOcrReviewSeverity.review => Icons.manage_search_rounded,
        ReceiptOcrReviewSeverity.partial => Icons.warning_amber_rounded,
        ReceiptOcrReviewSeverity.blocked => Icons.error_outline_rounded,
      },
      color: color,
      title: warnings.isEmpty
          ? 'OCR read: ${diagnostics.severity.label}'
          : 'OCR read: ${diagnostics.severity.label} - ${warnings.length} ${warnings.length == 1 ? 'warning' : 'warnings'}',
      detail: detail,
    );
  }

  String _ocrRecoverySummaryFor(
    ReceiptOcrWarning? warning,
    ReceiptProcessingSource source,
  ) {
    if (warning == null) {
      if (diagnostics.hasText) return '';
      return switch (source) {
        ReceiptProcessingSource.photo =>
          'Retake the receipt photo, add the missing long-receipt section, or continue by hand.',
        ReceiptProcessingSource.pdf =>
          'Scan the receipt with photos or continue by hand.',
        ReceiptProcessingSource.importedText =>
          'Paste cleaner receipt text or continue by hand.',
        ReceiptProcessingSource.mixed =>
          'Choose the clearest receipt source, add a clearer photo, or continue by hand.',
        ReceiptProcessingSource.none =>
          'Attach a receipt photo, readable PDF, or pasted receipt text.',
      };
    }
    return switch (warning.kind) {
      ReceiptOcrWarningKind.noSource =>
        'Attach a receipt photo, readable PDF, or pasted receipt text.',
      ReceiptOcrWarningKind.noReadableText => _ocrRecoverySummaryFor(
        null,
        source,
      ),
      ReceiptOcrWarningKind.sourceSkipped =>
        'Review the saved proof or turn receipt reading back on.',
      ReceiptOcrWarningKind.duplicateText ||
      ReceiptOcrWarningKind.probableOverlap =>
        'Check the long-receipt overlap before saving.',
      ReceiptOcrWarningKind.sectionGap =>
        'Add the missing receipt section or confirm the photos are in order.',
      ReceiptOcrWarningKind.pdfSafety =>
        'Attach a safe PDF copy, scan with photos, or continue by hand.',
      ReceiptOcrWarningKind.pdfTooLarge =>
        'Use a smaller PDF or scan the receipt with photos.',
      ReceiptOcrWarningKind.pdfUnreadable ||
      ReceiptOcrWarningKind.pdfReadFailure =>
        'Scan the receipt with photos, attach a clearer PDF, or continue by hand.',
      ReceiptOcrWarningKind.pluginUnavailable =>
        'Continue with manual entry for this build.',
      ReceiptOcrWarningKind.photoQuality =>
        'Retake the photo if store, date, total, tax, or item prices are not readable.',
      ReceiptOcrWarningKind.photoReadFailure =>
        'Retake the photo, add another clear section, or continue by hand.',
      ReceiptOcrWarningKind.unknown =>
        'Review the receipt proof and filled fields before saving.',
    };
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
