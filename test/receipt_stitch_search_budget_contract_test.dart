import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stitch overlap comparison stays bounded by capability inputs', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/'
      'receipt_image_processor_stitch_helpers.dart',
    ).readAsStringSync();
    final budgetSource = File(
      'lib/shared/widgets/receipt_capture/'
      'receipt_image_processor_stitch_search_budget.dart',
    ).readAsStringSync();

    expect(source, contains('int comparisonWidth = 400'));
    expect(source, contains('comparisonWidth.clamp(240, 480)'));
    expect(source, contains('retryComparisonWidth'));
    expect(source, contains('.clamp(200, safeComparisonWidth)'));
    expect(
      source,
      contains('_ReceiptStitchSearchBudget.forSampleWidth(sampleWidth)'),
    );
    expect(budgetSource, contains('if (sampleWidth <= 320)'));
    expect(budgetSource, contains('if (sampleWidth <= 360)'));
    expect(budgetSource, contains('perspectiveCorrections: []'));
    expect(budgetSource, contains('coarseOverlapStep: 36'));
    expect(budgetSource, contains('coarseOverlapStep: 24'));
  });
}
