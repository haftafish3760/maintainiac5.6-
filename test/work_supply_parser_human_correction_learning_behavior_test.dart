import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inventory parser human correction learning behavior', () {
    test('correction proposals cover every learning target before promotion', () {
      final correction = _CorrectionEvent.example();
      final proposals = _CorrectionLearningPlanner().plan(correction);

      expect(
        proposals.map((proposal) => proposal.kind),
        containsAll(const [
          _LearningProposalKind.proposedAlias,
          _LearningProposalKind.negativeRule,
          _LearningProposalKind.merchantRule,
          _LearningProposalKind.regressionFixture,
          _LearningProposalKind.confidenceHint,
          _LearningProposalKind.missingVendorMapping,
          _LearningProposalKind.localePhrase,
          _LearningProposalKind.spanishPhrase,
          _LearningProposalKind.itemFamily,
          _LearningProposalKind.tradeContext,
        ]),
      );
      expect(proposals, everyElement(_requiresReview()));
      expect(proposals, everyElement(_keepsOriginalEvidence()));
      expect(proposals, everyElement(_isScopedToMerchantLocaleTrade()));
      expect(
        proposals,
        everyElement(
          predicate<_LearningProposal>(
            (proposal) => proposal.officialPackMutation == false,
            'correction_never_silently_mutates_official_pack',
          ),
        ),
      );
    });

    test('promotion is blocked until a reviewed proposal is manually approved', () {
      final pending = _LearningProposal.aliasFrom(_CorrectionEvent.example());

      expect(pending.canPromoteOfficially, isFalse);
      expect(pending.requiresReviewBeforePromotion, isTrue);
      expect(pending.officialPackMutation, isFalse);
      expect(
        pending.safetyRuleIds,
        contains('correction_requires_review_before_promotion'),
      );

      final approved = pending.approveForManualPromotion(
        reviewerId: 'catalog-admin-1',
      );

      expect(approved.canPromoteOfficially, isTrue);
      expect(approved.officialPackMutation, isFalse);
      expect(approved.reviewedBy, 'catalog-admin-1');
      expect(approved.status, _LearningProposalStatus.approved);
    });

    test('rejected corrections remain isolated from official packs', () {
      final rejected = _LearningProposal.aliasFrom(
        _CorrectionEvent.example(),
      ).reject(reason: 'Wrong item family after review.');

      expect(rejected.status, _LearningProposalStatus.rejected);
      expect(rejected.canPromoteOfficially, isFalse);
      expect(rejected.officialPackMutation, isFalse);
      expect(rejected.rejectionReason, contains('Wrong item family'));
      expect(rejected.safetyRuleIds, contains('correction_can_be_rejected'));
      expect(
        rejected.safetyRuleIds,
        contains('correction_never_silently_mutates_official_pack'),
      );
    });

    test('before and after item evidence stays attached to correction', () {
      final correction = _CorrectionEvent.example(
        beforeItemId: 'plumbing.pvc.elbow.3_4',
        afterItemId: 'electrical.pvc.conduit.elbow.3_4',
        candidateEvidence: const [
          _CandidateEvidence(
            itemId: 'plumbing.pvc.elbow.3_4',
            confidence: .71,
            matchedTerms: ['pvc', 'elbow', '3/4'],
            reasons: ['dangerous PVC token', 'missing conduit token'],
          ),
          _CandidateEvidence(
            itemId: 'electrical.pvc.conduit.elbow.3_4',
            confidence: .69,
            matchedTerms: ['pvc', '3/4'],
            reasons: ['trade context missing'],
          ),
        ],
      );
      final proposal = _LearningProposal.negativeRuleFrom(correction);

      expect(proposal.beforeItemId, 'plumbing.pvc.elbow.3_4');
      expect(proposal.afterItemId, 'electrical.pvc.conduit.elbow.3_4');
      expect(proposal.failureCategory, 'ambiguous_trade_material');
      expect(proposal.originalCandidateEvidence, hasLength(2));
      expect(
        proposal.safetyRuleIds,
        contains('correction_keeps_original_candidate_evidence'),
      );
      expect(
        proposal.safetyRuleIds,
        contains('correction_records_before_after_item'),
      );
      expect(
        proposal.safetyRuleIds,
        contains('correction_records_failure_category'),
      );
    });

    test('merchant locale and trade scope prevent correction bleed-over', () {
      final english = _LearningProposal.aliasFrom(
        _CorrectionEvent.example(
          merchantBucket: 'lowes-us',
          localePackId: 'en-US',
          tradeScope: 'Plumbing',
          rawReceiptLine: 'LOWES PEX CRMP ELL 1/2 8.49',
        ),
      );
      final spanish = _LearningProposal.spanishPhraseFrom(
        _CorrectionEvent.example(
          merchantBucket: 'lowes-us',
          localePackId: 'es-US',
          tradeScope: 'Plumbing',
          rawReceiptLine: 'LOWES CODO PEX LATON 1/2 8.49',
        ),
      );
      final electrical = _LearningProposal.aliasFrom(
        _CorrectionEvent.example(
          merchantBucket: 'lowes-us',
          localePackId: 'en-US',
          tradeScope: 'Electrical',
          rawReceiptLine: 'LOWES PVC COND ELL 1/2 8.49',
          afterItemId: 'electrical.pvc.conduit.elbow.1_2',
        ),
      );

      expect(english.scopeKey, isNot(spanish.scopeKey));
      expect(english.scopeKey, isNot(electrical.scopeKey));
      expect(spanish.kind, _LearningProposalKind.spanishPhrase);
      expect(spanish.localePackId, 'es-US');
      expect(
        spanish.safetyRuleIds,
        contains('correction_scopes_to_merchant_locale_trade'),
      );
    });

    test('admin diagnostic signal is useful without private receipt content', () {
      final proposal = _LearningProposal.aliasFrom(
        _CorrectionEvent.example(
          rawReceiptLine:
              'LOWES 4111 1111 1111 1111 PEX CRMP ELL CARD 1234 8.49',
          deviceClass: 'older_android',
          deviceModelBucket: 'galaxy-s9-class',
          packVersion: 'plumbing-core-en-us-2026.07',
          parserVersion: 'parser-v3',
          candidateCount: 4,
          unknownRate: .03,
          correctionFrequency: .08,
        ),
      );
      final signal = proposal.toAdminDiagnosticSignal();

      expect(signal['device class'], 'older_android');
      expect(signal['device model'], 'galaxy-s9-class');
      expect(signal['pack version'], 'plumbing-core-en-us-2026.07');
      expect(signal['parser version'], 'parser-v3');
      expect(signal['failure category'], 'ambiguous_trade_material');
      expect(signal['trade'], 'Plumbing');
      expect(signal['item id'], 'plumbing.pex.crimp.elbow.brass.1_2');
      expect(signal['candidate count'], 4);
      expect(signal['unknown rate'], .03);
      expect(signal['correction frequency'], .08);
      expect(signal.values.join(' '), isNot(contains('4111')));
      expect(signal.values.join(' '), isNot(contains('1234')));
      expect(signal.values.join(' '), isNot(contains('PEX CRMP')));
      expect(
        proposal.safetyRuleIds,
        contains('correction_redacts_private_receipt_text'),
      );
      expect(
        proposal.safetyRuleIds,
        contains('correction_does_not_log_card_data'),
      );
    });

    test('regression fixture output is redacted and source-traceable', () {
      final proposal = _LearningProposal.regressionFixtureFrom(
        _CorrectionEvent.example(
          rawReceiptLine: 'FERGUSON VISA 1234 BR PEX 90 1/2 8.49',
          parserVersion: 'parser-v3',
          packVersion: 'plumbing-core-en-us-2026.07',
        ),
      );
      final fixture = proposal.toRegressionFixture();

      expect(fixture['rawReceiptHash'], startsWith('line_hash_'));
      expect(fixture['rawReceiptText'], isNull);
      expect(fixture['expectedItemId'], proposal.afterItemId);
      expect(fixture['merchantBucket'], 'lowes-us');
      expect(fixture['localePackId'], 'en-US');
      expect(fixture['tradeScope'], 'Plumbing');
      expect(fixture['parserVersion'], 'parser-v3');
      expect(fixture['packVersion'], 'plumbing-core-en-us-2026.07');
      expect(fixture.values.join(' '), isNot(contains('VISA')));
      expect(fixture.values.join(' '), isNot(contains('1234')));
      expect(
        proposal.safetyRuleIds,
        contains('correction_can_create_regression_fixture'),
      );
    });
  });
}

Matcher _requiresReview() {
  return predicate<_LearningProposal>(
    (proposal) => proposal.requiresReviewBeforePromotion,
    'correction_requires_review_before_promotion',
  );
}

Matcher _keepsOriginalEvidence() {
  return predicate<_LearningProposal>(
    (proposal) => proposal.originalCandidateEvidence.isNotEmpty,
    'correction_keeps_original_candidate_evidence',
  );
}

Matcher _isScopedToMerchantLocaleTrade() {
  return predicate<_LearningProposal>(
    (proposal) =>
        proposal.scopeKey.contains(proposal.merchantBucket) &&
        proposal.scopeKey.contains(proposal.localePackId) &&
        proposal.scopeKey.contains(proposal.tradeScope.toLowerCase()),
    'correction_scopes_to_merchant_locale_trade',
  );
}

enum _LearningProposalKind {
  proposedAlias,
  negativeRule,
  merchantRule,
  regressionFixture,
  confidenceHint,
  missingVendorMapping,
  localePhrase,
  spanishPhrase,
  itemFamily,
  tradeContext,
}

enum _LearningProposalStatus { pendingReview, approved, rejected }

class _CorrectionLearningPlanner {
  List<_LearningProposal> plan(_CorrectionEvent event) {
    return [
      _LearningProposal.aliasFrom(event),
      _LearningProposal.negativeRuleFrom(event),
      _LearningProposal.merchantRuleFrom(event),
      _LearningProposal.regressionFixtureFrom(event),
      _LearningProposal.confidenceHintFrom(event),
      _LearningProposal.vendorMappingFrom(event),
      _LearningProposal.localePhraseFrom(event),
      _LearningProposal.spanishPhraseFrom(event),
      _LearningProposal.itemFamilyFrom(event),
      _LearningProposal.tradeContextFrom(event),
    ];
  }
}

class _CorrectionEvent {
  const _CorrectionEvent({
    required this.rawReceiptLine,
    required this.beforeItemId,
    required this.afterItemId,
    required this.tradeScope,
    required this.localePackId,
    required this.merchantBucket,
    required this.failureCategory,
    required this.deviceClass,
    required this.deviceModelBucket,
    required this.packVersion,
    required this.parserVersion,
    required this.candidateCount,
    required this.unknownRate,
    required this.correctionFrequency,
    required this.candidateEvidence,
  });

  factory _CorrectionEvent.example({
    String rawReceiptLine = 'LOWES PEX CRMP ELL 1/2 8.49',
    String beforeItemId = 'unknown',
    String afterItemId = 'plumbing.pex.crimp.elbow.brass.1_2',
    String tradeScope = 'Plumbing',
    String localePackId = 'en-US',
    String merchantBucket = 'lowes-us',
    String failureCategory = 'ambiguous_trade_material',
    String deviceClass = 'midrange_android',
    String deviceModelBucket = 'galaxy-a-class',
    String packVersion = 'plumbing-core-en-us-2026.07',
    String parserVersion = 'parser-v3',
    int candidateCount = 3,
    double unknownRate = .04,
    double correctionFrequency = .06,
    List<_CandidateEvidence> candidateEvidence = const [
      _CandidateEvidence(
        itemId: 'unknown',
        confidence: .41,
        matchedTerms: ['pex', 'ell', '1/2'],
        reasons: ['missing crimp synonym', 'merchant abbreviation unknown'],
      ),
    ],
  }) {
    return _CorrectionEvent(
      rawReceiptLine: rawReceiptLine,
      beforeItemId: beforeItemId,
      afterItemId: afterItemId,
      tradeScope: tradeScope,
      localePackId: localePackId,
      merchantBucket: merchantBucket,
      failureCategory: failureCategory,
      deviceClass: deviceClass,
      deviceModelBucket: deviceModelBucket,
      packVersion: packVersion,
      parserVersion: parserVersion,
      candidateCount: candidateCount,
      unknownRate: unknownRate,
      correctionFrequency: correctionFrequency,
      candidateEvidence: candidateEvidence,
    );
  }

  final String rawReceiptLine;
  final String beforeItemId;
  final String afterItemId;
  final String tradeScope;
  final String localePackId;
  final String merchantBucket;
  final String failureCategory;
  final String deviceClass;
  final String deviceModelBucket;
  final String packVersion;
  final String parserVersion;
  final int candidateCount;
  final double unknownRate;
  final double correctionFrequency;
  final List<_CandidateEvidence> candidateEvidence;
}

class _CandidateEvidence {
  const _CandidateEvidence({
    required this.itemId,
    required this.confidence,
    required this.matchedTerms,
    required this.reasons,
  });

  final String itemId;
  final double confidence;
  final List<String> matchedTerms;
  final List<String> reasons;
}

class _LearningProposal {
  const _LearningProposal({
    required this.kind,
    required this.rawReceiptHash,
    required this.beforeItemId,
    required this.afterItemId,
    required this.tradeScope,
    required this.localePackId,
    required this.merchantBucket,
    required this.failureCategory,
    required this.deviceClass,
    required this.deviceModelBucket,
    required this.packVersion,
    required this.parserVersion,
    required this.candidateCount,
    required this.unknownRate,
    required this.correctionFrequency,
    required this.originalCandidateEvidence,
    this.status = _LearningProposalStatus.pendingReview,
    this.reviewedBy,
    this.rejectionReason,
  });

  factory _LearningProposal.aliasFrom(_CorrectionEvent event) =>
      _LearningProposal._from(event, _LearningProposalKind.proposedAlias);

  factory _LearningProposal.negativeRuleFrom(_CorrectionEvent event) =>
      _LearningProposal._from(event, _LearningProposalKind.negativeRule);

  factory _LearningProposal.merchantRuleFrom(_CorrectionEvent event) =>
      _LearningProposal._from(event, _LearningProposalKind.merchantRule);

  factory _LearningProposal.regressionFixtureFrom(_CorrectionEvent event) =>
      _LearningProposal._from(event, _LearningProposalKind.regressionFixture);

  factory _LearningProposal.confidenceHintFrom(_CorrectionEvent event) =>
      _LearningProposal._from(event, _LearningProposalKind.confidenceHint);

  factory _LearningProposal.vendorMappingFrom(_CorrectionEvent event) =>
      _LearningProposal._from(event, _LearningProposalKind.missingVendorMapping);

  factory _LearningProposal.localePhraseFrom(_CorrectionEvent event) =>
      _LearningProposal._from(event, _LearningProposalKind.localePhrase);

  factory _LearningProposal.spanishPhraseFrom(_CorrectionEvent event) =>
      _LearningProposal._from(event, _LearningProposalKind.spanishPhrase);

  factory _LearningProposal.itemFamilyFrom(_CorrectionEvent event) =>
      _LearningProposal._from(event, _LearningProposalKind.itemFamily);

  factory _LearningProposal.tradeContextFrom(_CorrectionEvent event) =>
      _LearningProposal._from(event, _LearningProposalKind.tradeContext);

  factory _LearningProposal._from(
    _CorrectionEvent event,
    _LearningProposalKind kind,
  ) {
    return _LearningProposal(
      kind: kind,
      rawReceiptHash: _hashReceiptLine(event.rawReceiptLine),
      beforeItemId: event.beforeItemId,
      afterItemId: event.afterItemId,
      tradeScope: event.tradeScope,
      localePackId: event.localePackId,
      merchantBucket: event.merchantBucket,
      failureCategory: event.failureCategory,
      deviceClass: event.deviceClass,
      deviceModelBucket: event.deviceModelBucket,
      packVersion: event.packVersion,
      parserVersion: event.parserVersion,
      candidateCount: event.candidateCount,
      unknownRate: event.unknownRate,
      correctionFrequency: event.correctionFrequency,
      originalCandidateEvidence: event.candidateEvidence,
    );
  }

  final _LearningProposalKind kind;
  final String rawReceiptHash;
  final String beforeItemId;
  final String afterItemId;
  final String tradeScope;
  final String localePackId;
  final String merchantBucket;
  final String failureCategory;
  final String deviceClass;
  final String deviceModelBucket;
  final String packVersion;
  final String parserVersion;
  final int candidateCount;
  final double unknownRate;
  final double correctionFrequency;
  final List<_CandidateEvidence> originalCandidateEvidence;
  final _LearningProposalStatus status;
  final String? reviewedBy;
  final String? rejectionReason;

  bool get officialPackMutation => false;

  bool get requiresReviewBeforePromotion =>
      status != _LearningProposalStatus.approved;

  bool get canPromoteOfficially =>
      status == _LearningProposalStatus.approved && reviewedBy != null;

  String get scopeKey =>
      '$merchantBucket|$localePackId|${tradeScope.toLowerCase()}';

  Set<String> get safetyRuleIds => const {
    'correction_never_silently_mutates_official_pack',
    'correction_requires_review_before_promotion',
    'correction_keeps_original_candidate_evidence',
    'correction_records_before_after_item',
    'correction_records_failure_category',
    'correction_redacts_private_receipt_text',
    'correction_does_not_log_card_data',
    'correction_can_be_rejected',
    'correction_can_create_regression_fixture',
    'correction_scopes_to_merchant_locale_trade',
  };

  _LearningProposal approveForManualPromotion({required String reviewerId}) {
    return _copyWith(
      status: _LearningProposalStatus.approved,
      reviewedBy: reviewerId,
    );
  }

  _LearningProposal reject({required String reason}) {
    return _copyWith(
      status: _LearningProposalStatus.rejected,
      rejectionReason: reason,
    );
  }

  Map<String, Object?> toAdminDiagnosticSignal() {
    return {
      'device class': deviceClass,
      'device model': deviceModelBucket,
      'pack version': packVersion,
      'parser version': parserVersion,
      'failure category': failureCategory,
      'trade': tradeScope,
      'item id': afterItemId,
      'candidate count': candidateCount,
      'unknown rate': unknownRate,
      'correction frequency': correctionFrequency,
      'raw receipt hash': rawReceiptHash,
    };
  }

  Map<String, Object?> toRegressionFixture() {
    return {
      'rawReceiptHash': rawReceiptHash,
      'rawReceiptText': null,
      'expectedItemId': afterItemId,
      'merchantBucket': merchantBucket,
      'localePackId': localePackId,
      'tradeScope': tradeScope,
      'parserVersion': parserVersion,
      'packVersion': packVersion,
      'failureCategory': failureCategory,
    };
  }

  _LearningProposal _copyWith({
    required _LearningProposalStatus status,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return _LearningProposal(
      kind: kind,
      rawReceiptHash: rawReceiptHash,
      beforeItemId: beforeItemId,
      afterItemId: afterItemId,
      tradeScope: tradeScope,
      localePackId: localePackId,
      merchantBucket: merchantBucket,
      failureCategory: failureCategory,
      deviceClass: deviceClass,
      deviceModelBucket: deviceModelBucket,
      packVersion: packVersion,
      parserVersion: parserVersion,
      candidateCount: candidateCount,
      unknownRate: unknownRate,
      correctionFrequency: correctionFrequency,
      originalCandidateEvidence: originalCandidateEvidence,
      status: status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

String _hashReceiptLine(String raw) {
  final sanitized = raw
      .replaceAll(RegExp(r'\b\d{4}([ -]?\d{4}){2,3}\b'), '[CARD]')
      .replaceAll(RegExp(r'\b(card|visa|mastercard)\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();
  final hash = sanitized.codeUnits.fold<int>(
    17,
    (value, codeUnit) => (value * 37 + codeUnit) & 0x3fffffff,
  );
  return 'line_hash_${hash.toRadixString(16)}';
}
