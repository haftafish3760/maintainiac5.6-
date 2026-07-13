import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_ocr_handoff.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('OCR handoff passes the unchanged reusable QA harness', () async {
    final report = await QaHarness(
      domain: 'receipt_ocr_handoff',
      suites: const [_ReceiptOcrHandoffQaSuite()],
    ).run(const QaContext(strict: true, redactor: QaRedactor()));

    expect(report.actualFailureCount, 0, reason: report.toSummary());
    expect(report.checked, 4);
  });
}

class _ReceiptOcrHandoffQaSuite extends QaSuite {
  const _ReceiptOcrHandoffQaSuite() : super('receipt_ocr.handoff_contract');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    const readable = ReceiptOcrResult(
      rawText: 'STORE\nTOTAL 12.99',
      parserText: 'STORE\nTOTAL 12.99',
      textByAttachmentId: {'photo': 'STORE\nTOTAL 12.99'},
      source: ReceiptProcessingSource.photo,
    );
    const unreadable = ReceiptOcrResult(
      rawText: '',
      parserText: '',
      textByAttachmentId: {},
      source: ReceiptProcessingSource.photo,
    );
    final cases =
        <
          ({
            String category,
            bool inventory,
            ReceiptOcrHandoffDestination expected,
            ReceiptOcrResult ocr,
          })
        >[
          (
            category: 'Fuel',
            inventory: false,
            expected: ReceiptOcrHandoffDestination.fuel,
            ocr: readable,
          ),
          (
            category: 'Inventory',
            inventory: false,
            expected: ReceiptOcrHandoffDestination.inventory,
            ocr: readable,
          ),
          (
            category: 'Electrical',
            inventory: false,
            expected: ReceiptOcrHandoffDestination.expenseReview,
            ocr: readable,
          ),
          (
            category: '',
            inventory: false,
            expected: ReceiptOcrHandoffDestination.expenseReview,
            ocr: unreadable,
          ),
        ];

    for (final testCase in cases) {
      final handoff = ReceiptOcrHandoff.forUserSelection(
        ocr: testCase.ocr,
        selectedCategory: testCase.category,
        inventoryRequested: testCase.inventory,
      );
      if (handoff.destination != testCase.expected) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'explicit_route_mismatch',
            message: 'OCR handoff changed an explicit user route.',
            severity: QaSeverity.error,
            expected: testCase.expected.name,
            actual: handoff.destination.name,
          ),
        );
      }
      if (!testCase.ocr.hasText && !handoff.needsManualReview) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'unreadable_receipt_not_flagged',
            message:
                'An unreadable receipt must remain available for manual review.',
            severity: QaSeverity.error,
          ),
        );
      }
    }
    return timer.finish(
      suite: name,
      checked: cases.length,
      failures: failures,
      metrics: const {'contract': 'explicit_route_no_inference'},
    );
  }
}
