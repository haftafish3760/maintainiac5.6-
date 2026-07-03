enum MaintainiacParserReviewStatus {
  suggested,
  needsReview,
  rejected,
  confirmed,
}

class MaintainiacParseCandidate {
  const MaintainiacParseCandidate({
    required this.id,
    required this.domain,
    required this.rawInputHash,
    required this.normalizedLabel,
    required this.reviewStatus,
    required this.confidence,
    required this.evidence,
    this.confidenceReasons = const [],
    this.warnings = const [],
    this.missingFields = const [],
    this.suggestedAction = '',
    this.autoSaveAllowed = false,
    this.userConfirmed = false,
  });

  final String id;
  final String domain;
  final String rawInputHash;
  final String normalizedLabel;
  final MaintainiacParserReviewStatus reviewStatus;
  final double confidence;
  final Map<String, Object?> evidence;
  final List<String> confidenceReasons;
  final List<String> warnings;
  final List<String> missingFields;
  final String suggestedAction;
  final bool autoSaveAllowed;
  final bool userConfirmed;

  bool get isFinal {
    return reviewStatus == MaintainiacParserReviewStatus.confirmed;
  }

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('parse candidate missing id');
    if (domain.trim().isEmpty) failures.add('$id missing parser domain');
    if (rawInputHash.trim().isEmpty) {
      failures.add('$id missing raw input hash');
    }
    if (normalizedLabel.trim().isEmpty) {
      failures.add('$id missing normalized label');
    }
    if (confidence < 0 || confidence > 1) {
      failures.add('$id confidence must be between 0 and 1');
    }
    if (evidence.isEmpty) failures.add('$id missing preserved evidence');
    if (confidenceReasons.isEmpty) {
      failures.add('$id missing confidence reasons');
    }
    if (suggestedAction.trim().isEmpty) {
      failures.add('$id missing suggested action');
    }
    if (autoSaveAllowed) {
      failures.add('$id parser candidates must never auto-save');
    }
    if (reviewStatus == MaintainiacParserReviewStatus.confirmed &&
        !userConfirmed) {
      failures.add('$id confirmed candidate must be user-confirmed');
    }
    if (reviewStatus != MaintainiacParserReviewStatus.confirmed &&
        userConfirmed) {
      failures.add('$id userConfirmed conflicts with ${reviewStatus.name}');
    }
    if (reviewStatus == MaintainiacParserReviewStatus.suggested &&
        confidence >= 0.97 &&
        warnings.isEmpty) {
      failures.add('$id high-confidence suggestion still needs review warning');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'domain': domain,
      'rawInputHash': rawInputHash,
      'normalizedLabel': normalizedLabel,
      'reviewStatus': reviewStatus.name,
      'confidence': confidence,
      'evidence': evidence,
      'confidenceReasons': confidenceReasons,
      'warnings': warnings,
      'missingFields': missingFields,
      'suggestedAction': suggestedAction,
      'autoSaveAllowed': autoSaveAllowed,
      'userConfirmed': userConfirmed,
    };
  }
}

class MaintainiacParserCandidateContract {
  const MaintainiacParserCandidateContract(this.candidates);

  final List<MaintainiacParseCandidate> candidates;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    if (candidates.isEmpty) failures.add('parser contract has no candidates');
    for (final candidate in candidates) {
      if (!ids.add(candidate.id)) {
        failures.add('duplicate parse candidate id ${candidate.id}');
      }
      failures.addAll(candidate.validate());
    }
    return failures;
  }

  List<MaintainiacParseCandidate> needingReview() {
    return [
      for (final candidate in candidates)
        if (!candidate.isFinal) candidate,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'candidateCount': candidates.length,
      'needsReviewCount': needingReview().length,
      'candidates': [for (final candidate in candidates) candidate.toJson()],
    };
  }
}
