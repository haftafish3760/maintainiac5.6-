import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parser handoff status ladder covers empty and incomplete receipts', () {
    _expectStatus(
      '',
      parser: 'no_text',
      downstream: 'no_text',
      structure: 'no_text',
      sequence: 'empty',
    );

    _expectStatus(
      '''
ACME SUPPLY
06/12/2026
PVC ELBOW 1/2 IN 2.49
''',
      parser: 'missing_total',
      downstream: 'proof_needs_review',
      structure: 'missing_total',
      sequence: 'missing_summary',
    );

    _expectStatus(
      '''
ACME SUPPLY
06/12/2026
SUBTOTAL 2.49
TAX 0.20
TOTAL 2.69
''',
      parser: 'no_item_lines',
      downstream: 'proof_total_only',
      structure: 'no_items',
      sequence: 'no_items',
    );
  });

  test('parser handoff status ladder separates review and ready receipts', () {
    _expectStatus(
      '''
ACME SUPPLY
06/12/2026
ITEM 2.49
SUBTOTAL 2.49
TAX 0.20
TOTAL 2.69
''',
      parser: 'no_parser_ready_items',
      downstream: 'proof_total_only',
      structure: 'line_item_review',
      sequence: 'expected_order',
    );

    _expectStatus(
      '''
ACME SUPPLY
06/12/2026
PVC ELBOW 1/2 IN 2.49
SUBTOTAL 2.49
TAX 0.20
TOTAL 99.99
''',
      parser: 'inventory_ready',
      downstream: 'inventory_material_ready',
      structure: 'summary_math_review',
      sequence: 'expected_order',
    );

    _expectStatus(
      '''
ACME SUPPLY
06/12/2026
PVC ELBOW 1/2 IN 2.49
SUBTOTAL 2.49
TAX 0.20
TOTAL 2.69
''',
      parser: 'inventory_ready',
      downstream: 'inventory_material_ready',
      structure: 'ready_for_parser',
      sequence: 'expected_order',
    );
  });
}

void _expectStatus(
  String text, {
  required String parser,
  required String downstream,
  required String structure,
  required String sequence,
}) {
  final result = ReceiptOcrResult(
    rawText: text,
    parserText: text,
    textByAttachmentId: const {'photo-1': 'private receipt text omitted'},
    source: ReceiptProcessingSource.photo,
  );
  final handoff = result.parserHandoff;

  expect(handoff.parserReadinessStatus, parser, reason: text);
  expect(handoff.downstreamReadinessStatus, downstream, reason: text);
  expect(handoff.receiptStructureStatus, structure, reason: text);
  expect(handoff.lineSequenceStatus, sequence, reason: text);
}
