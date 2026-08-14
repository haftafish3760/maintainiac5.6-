/// Review-only candidate evidence for the GPS App Assistant.
///
/// Owns a bounded, coordinate-free description of a possible vehicle movement
/// and its user-review lifecycle. It does not own GPS samples, sessions,
/// odometer values, TripLog records, or business classification. Consumed by
/// the automatic evidence inbox before an explicit user opens an editable
/// workday/trip review. A candidate can never confirm a business record.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'trip_automatic_start_detector.dart';

enum TripAutomaticEvidenceCandidateState {
  reviewNeeded,
  approvedForEditableReview,
  rejected,
  expired,
}

enum TripAutomaticEvidenceCandidateAction {
  detected,
  approved,
  rejected,
  expired,
}

class TripAutomaticEvidenceCandidateAudit {
  const TripAutomaticEvidenceCandidateAudit({
    required this.action,
    required this.recordedAtUtc,
  });

  final TripAutomaticEvidenceCandidateAction action;
  final DateTime recordedAtUtc;

  Map<String, Object?> toMap() => {
    'action': action.name,
    'recordedAtUtc': recordedAtUtc.toUtc().toIso8601String(),
  };

  static TripAutomaticEvidenceCandidateAudit? fromMap(Object? value) {
    if (value is! Map) return null;
    final actionName = value['action'];
    if (actionName is! String) return null;
    TripAutomaticEvidenceCandidateAction? action;
    for (final candidate in TripAutomaticEvidenceCandidateAction.values) {
      if (candidate.name == actionName) {
        action = candidate;
        break;
      }
    }
    if (action == null) return null;
    final recordedAt = DateTime.tryParse(
      value['recordedAtUtc']?.toString() ?? '',
    )?.toUtc();
    if (recordedAt == null) return null;
    return TripAutomaticEvidenceCandidateAudit(
      action: action,
      recordedAtUtc: recordedAt,
    );
  }
}

class TripAutomaticEvidenceCandidate {
  /// Candidate evidence never owns mileage truth; the physical odometer does.
  static const bool odometerIsGlobalTruth = true;

  const TripAutomaticEvidenceCandidate._({
    required this.id,
    required this.revision,
    required this.state,
    required this.detectedAtUtc,
    required this.evidenceStartedAtUtc,
    required this.evidenceEndedAtUtc,
    required this.reasonCode,
    required this.evidenceSources,
    required this.auditHistory,
    required this.requiresPaidEntitlementOnAcceptance,
    required this.allowancePeriodKey,
    required this.freeUseLimitAtDetection,
    required this.consumesFreeUseIfAccepted,
    this.suggestedVehicleId,
  });

  static const schemaVersion = 1;

  final String id;
  final int revision;
  final TripAutomaticEvidenceCandidateState state;
  final DateTime detectedAtUtc;
  final DateTime evidenceStartedAtUtc;
  final DateTime evidenceEndedAtUtc;
  final String reasonCode;
  final List<String> evidenceSources;
  final List<TripAutomaticEvidenceCandidateAudit> auditHistory;
  final bool requiresPaidEntitlementOnAcceptance;
  final String? allowancePeriodKey;
  final int freeUseLimitAtDetection;
  final bool consumesFreeUseIfAccepted;
  final String? suggestedVehicleId;

  bool get requiresUserReview =>
      state == TripAutomaticEvidenceCandidateState.reviewNeeded;
  bool get canCreateConfirmedRecord => false;
  bool get canConfirmMileage => false;
  bool get canAssignBusinessPurpose => false;
  bool get canClassifyMileage => false;

  String get evidenceStrength => switch (evidenceSources.length) {
    >= 3 => 'supported',
    2 => 'corroborated',
    _ => 'limited',
  };

  String get explanation =>
      'Maintainiac noticed possible vehicle movement from ${evidenceSources.join(', ')}. '
      'Review it before creating any workday or trip record.';

  String get expectedResultIfApproved =>
      'Keeps this evidence for a later editable review. No odometer, trip, stop, vehicle, profile, or '
      'business classification is confirmed by this approval.';

  String get resultIfRejected =>
      'Keeps an audit of the rejection but makes no workday, mileage, or business record.';

  factory TripAutomaticEvidenceCandidate.fromDecision({
    required TripAutomaticStartDecision decision,
    required DateTime detectedAt,
  }) {
    if (!decision.shouldCreateReviewCandidate ||
        decision.evidenceStartedAt == null ||
        decision.evidenceEndedAt == null) {
      throw ArgumentError(
        'Only a current automatic-evidence candidate can be stored.',
      );
    }
    final startedAt = decision.evidenceStartedAt!.toUtc();
    final endedAt = decision.evidenceEndedAt!.toUtc();
    final detectedAtUtc = detectedAt.toUtc();
    if (endedAt.isBefore(startedAt) || detectedAtUtc.isBefore(endedAt)) {
      throw ArgumentError('Automatic evidence timestamps are inconsistent.');
    }
    final sources = <String>[
      'currentVehicleMovement',
      if (decision.suggestedVehicleId != null) 'knownVehicleBluetooth',
      if (decision.disposition == TripAutomaticStartDisposition.candidate)
        'multiSignalVehicleEvidence',
    ];
    final id = _candidateId(
      startedAt: startedAt,
      endedAt: endedAt,
      reasonCode: decision.reasonCode,
      suggestedVehicleId: decision.suggestedVehicleId,
    );
    return TripAutomaticEvidenceCandidate._(
      id: id,
      revision: 1,
      state: TripAutomaticEvidenceCandidateState.reviewNeeded,
      detectedAtUtc: detectedAtUtc,
      evidenceStartedAtUtc: startedAt,
      evidenceEndedAtUtc: endedAt,
      reasonCode: decision.reasonCode,
      evidenceSources: List<String>.unmodifiable(sources),
      auditHistory: List<TripAutomaticEvidenceCandidateAudit>.unmodifiable([
        TripAutomaticEvidenceCandidateAudit(
          action: TripAutomaticEvidenceCandidateAction.detected,
          recordedAtUtc: detectedAtUtc,
        ),
      ]),
      requiresPaidEntitlementOnAcceptance:
          decision.requiresPaidEntitlementOnAcceptance,
      allowancePeriodKey: decision.allowanceDecision?.periodKey,
      freeUseLimitAtDetection: decision.allowanceDecision?.freeLimit ?? 0,
      consumesFreeUseIfAccepted:
          decision.allowanceDecision?.consumesFreeUseIfAccepted ?? false,
      suggestedVehicleId: _safeId(decision.suggestedVehicleId),
    );
  }

  TripAutomaticEvidenceCandidate resolve({
    required bool approved,
    required DateTime decidedAt,
  }) {
    if (!requiresUserReview) {
      throw StateError('A candidate can only be decided once.');
    }
    final decidedAtUtc = decidedAt.toUtc();
    if (decidedAtUtc.isBefore(detectedAtUtc)) {
      throw ArgumentError('A candidate decision cannot predate detection.');
    }
    final action = approved
        ? TripAutomaticEvidenceCandidateAction.approved
        : TripAutomaticEvidenceCandidateAction.rejected;
    return TripAutomaticEvidenceCandidate._(
      id: id,
      revision: revision + 1,
      state: approved
          ? TripAutomaticEvidenceCandidateState.approvedForEditableReview
          : TripAutomaticEvidenceCandidateState.rejected,
      detectedAtUtc: detectedAtUtc,
      evidenceStartedAtUtc: evidenceStartedAtUtc,
      evidenceEndedAtUtc: evidenceEndedAtUtc,
      reasonCode: reasonCode,
      evidenceSources: evidenceSources,
      auditHistory: List<TripAutomaticEvidenceCandidateAudit>.unmodifiable([
        ...auditHistory,
        TripAutomaticEvidenceCandidateAudit(
          action: action,
          recordedAtUtc: decidedAtUtc,
        ),
      ]),
      requiresPaidEntitlementOnAcceptance: requiresPaidEntitlementOnAcceptance,
      allowancePeriodKey: allowancePeriodKey,
      freeUseLimitAtDetection: freeUseLimitAtDetection,
      consumesFreeUseIfAccepted: consumesFreeUseIfAccepted,
      suggestedVehicleId: suggestedVehicleId,
    );
  }

  TripAutomaticEvidenceCandidate expire({required DateTime expiredAt}) {
    if (!requiresUserReview) return this;
    final expiredAtUtc = expiredAt.toUtc();
    if (expiredAtUtc.isBefore(detectedAtUtc)) {
      throw ArgumentError('Candidate expiration cannot predate detection.');
    }
    return TripAutomaticEvidenceCandidate._(
      id: id,
      revision: revision + 1,
      state: TripAutomaticEvidenceCandidateState.expired,
      detectedAtUtc: detectedAtUtc,
      evidenceStartedAtUtc: evidenceStartedAtUtc,
      evidenceEndedAtUtc: evidenceEndedAtUtc,
      reasonCode: reasonCode,
      evidenceSources: evidenceSources,
      auditHistory: List<TripAutomaticEvidenceCandidateAudit>.unmodifiable([
        ...auditHistory,
        TripAutomaticEvidenceCandidateAudit(
          action: TripAutomaticEvidenceCandidateAction.expired,
          recordedAtUtc: expiredAtUtc,
        ),
      ]),
      requiresPaidEntitlementOnAcceptance: requiresPaidEntitlementOnAcceptance,
      allowancePeriodKey: allowancePeriodKey,
      freeUseLimitAtDetection: freeUseLimitAtDetection,
      consumesFreeUseIfAccepted: consumesFreeUseIfAccepted,
      suggestedVehicleId: suggestedVehicleId,
    );
  }

  Map<String, Object?> toMap() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'revision': revision,
    'state': state.name,
    'detectedAtUtc': detectedAtUtc.toUtc().toIso8601String(),
    'evidenceStartedAtUtc': evidenceStartedAtUtc.toUtc().toIso8601String(),
    'evidenceEndedAtUtc': evidenceEndedAtUtc.toUtc().toIso8601String(),
    'reasonCode': reasonCode,
    'evidenceSources': evidenceSources,
    'auditHistory': auditHistory.map((item) => item.toMap()).toList(),
    'requiresPaidEntitlementOnAcceptance': requiresPaidEntitlementOnAcceptance,
    if (allowancePeriodKey != null) 'allowancePeriodKey': allowancePeriodKey,
    'freeUseLimitAtDetection': freeUseLimitAtDetection,
    'consumesFreeUseIfAccepted': consumesFreeUseIfAccepted,
    if (suggestedVehicleId != null) 'suggestedVehicleId': suggestedVehicleId,
    'canCreateConfirmedRecord': false,
    'canConfirmMileage': false,
    'canAssignBusinessPurpose': false,
    'canClassifyMileage': false,
    'coordinatesIncluded': false,
  };

  static TripAutomaticEvidenceCandidate? fromMap(Object? value) {
    if (value is! Map || value['schemaVersion'] != schemaVersion) return null;
    final id = _safeId(value['id']?.toString());
    final reasonCode = _safeReasonCode(value['reasonCode']?.toString());
    final revision = value['revision'];
    final stateName = value['state'];
    TripAutomaticEvidenceCandidateState? state;
    if (stateName is String) {
      for (final candidate in TripAutomaticEvidenceCandidateState.values) {
        if (candidate.name == stateName) {
          state = candidate;
          break;
        }
      }
    }
    final detectedAt = DateTime.tryParse(
      value['detectedAtUtc']?.toString() ?? '',
    )?.toUtc();
    final startedAt = DateTime.tryParse(
      value['evidenceStartedAtUtc']?.toString() ?? '',
    )?.toUtc();
    final endedAt = DateTime.tryParse(
      value['evidenceEndedAtUtc']?.toString() ?? '',
    )?.toUtc();
    final sources = value['evidenceSources'];
    final audits = value['auditHistory'];
    if (id == null ||
        reasonCode == null ||
        state == null ||
        revision is! int ||
        revision < 1 ||
        detectedAt == null ||
        startedAt == null ||
        endedAt == null ||
        endedAt.isBefore(startedAt) ||
        detectedAt.isBefore(endedAt) ||
        sources is! List ||
        audits is! List) {
      return null;
    }
    final safeSources = sources
        .map((item) => item is String ? _safeSource(item) : null)
        .whereType<String>()
        .toList(growable: false);
    final safeAudits = audits
        .map(TripAutomaticEvidenceCandidateAudit.fromMap)
        .whereType<TripAutomaticEvidenceCandidateAudit>()
        .toList(growable: false);
    final suggestedVehicleId = _safeId(value['suggestedVehicleId']?.toString());
    final hasAllowanceMetadata = value.containsKey('allowancePeriodKey');
    final allowancePeriodKey = _safePeriodKey(
      value['allowancePeriodKey']?.toString(),
    );
    final freeUseLimit = value['freeUseLimitAtDetection'];
    final normalizedFreeUseLimit = freeUseLimit is int && freeUseLimit >= 0
        ? freeUseLimit
        : 0;
    if (safeSources.isEmpty ||
        safeSources.length != sources.length ||
        safeAudits.isEmpty ||
        safeAudits.length != audits.length ||
        (hasAllowanceMetadata && allowancePeriodKey == null) ||
        !_auditHistoryIsValid(
          state: state,
          revision: revision,
          detectedAt: detectedAt,
          audits: safeAudits,
        ) ||
        id !=
            _candidateId(
              startedAt: startedAt,
              endedAt: endedAt,
              reasonCode: reasonCode,
              suggestedVehicleId: suggestedVehicleId,
            )) {
      return null;
    }
    return TripAutomaticEvidenceCandidate._(
      id: id,
      revision: revision,
      state: state,
      detectedAtUtc: detectedAt,
      evidenceStartedAtUtc: startedAt,
      evidenceEndedAtUtc: endedAt,
      reasonCode: reasonCode,
      evidenceSources: List<String>.unmodifiable(safeSources),
      auditHistory: List<TripAutomaticEvidenceCandidateAudit>.unmodifiable(
        safeAudits,
      ),
      // Legacy candidates predate the durable allowance meter. Fail closed on
      // acceptance instead of granting an unmetered free use.
      requiresPaidEntitlementOnAcceptance:
          !hasAllowanceMetadata ||
          value['requiresPaidEntitlementOnAcceptance'] == true,
      allowancePeriodKey: allowancePeriodKey,
      freeUseLimitAtDetection: normalizedFreeUseLimit,
      consumesFreeUseIfAccepted: value['consumesFreeUseIfAccepted'] == true,
      suggestedVehicleId: suggestedVehicleId,
    );
  }
}

bool _auditHistoryIsValid({
  required TripAutomaticEvidenceCandidateState state,
  required int revision,
  required DateTime detectedAt,
  required List<TripAutomaticEvidenceCandidateAudit> audits,
}) {
  if (audits.length != revision ||
      audits.first.action != TripAutomaticEvidenceCandidateAction.detected ||
      audits.first.recordedAtUtc.toUtc() != detectedAt.toUtc()) {
    return false;
  }
  for (var index = 1; index < audits.length; index += 1) {
    if (audits[index].recordedAtUtc.toUtc().isBefore(
      audits[index - 1].recordedAtUtc.toUtc(),
    )) {
      return false;
    }
  }
  final expectedFinalAction = switch (state) {
    TripAutomaticEvidenceCandidateState.reviewNeeded =>
      TripAutomaticEvidenceCandidateAction.detected,
    TripAutomaticEvidenceCandidateState.approvedForEditableReview =>
      TripAutomaticEvidenceCandidateAction.approved,
    TripAutomaticEvidenceCandidateState.rejected =>
      TripAutomaticEvidenceCandidateAction.rejected,
    TripAutomaticEvidenceCandidateState.expired =>
      TripAutomaticEvidenceCandidateAction.expired,
  };
  return audits.last.action == expectedFinalAction &&
      (state == TripAutomaticEvidenceCandidateState.reviewNeeded
          ? audits.length == 1
          : audits.length == 2);
}

String _candidateId({
  required DateTime startedAt,
  required DateTime endedAt,
  required String reasonCode,
  required String? suggestedVehicleId,
}) {
  final parts = [
    startedAt.microsecondsSinceEpoch.toString(),
    endedAt.microsecondsSinceEpoch.toString(),
    reasonCode,
    suggestedVehicleId ?? '',
  ];
  final fingerprint = parts.map((item) => '${item.length}:$item').join('|');
  return 'automatic-evidence-${sha256.convert(utf8.encode(fingerprint)).toString().substring(0, 32)}';
}

String? _safeId(String? value) {
  final clean = value?.trim() ?? '';
  return clean.isNotEmpty &&
          clean.length <= 160 &&
          RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean)
      ? clean
      : null;
}

String? _safeReasonCode(String? value) {
  final clean = value?.trim() ?? '';
  return clean.isNotEmpty &&
          clean.length <= 80 &&
          RegExp(r'^[a-z0-9_]+$').hasMatch(clean)
      ? clean
      : null;
}

String? _safeSource(String value) {
  final clean = value.trim();
  return clean.isNotEmpty &&
          clean.length <= 48 &&
          RegExp(r'^[A-Za-z0-9_]+$').hasMatch(clean)
      ? clean
      : null;
}

String? _safePeriodKey(String? value) {
  final clean = value?.trim() ?? '';
  return RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(clean) ? clean : null;
}
