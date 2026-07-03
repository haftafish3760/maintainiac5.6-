import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('correction learning contract creates reviewable parser proposals', () {
    const contract = MaintainiacCorrectionLearningContract([
      MaintainiacCorrectionProposal(
        id: 'correction_inventory_alias_001',
        domain: 'inventory_parser',
        kind: MaintainiacCorrectionProposalKind.alias,
        status: MaintainiacCorrectionProposalStatus.proposed,
        sourceCandidateId: 'candidate_inventory_pvc_001',
        userCorrectionHash: 'sha256:user-selected-plumbing-pvc-elbow',
        proposedChange:
            'Add merchant-scoped alias PVC EL 3/4 -> plumbing PVC elbow only when plumbing context is active.',
        reason: 'User selected plumbing candidate from ambiguous receipt line.',
        tags: {'inventory', 'alias', 'review-required'},
      ),
      MaintainiacCorrectionProposal(
        id: 'correction_expense_mapping_001',
        domain: 'expense_receipt_parser',
        kind: MaintainiacCorrectionProposalKind.categoryMapping,
        status: MaintainiacCorrectionProposalStatus.proposed,
        sourceCandidateId: 'candidate_expense_fuel_001',
        userCorrectionHash: 'sha256:user-confirmed-fuel',
        proposedChange: 'Prefer fuel category for merchant gas_station.',
        reason: 'User confirmed gas-station receipt as fuel expense.',
        tags: {'expenses', 'category', 'review-required'},
      ),
    ]);

    expect(contract.validate(), isEmpty);
    expect(contract.pendingReview(), hasLength(2));
    expect(contract.toJson().toString(), contains('autoPromoteToPack'));
  });

  test('correction learning contract requires regression metadata', () {
    const contract = MaintainiacCorrectionLearningContract([
      MaintainiacCorrectionProposal(
        id: 'correction_regression_001',
        domain: 'inventory_parser',
        kind: MaintainiacCorrectionProposalKind.regressionFixture,
        status: MaintainiacCorrectionProposalStatus.accepted,
        sourceCandidateId: 'candidate_inventory_bad_001',
        userCorrectionHash: 'sha256:user-rejected-false-match',
        proposedChange:
            'Add regression fixture for electrical PVC conduit false match.',
        reason: 'Parser ranked plumbing item too high for conduit receipt.',
        regressionId: 'INV-0003',
        reviewer: 'maintainiac-qa',
        tags: {'inventory', 'regression', 'privacy-reviewed'},
      ),
    ]);

    expect(contract.validate(), isEmpty);
    expect(contract.pendingReview(), isEmpty);
  });

  test('correction learning contract blocks silent pack mutation', () {
    const contract = MaintainiacCorrectionLearningContract([
      MaintainiacCorrectionProposal(
        id: 'correction_bad_auto_promote',
        domain: 'inventory_parser',
        kind: MaintainiacCorrectionProposalKind.alias,
        status: MaintainiacCorrectionProposalStatus.accepted,
        sourceCandidateId: 'candidate_1',
        userCorrectionHash: 'sha256:bad',
        proposedChange: 'Silently add alias to official pack.',
        reason: 'Bad automation.',
        autoPromoteToPack: true,
        reviewer: '',
        tags: {'bad'},
      ),
      MaintainiacCorrectionProposal(
        id: 'correction_bad_source_mutation',
        domain: 'expense_receipt_parser',
        kind: MaintainiacCorrectionProposalKind.regressionFixture,
        status: MaintainiacCorrectionProposalStatus.proposed,
        sourceCandidateId: 'candidate_2',
        userCorrectionHash: 'sha256:bad2',
        proposedChange: 'Change confirmed expense total from correction.',
        reason: 'Bad mutation.',
        mutatesConfirmedSource: true,
        tags: {'bad'},
      ),
    ]);

    final failures = contract.validate().join('\n');

    expect(failures, contains('must never auto-promote'));
    expect(failures, contains('must not mutate confirmed source records'));
    expect(failures, contains('accepted proposal needs reviewer'));
    expect(
      failures,
      contains('regression fixture proposal needs regression id'),
    );
  });
}
