enum MaintainiacCorrectionProposalKind {
  alias,
  negativeRule,
  merchantRule,
  regressionFixture,
  categoryMapping,
}

enum MaintainiacCorrectionProposalStatus {
  proposed,
  reviewed,
  accepted,
  rejected,
}

class MaintainiacCorrectionProposal {
  const MaintainiacCorrectionProposal({
    required this.id,
    required this.domain,
    required this.kind,
    required this.status,
    required this.sourceCandidateId,
    required this.userCorrectionHash,
    required this.proposedChange,
    required this.reason,
    this.regressionId = '',
    this.reviewer = '',
    this.autoPromoteToPack = false,
    this.mutatesConfirmedSource = false,
    this.tags = const {},
  });

  final String id;
  final String domain;
  final MaintainiacCorrectionProposalKind kind;
  final MaintainiacCorrectionProposalStatus status;
  final String sourceCandidateId;
  final String userCorrectionHash;
  final String proposedChange;
  final String reason;
  final String regressionId;
  final String reviewer;
  final bool autoPromoteToPack;
  final bool mutatesConfirmedSource;
  final Set<String> tags;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('correction proposal missing id');
    if (domain.trim().isEmpty) failures.add('$id missing parser domain');
    if (sourceCandidateId.trim().isEmpty) {
      failures.add('$id missing source candidate id');
    }
    if (userCorrectionHash.trim().isEmpty) {
      failures.add('$id missing user correction hash');
    }
    if (proposedChange.trim().isEmpty) {
      failures.add('$id missing proposed change');
    }
    if (reason.trim().isEmpty) failures.add('$id missing reason');
    if (tags.isEmpty) failures.add('$id needs searchable tags');
    if (autoPromoteToPack) {
      failures.add('$id must never auto-promote into official packs');
    }
    if (mutatesConfirmedSource) {
      failures.add('$id must not mutate confirmed source records');
    }
    if (status == MaintainiacCorrectionProposalStatus.accepted &&
        reviewer.trim().isEmpty) {
      failures.add('$id accepted proposal needs reviewer');
    }
    if (kind == MaintainiacCorrectionProposalKind.regressionFixture &&
        regressionId.trim().isEmpty) {
      failures.add('$id regression fixture proposal needs regression id');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'domain': domain,
      'kind': kind.name,
      'status': status.name,
      'sourceCandidateId': sourceCandidateId,
      'userCorrectionHash': userCorrectionHash,
      'proposedChange': proposedChange,
      'reason': reason,
      if (regressionId.isNotEmpty) 'regressionId': regressionId,
      if (reviewer.isNotEmpty) 'reviewer': reviewer,
      'autoPromoteToPack': autoPromoteToPack,
      'mutatesConfirmedSource': mutatesConfirmedSource,
      'tags': tags.toList()..sort(),
    };
  }
}

class MaintainiacCorrectionLearningContract {
  const MaintainiacCorrectionLearningContract(this.proposals);

  final List<MaintainiacCorrectionProposal> proposals;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    if (proposals.isEmpty) failures.add('correction learning has no proposals');
    for (final proposal in proposals) {
      if (!ids.add(proposal.id)) {
        failures.add('duplicate correction proposal id ${proposal.id}');
      }
      failures.addAll(proposal.validate());
    }
    return failures;
  }

  List<MaintainiacCorrectionProposal> pendingReview() {
    return [
      for (final proposal in proposals)
        if (proposal.status == MaintainiacCorrectionProposalStatus.proposed)
          proposal,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'proposalCount': proposals.length,
      'pendingReviewCount': pendingReview().length,
      'proposals': [for (final proposal in proposals) proposal.toJson()],
    };
  }
}
