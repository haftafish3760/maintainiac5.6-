import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test(
    'parser candidate contract preserves review-only inventory evidence',
    () {
      const contract = MaintainiacParserCandidateContract([
        MaintainiacParseCandidate(
          id: 'candidate_inventory_pvc_001',
          domain: 'inventory_parser',
          rawInputHash: 'sha256:pvc-el-34',
          normalizedLabel: 'PVC EL 3/4',
          reviewStatus: MaintainiacParserReviewStatus.needsReview,
          confidence: 0.72,
          evidence: {
            'merchant': 'unknown',
            'tokens': ['PVC', 'EL', '3/4'],
            'rankedCandidates': [
              'plumbing_pvc_elbow',
              'electrical_pvc_conduit_elbow',
            ],
          },
          confidenceReasons: [
            'PVC and elbow tokens are ambiguous across trades.',
            'No merchant department or active job context resolved ambiguity.',
          ],
          warnings: ['Review required before inventory or job write.'],
          missingFields: ['tradeContext', 'merchantDepartment'],
          suggestedAction: 'Show ranked candidates and require user selection.',
        ),
      ]);

      expect(contract.validate(), isEmpty);
      expect(contract.needingReview(), hasLength(1));
      expect(contract.toJson().toString(), contains('rankedCandidates'));
    },
  );

  test('parser candidate contract allows confirmed only after user action', () {
    const contract = MaintainiacParserCandidateContract([
      MaintainiacParseCandidate(
        id: 'candidate_expense_fuel_001',
        domain: 'expense_receipt_parser',
        rawInputHash: 'sha256:fuel-total-1060',
        normalizedLabel: 'fuel receipt total 10.60',
        reviewStatus: MaintainiacParserReviewStatus.confirmed,
        confidence: 0.99,
        evidence: {'category': 'fuel', 'totalCents': 1060, 'taxCents': 60},
        confidenceReasons: [
          'User confirmed category and total.',
          'Integer-cent ledger balanced.',
        ],
        suggestedAction: 'Write confirmed expense to local Hive first.',
        userConfirmed: true,
      ),
    ]);

    expect(contract.validate(), isEmpty);
    expect(contract.needingReview(), isEmpty);
  });

  test('parser candidate contract rejects autosave and false confirmation', () {
    const contract = MaintainiacParserCandidateContract([
      MaintainiacParseCandidate(
        id: 'candidate_bad_autosave',
        domain: 'inventory_parser',
        rawInputHash: 'sha256:bad',
        normalizedLabel: 'PEX 90',
        reviewStatus: MaintainiacParserReviewStatus.suggested,
        confidence: 0.99,
        evidence: {
          'tokens': ['PEX', '90'],
        },
        confidenceReasons: ['Strong token match.'],
        suggestedAction: 'Auto-write bad candidate.',
        autoSaveAllowed: true,
      ),
      MaintainiacParseCandidate(
        id: 'candidate_bad_confirmed',
        domain: 'expense_receipt_parser',
        rawInputHash: 'sha256:bad-confirmed',
        normalizedLabel: 'fuel total',
        reviewStatus: MaintainiacParserReviewStatus.confirmed,
        confidence: 0.9,
        evidence: {'totalCents': 1000},
        confidenceReasons: ['Parser guessed total.'],
        suggestedAction: 'Write expense.',
      ),
    ]);

    final failures = contract.validate().join('\n');

    expect(failures, contains('must never auto-save'));
    expect(failures, contains('high-confidence suggestion still needs review'));
    expect(failures, contains('confirmed candidate must be user-confirmed'));
  });
}
