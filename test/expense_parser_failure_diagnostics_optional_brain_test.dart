import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_parser_failure_diagnostics.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';

void main() {
  group('ExpenseParserFailureDiagnostics optional receipt brain causes', () {
    test(
      'marks optional detail parser pack limits as a distinct review cause',
      () {
        final result = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
25PK #8 X 1-1/4 WOOD SCREWS 6.98
TOTAL 6.98
''', parserDepth: ReceiptParserDepth.lineItems);

        final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(
          result,
        );

        expect(result.diagnostics.shouldOfferDetailedParserPack, isTrue);
        expect(
          result.diagnostics.localReceiptParserRoutingCode,
          'optional_detail_pack_available',
        );
        expect(
          ExpenseParserFailureDiagnostics.outcomeFor(result),
          ExpenseParserTelemetryOutcome.needsReview,
        );
        expect(diagnostic, isNotNull);
        expect(
          diagnostic!.confirmedCause,
          'receipt_parser_optional_detail_pack_available',
        );
        expect(diagnostic.failedAt, 'receipt_optional_detail_pack_routing');
        expect(
          diagnostic.evidence,
          contains('local_route_optional_detail_pack_available'),
        );
        expect(diagnostic.evidence, contains('local_kept_false'));
        expect(diagnostic.evidence, contains('optional_pack_true'));
        expect(
          result.diagnostics.localParserEvidenceOutcome,
          'optional_parser_pack_limited',
        );
        expect(
          result.diagnostics.localParserEvidenceSummaryLabel,
          contains('stronger optional parser details'),
        );
        expect(
          diagnostic.evidence,
          contains('local_parser_evidence_optional_parser_pack_limited'),
        );
      },
    );

    test(
      'marks deferred optional parser packs as a storage guardrail cause',
      () {
        final base = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
25PK #8 X 1-1/4 WOOD SCREWS 6.98
TOTAL 6.98
''', parserDepth: ReceiptParserDepth.lineItems);
        final result = base.copyWith(
          diagnostics: base.diagnostics.copyWith(
            receiptBrainLowStorageDownloadRiskCounts: {
              'base_safe_optional_brain_deferred_for_low_storage': 1,
            },
            receiptBrainFullOfflineMustStayOptionalCounts: {'true': 1},
          ),
        );

        final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(
          result,
        );

        expect(result.diagnostics.shouldOfferDetailedParserPack, isTrue);
        expect(
          result.diagnostics.receiptBrainParserLimitOutcome,
          'optional_parser_pack_deferred_for_storage',
        );
        expect(
          result.diagnostics.receiptBrainParserLimitSummaryLabel,
          'Optional receipt brain deferred for storage',
        );
        expect(
          result.diagnostics.receiptBrainParserLimitActionLabel,
          contains('saved proof and core receipt fields'),
        );
        expect(
          result.diagnostics.ocrParserReviewCauseCodes,
          contains('receipt_parser_optional_pack_deferred_for_storage'),
        );
        expect(
          ExpenseParserFailureDiagnostics.outcomeFor(result),
          ExpenseParserTelemetryOutcome.needsReview,
        );
        expect(diagnostic, isNotNull);
        expect(
          diagnostic!.confirmedCause,
          'receipt_parser_optional_pack_deferred_for_storage',
        );
        expect(
          diagnostic.failedAt,
          'receipt_optional_detail_pack_storage_guardrail',
        );
        expect(
          diagnostic.evidence,
          contains('brain_limit_optional_parser_pack_deferred_for_storage'),
        );
        expect(
          result.diagnostics.localParserEvidenceOutcome,
          'receipt_brain_storage_limited',
        );
        expect(
          diagnostic.evidence,
          contains('local_parser_evidence_receipt_brain_storage_limited'),
        );
      },
    );

    test('marks oversized full offline receipt brain as optional-only', () {
      final base = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
25PK #8 X 1-1/4 WOOD SCREWS 6.98
TOTAL 6.98
''', parserDepth: ReceiptParserDepth.lineItems);
      final result = base.copyWith(
        diagnostics: base.diagnostics.copyWith(
          receiptBrainLowStorageDownloadRiskCounts: {
            'full_offline_large_optional_only': 1,
          },
          receiptBrainFullOfflineExceedsBaseGuardrailCounts: {'true': 1},
          receiptBrainFullOfflineMustStayOptionalCounts: {'true': 1},
        ),
      );

      final diagnostic = ExpenseParserFailureDiagnostics.diagnosticFor(result);

      expect(
        result.diagnostics.receiptBrainParserLimitOutcome,
        'full_offline_receipt_brain_optional_only',
      );
      expect(
        result.diagnostics.receiptBrainParserLimitSummaryLabel,
        'Full offline receipt brain is optional',
      );
      expect(
        result.diagnostics.receiptBrainParserLimitActionLabel,
        contains('offer the full offline receipt brain as a separate choice'),
      );
      expect(
        result.diagnostics.ocrParserReviewCauseCodes,
        contains('receipt_parser_full_offline_too_large_optional_only'),
      );
      expect(diagnostic, isNotNull);
      expect(
        diagnostic!.confirmedCause,
        'receipt_parser_full_offline_too_large_optional_only',
      );
      expect(diagnostic.failedAt, 'receipt_brain_full_offline_pack_guardrail');
      expect(
        diagnostic.evidence,
        contains('brain_limit_full_offline_receipt_brain_optional_only'),
      );
      expect(
        result.diagnostics.localParserEvidenceOutcome,
        'receipt_brain_storage_limited',
      );
    });
  });
}
