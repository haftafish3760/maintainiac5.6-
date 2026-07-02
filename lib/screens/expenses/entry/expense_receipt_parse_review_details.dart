part of 'expense_receipt_entry_screen.dart';

class _ReceiptParseReviewDetails extends StatelessWidget {
  const _ReceiptParseReviewDetails({
    required this.quality,
    required this.parseDiagnostics,
    required this.fieldConfidences,
    required this.ocrDiagnostics,
    required this.ocrWarnings,
    required this.maintenanceHints,
    required this.ocrActionCallbacks,
  });

  final ExpenseReceiptParseQuality? quality;
  final ExpenseReceiptParseDiagnostics? parseDiagnostics;
  final Map<String, ExpenseReceiptFieldConfidence> fieldConfidences;
  final ReceiptOcrDiagnostics? ocrDiagnostics;
  final List<ReceiptOcrWarning> ocrWarnings;
  final List<ExpenseReceiptMaintenanceHint> maintenanceHints;
  final Map<String, VoidCallback> ocrActionCallbacks;

  @override
  Widget build(BuildContext context) {
    final quality = this.quality;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ocrDiagnostics != null)
          _ReceiptOcrReviewRow(
            diagnostics: ocrDiagnostics!,
            parseDiagnostics: parseDiagnostics,
            warnings: ocrWarnings,
            actionCallbacks: ocrActionCallbacks,
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
