import 'dart:io';

const _ledgerPath = 'docs/receipt_bug_regression_ledger.md';
const _requiredHeaders = [
  'Bug ID',
  'Category',
  'Symptom',
  'Root cause',
  'Fix',
  'Regression coverage',
  'Status',
];
const _allowedCategories = {
  'camera_capture_quality',
  'multi_photo_ordering',
  'ghost_overlap_stitching',
  'source_preservation',
  'ocr_handoff_contract',
  'receipt_line_numbering',
  'receipt_line_review_mode',
  'business_personal_split',
  'parser_totals_math',
  'fixture_generation',
  'qa_harness',
  'privacy_redaction',
  'native_bridge',
  'barcode_qr_scanning',
  'camera_review_state',
  'camera_diagnostics',
  'camera_docs',
  'storage_recovery',
};

void main() {
  final failures = <String>[];
  final file = File(_ledgerPath);
  if (!file.existsSync()) {
    failures.add('Missing receipt bug regression ledger: $_ledgerPath');
  } else {
    _checkLedger(file.readAsStringSync(), failures);
  }
  if (failures.isNotEmpty) {
    stderr.writeln('Receipt bug regression ledger gate failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
  }
}

void _checkLedger(String text, List<String> failures) {
  for (final header in _requiredHeaders) {
    if (!text.contains(header)) {
      failures.add('Ledger missing required field `$header`.');
    }
  }
  for (final category in _allowedCategories) {
    if (!text.contains('`$category`')) {
      failures.add('Ledger missing allowed category `$category`.');
    }
  }
  final rows = text
      .split('\n')
      .where((line) => line.startsWith('| `BUG-RECEIPT-'))
      .toList(growable: false);
  if (rows.isEmpty) failures.add('Ledger must contain at least one bug row.');
  for (final row in rows) {
    final cells = row
        .split('|')
        .map((cell) => cell.trim())
        .where((cell) => cell.isNotEmpty)
        .toList(growable: false);
    if (cells.length != _requiredHeaders.length) {
      failures.add('Bug row must have ${_requiredHeaders.length} cells: $row');
      continue;
    }
    final category = cells[1].replaceAll('`', '');
    if (!_allowedCategories.contains(category)) {
      failures.add('Bug row uses unknown category `$category`.');
    }
    if (cells.any((cell) => cell == '')) {
      failures.add('Bug row has an empty required field: $row');
    }
  }
}
