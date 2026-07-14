import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_benchmark_metrics.dart';

void main() {
  test('OCR benchmark keeps accuracy dimensions separate', () {
    final report = scoreReceiptOcrBenchmark([
      const ReceiptOcrBenchmarkCase(
        id: 'clear-receipt',
        expectedText: 'HDWR MART\nTOTAL 18.37',
        actualText: 'HDWR MART\nTOTAL 18.37',
        expectedMerchant: 'HDWR MART',
        actualMerchant: 'HDWR MART',
        expectedDate: '07/14/2026',
        actualDate: '07/14/2026',
        expectedTotal: '18.37',
        actualTotal: '18.37',
        expectedLines: ['HDWR MART', 'TOTAL 18.37'],
        actualLines: ['HDWR MART', 'TOTAL 18.37'],
        expectedRoute: 'expenseReview',
        actualRoute: 'expenseReview',
      ),
      const ReceiptOcrBenchmarkCase(
        id: 'numeric-error',
        expectedText: 'TOTAL 18.37',
        actualText: 'TOTAL 18.87',
        expectedTotal: '18.37',
        actualTotal: '18.87',
      ),
    ]);

    expect(report.caseCount, 2);
    expect(report.characterAccuracy, lessThan(1));
    expect(report.numericAccuracy, lessThan(1));
    expect(report.totalAccuracy, .5);
    expect(report.merchantAccuracy, 1);
    expect(report.below(.9), containsAll(['numeric', 'total']));
  });
}
