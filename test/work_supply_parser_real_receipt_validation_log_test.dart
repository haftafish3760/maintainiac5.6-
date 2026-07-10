import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_real_receipt_validation_log.dart';

void main() {
  test('builds a privacy-safe private receipt validation summary', () {
    final result = buildRealReceiptValidationSummary({
      'merchant-category': 'home_improvement_big_box',
      'expected-item-family': 'pvc elbow',
      'result-category': 'review_required',
      'failure-reason-category': 'cross_trade_ambiguous',
      'synthetic-fixture-recommendation': 'create safe PVC 90 fixture',
    });

    expect(result.error, isNull);
    final summary = result.summary!;
    expect(summary['rawReceiptStored'], isFalse);
    expect(summary['rawReceiptTextStored'], isFalse);
    expect(summary['receiptImageStored'], isFalse);
    expect(summary['privateReceiptContentCommitted'], isFalse);
    expect(summary['firebaseWritesAllowed'], isFalse);
    expect(summary['ocrCameraExpensesTouched'], isFalse);
    expect(summary.containsKey('rawLine'), isFalse);
    expect(summary.containsKey('receiptText'), isFalse);
  });

  test('rejects raw receipt text fields', () {
    final result = buildRealReceiptValidationSummary({
      'merchant-category': 'home_improvement_big_box',
      'expected-item-family': 'pvc elbow',
      'result-category': 'wrong',
      'raw-receipt-text': 'PRIVATE RECEIPT LINE',
    });

    expect(result.error, contains('Forbidden private receipt field'));
    expect(result.summary, isNull);
  });

  test('rejects exact merchant labels instead of safe categories', () {
    final result = buildRealReceiptValidationSummary({
      'merchant-category': 'lowes_store_1234',
      'expected-item-family': 'pvc elbow',
      'result-category': 'review_required',
    });

    expect(result.error, contains('Unsupported merchant category'));
    expect(result.summary, isNull);
  });

  test('rejects private-looking values in otherwise allowed fields', () {
    final result = buildRealReceiptValidationSummary({
      'merchant-category': 'home_improvement_big_box',
      'expected-item-family': 'pvc elbow receipt 123456',
      'result-category': 'wrong',
      'failure-reason-category': 'customer john 555-123-4567',
    });

    expect(result.error, contains('Forbidden private receipt value'));
    expect(result.summary, isNull);
  });

  test('writes only under build directory', () {
    final outside = runRealReceiptValidationLog([
      '--output',
      'docs/private_receipt_summary.json',
      '--merchant-category',
      'home_improvement_big_box',
      '--expected-item-family',
      'pvc elbow',
      '--result-category',
      'correct',
    ]);

    expect(outside.exitCode, isNot(0));
    expect(outside.message, contains('outside build'));
  });

  test('writes a JSON artifact without private receipt content', () {
    final output =
        'build/parser_qa_reports/test_private_receipt_validation_log.json';
    final file = File(output);
    if (file.existsSync()) file.deleteSync();

    final result = runRealReceiptValidationLog([
      '--output',
      output,
      '--merchant-category',
      'local_hardware',
      '--expected-item-family',
      'copper 90',
      '--result-category',
      'review_required',
      '--failure-reason-category',
      'cross_trade_ambiguous',
    ]);

    expect(result.exitCode, 0);
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(decoded['report'], 'work_supply_parser_real_receipt_validation_log');
    expect(decoded['rawReceiptStored'], isFalse);
    expect(decoded['merchantCategory'], 'local_hardware');
    expect(decoded.containsKey('rawReceiptText'), isFalse);
  });
}
