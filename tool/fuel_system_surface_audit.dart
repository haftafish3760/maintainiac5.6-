import 'dart:convert';
import 'dart:io';

const _surface = <String>[
  'lib/screens/expenses/data/expense_receipt_fuel_parser.dart',
  'lib/screens/expenses/data/expense_receipt_fuel_pricing_logic.dart',
  'lib/screens/expenses/data/expense_receipt_fuel_quantity_logic.dart',
  'lib/screens/expenses/data/expense_receipt_parser_line_item_logic.dart',
  'lib/screens/expenses/data/expense_receipt_parser_category_match_logic.dart',
  'lib/screens/expenses/data/expense_receipt_parser_fuel_line_review_logic.dart',
  'lib/screens/expenses/data/fuel_economy_metrics.dart',
  'lib/screens/expenses/data/fuel_economy_helpers.dart',
  'lib/screens/expenses/data/fuel_economy_recap_metrics.dart',
  'lib/screens/expenses/data/expense_firestore_documents.dart',
  'lib/screens/expenses/reports/expense_recap_models.dart',
  'lib/screens/expenses/categories/fuel_category.dart',
  'lib/shared/state/global_odometer.dart',
];

const _tests = <String>[
  'test/expense_receipt_parser_fuel_formats_test.dart',
  'test/expense_receipt_parser_fuel_synthetic_matrix_test.dart',
  'test/fuel_synthetic_parser_runner_contract_test.dart',
  'test/fuel_economy_metrics_test.dart',
  'test/expense_firestore_documents_test.dart',
  'test/expense_recap_models_test.dart',
  'test/expense_ledger_fuel_test.dart',
];

void main() {
  final result = <String, Object?>{
    'scope': 'fuel-system',
    'excluded': ['ocr', 'stitching', 'pdf', 'inventory'],
    'surface': _surface.map((path) => _summarize('source', path)).toList(),
    'tests': _tests.map((path) => _summarize('test', path)).toList(),
  };
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
}

Map<String, Object?> _summarize(String kind, String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return {'kind': kind, 'path': path, 'status': 'missing'};
  }
  final lines = file.readAsLinesSync();
  final declarations = <String>[];
  final declarationPattern = RegExp(
    r'^\s*(?:abstract\s+)?(?:class|enum|mixin|extension|typedef|factory|static\s+\w+|Future<[^>]+>\s+\w+|\w+[?]?\s+\w+\()',
  );
  for (var index = 0; index < lines.length; index++) {
    if (declarationPattern.hasMatch(lines[index])) {
      declarations.add('${index + 1}:${lines[index].trim()}');
    }
  }
  final lineCount = lines.length;
  return {
    'kind': kind,
    'path': path,
    'status': lineCount > 500 ? 'over-500-lines' : 'ok',
    'lines': lineCount,
    'declarations': declarations,
  };
}
