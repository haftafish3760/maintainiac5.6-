import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_parser_failure_diagnostics.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

void main() {
  group('ExpenseParserFailureDiagnostics core parser causes', () {
    test('marks receipts with no usable fields as parser failures', () {
      const result = ExpenseReceiptParseResult(
        sourceText: 'unreadable noise',
        lines: [],
        quality: ExpenseReceiptParseQuality(
          confidence: .12,
          needsReview: true,
          reasons: ['No fields.'],
        ),
      );

      final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(result);

      expect(
        ExpenseParserFailureDiagnostics.outcomeFor(result),
        ExpenseParserTelemetryOutcome.failed,
      );
      expect(diagnostic, isNotNull);
      expect(diagnostic!.workflowStep, ExpenseWorkflowStep.receiptParser);
      expect(diagnostic.confirmedCause, 'receipt_parser_no_usable_fields');
      expect(diagnostic.failedAt, 'after_ocr_text_before_receipt_fields');
      expect(diagnostic.evidence, contains('quality_poor'));
      expect(
        diagnostic.evidence,
        contains('local_parser_evidence_ocr_readability_limited'),
      );
    });

    test(
      'marks total reconciliation problems as reviewable parser failures',
      () {
        final result = parseExpenseReceiptText('''
Lowe's
06/12/2026
Pipe wrench 12.00
Copper fitting 4.00
Total 25.00
''');

        final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(
          result,
        );

        expect(
          ExpenseParserFailureDiagnostics.outcomeFor(result),
          ExpenseParserTelemetryOutcome.needsReview,
        );
        expect(diagnostic, isNotNull);
        expect(diagnostic!.confirmedCause, 'receipt_line_total_mismatch');
        expect(diagnostic.failedAt, 'receipt_line_reconciliation');
        expect(diagnostic.evidence, contains('reconciled_false'));
        expect(diagnostic.evidence, contains('line_diff_under_20dollars'));
        expect(diagnostic.evidence, contains('summary_diff_unknown'));
      },
    );

    test('marks subtotal tax total mismatch with safe math buckets', () {
      final result = parseExpenseReceiptText('''
Fuel Stop
06/12/2026
Diesel 48.75
Subtotal 48.75
Tax 2.93
Total 57.68
''');

      final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(result);

      expect(
        ExpenseParserFailureDiagnostics.outcomeFor(result),
        ExpenseParserTelemetryOutcome.needsReview,
      );
      expect(diagnostic, isNotNull);
      expect(diagnostic!.confirmedCause, 'receipt_subtotal_tax_total_mismatch');
      expect(diagnostic.failedAt, 'receipt_total_math_check');
      expect(diagnostic.evidence, contains('tax_false'));
      expect(diagnostic.evidence, contains('summary_diff_under_20dollars'));
      expect(diagnostic.evidence, contains('explicit_subtotal|tax|total'));
    });

    test('marks inferred subtotal as an exact parser review cause', () {
      final result = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
PVC GLUE 7.99
Tax 0.56
Total 8.55
''');

      final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(result);

      expect(
        ExpenseParserFailureDiagnostics.outcomeFor(result),
        ExpenseParserTelemetryOutcome.needsReview,
      );
      expect(diagnostic, isNotNull);
      expect(diagnostic!.confirmedCause, 'receipt_subtotal_inferred');
      expect(diagnostic.failedAt, 'receipt_total_math_inference');
      expect(diagnostic.evidence, contains('subtotal_review'));
    });

    test('marks fallback receipt dates as an exact parser review cause', () {
      final result = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
PVC GLUE 7.99
Subtotal 7.99
Tax 0.56
Total 8.55
''', fallbackDate: DateTime(2026, 6, 12));

      final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(result);

      expect(
        ExpenseParserFailureDiagnostics.outcomeFor(result),
        ExpenseParserTelemetryOutcome.needsReview,
      );
      expect(diagnostic, isNotNull);
      expect(diagnostic!.confirmedCause, 'receipt_date_used_fallback');
      expect(diagnostic.failedAt, 'receipt_date_fallback');
      expect(diagnostic.evidence, contains('date_review'));
    });

    test('reports totals-found no-line recovery as an exact parser cause', () {
      final result = parseExpenseReceiptText('''
LOWE'S HOME CENTERS, LLC
07/09/2021
SUBTOTAL 2.99
TAX 0.25
TOTAL 3.24
THANK YOU
''');

      final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(result);

      expect(
        ExpenseParserFailureDiagnostics.outcomeFor(result),
        ExpenseParserTelemetryOutcome.needsReview,
      );
      expect(diagnostic, isNotNull);
      expect(
        diagnostic!.confirmedCause,
        'receipt_parser_totals_found_no_safe_lines',
      );
      expect(
        diagnostic.failedAt,
        'receipt_line_detection_after_total_detection',
      );
      expect(diagnostic.evidence, contains('lines_0'));
      expect(diagnostic.evidence, contains('totals_true'));
      expect(
        diagnostic.evidence,
        contains('line_diff_under_5dollars_summary_diff_zero'),
      );
      expect(
        result.diagnostics.localParserEvidenceOutcome,
        'local_parser_patterns_limited',
      );
      expect(
        result.diagnostics.localParserEvidenceActionLabel,
        contains('Strengthen local merchant, total, tax, and line-item parser'),
      );
      expect(
        diagnostic.evidence,
        contains('local_parser_evidence_local_parser_patterns_limited'),
      );
    });

    test('does not create a failure diagnostic for a clean parse', () {
      final result = parseExpenseReceiptText('''
Quick Fuel
06/11/2026
Diesel 12.50 GAL 3.90 48.75
Subtotal 48.75
Tax 2.93
Total 51.68
''');

      expect(
        ExpenseParserFailureDiagnostics.outcomeFor(result),
        ExpenseParserTelemetryOutcome.completed,
      );
      expect(
        result.diagnostics.localReceiptParserRoutingCode,
        'fuel_simple_local',
      );
      expect(result.diagnostics.keepsSimpleReceiptLocal, isTrue);
      expect(result.diagnostics.shouldOfferDetailedParserPack, isFalse);
      expect(ExpenseParserFailureDiagnostics.diagnosticFor(result), isNull);
    });
  });
}
