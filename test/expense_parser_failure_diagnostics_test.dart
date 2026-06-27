import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_parser_failure_diagnostics.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

void main() {
  group('ExpenseParserFailureDiagnostics', () {
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
      },
    );

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
      expect(ExpenseParserFailureDiagnostics.diagnosticFor(result), isNull);
    });
  });
}
