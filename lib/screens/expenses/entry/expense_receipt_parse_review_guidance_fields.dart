part of 'expense_receipt_entry_screen.dart';

List<_ReceiptFieldStatusChipData> _fieldStatusChipsFor(
  ReceiptOcrDiagnostics? diagnostics,
) {
  if (diagnostics == null ||
      (diagnostics.fieldReadinessCounts.isEmpty &&
          diagnostics.parserTaskCounts.isEmpty)) {
    return const [];
  }
  final counts = diagnostics.fieldReadinessCounts;
  final tasks = diagnostics.parserTaskCounts;
  final chips = <_ReceiptFieldStatusChipData?>[
    _fieldChip(
      ready: _readyCount(counts, tasks, 'vendor_ready', 'vendor_candidate'),
      review: counts['vendor_needs_review'] ?? 0,
      missing: _diagnosticCount(counts, tasks, 'vendor_missing'),
      readyLabel: 'Store ready',
      reviewLabel: 'Store needs review',
      missingLabel: 'Store missing',
      icon: Icons.storefront_rounded,
    ),
    _fieldChip(
      ready: _readyCount(counts, tasks, 'date_ready', 'date_candidate'),
      review: counts['date_needs_review'] ?? 0,
      missing: _diagnosticCount(counts, tasks, 'date_missing'),
      readyLabel: 'Date ready',
      reviewLabel: 'Date needs review',
      missingLabel: 'Date missing',
      icon: Icons.event_rounded,
    ),
    _fieldChip(
      ready: _readyCount(
        counts,
        tasks,
        'subtotal_ready',
        'subtotal_candidate',
      ),
      review: counts['subtotal_needs_review'] ?? 0,
      missing: _diagnosticCount(counts, tasks, 'subtotal_missing'),
      readyLabel: 'Subtotal ready',
      reviewLabel: 'Subtotal needs review',
      missingLabel: 'Subtotal missing',
      icon: Icons.calculate_rounded,
    ),
    _fieldChip(
      ready: _readyCount(counts, tasks, 'total_ready', 'total_candidate'),
      review: counts['total_needs_review'] ?? 0,
      missing: _diagnosticCount(counts, tasks, 'total_missing'),
      readyLabel: 'Total ready',
      reviewLabel: 'Total needs review',
      missingLabel: 'Total missing',
      icon: Icons.price_check_rounded,
    ),
    _fieldChip(
      ready: _readyCount(counts, tasks, 'tax_ready', 'tax_candidate'),
      review: counts['tax_needs_review'] ?? 0,
      missing: _diagnosticCount(counts, tasks, 'tax_missing'),
      readyLabel: 'Tax ready',
      reviewLabel: 'Tax needs review',
      missingLabel: 'Tax missing',
      icon: Icons.receipt_rounded,
    ),
  ].whereType<_ReceiptFieldStatusChipData>().toList(growable: true);
  final itemReady =
      counts['item_price_ready'] ?? tasks['item_price_ready'] ?? 0;
  final itemReview =
      counts['item_price_needs_review'] ??
      tasks['item_price_needs_review'] ??
      0;
  if (itemReady > 0) {
    chips.add(
      _ReceiptFieldStatusChipData(
        icon: Icons.format_list_numbered_rounded,
        label: '$itemReady item ${itemReady == 1 ? 'price' : 'prices'} ready',
        color: const Color(0xFF8EF6A4),
      ),
    );
  }
  if (itemReview > 0) {
    chips.add(
      _ReceiptFieldStatusChipData(
        icon: Icons.manage_search_rounded,
        label:
            '$itemReview item ${itemReview == 1 ? 'price needs' : 'prices need'} review',
        color: const Color(0xFFFFD166),
      ),
    );
  }
  final itemMissing = _diagnosticCount(counts, tasks, 'item_price_missing');
  if (itemMissing > 0) {
    chips.add(
      const _ReceiptFieldStatusChipData(
        icon: Icons.format_list_numbered_rounded,
        label: 'Item prices missing',
        color: Color(0xFFFF8FA3),
      ),
    );
  }
  final summaryMissing = _diagnosticCount(counts, tasks, 'summary_missing');
  if (summaryMissing > 0) {
    chips.add(
      const _ReceiptFieldStatusChipData(
        icon: Icons.summarize_rounded,
        label: 'Totals section missing',
        color: Color(0xFFFF8FA3),
      ),
    );
  }
  final materialCandidates =
      counts['inventory_material_candidate'] ??
      tasks['inventory_material_candidate'] ??
      0;
  if (materialCandidates > 0) {
    chips.add(
      _ReceiptFieldStatusChipData(
        icon: Icons.inventory_2_rounded,
        label:
            '$materialCandidates material ${materialCandidates == 1 ? 'candidate' : 'candidates'}',
        color: const Color(0xFF34A9E8),
      ),
    );
  }
  return List.unmodifiable(chips);
}

int _diagnosticCount(
  Map<String, int> counts,
  Map<String, int> tasks,
  String key,
) {
  final readiness = counts[key] ?? 0;
  if (readiness > 0) return readiness;
  return tasks[key] ?? 0;
}

int _readyCount(
  Map<String, int> counts,
  Map<String, int> tasks,
  String readinessKey,
  String taskKey,
) {
  final readiness = counts[readinessKey] ?? 0;
  if (readiness > 0) return readiness;
  return tasks[taskKey] ?? 0;
}

_ReceiptFieldStatusChipData? _fieldChip({
  required int ready,
  required int review,
  required int missing,
  required String readyLabel,
  required String reviewLabel,
  required String missingLabel,
  required IconData icon,
}) {
  if (missing > 0) {
    return _ReceiptFieldStatusChipData(
      icon: icon,
      label: missingLabel,
      color: const Color(0xFFFF8FA3),
    );
  }
  if (review > 0) {
    return _ReceiptFieldStatusChipData(
      icon: icon,
      label: reviewLabel,
      color: const Color(0xFFFFD166),
    );
  }
  if (ready > 0) {
    return _ReceiptFieldStatusChipData(
      icon: icon,
      label: readyLabel,
      color: const Color(0xFF8EF6A4),
    );
  }
  return null;
}
