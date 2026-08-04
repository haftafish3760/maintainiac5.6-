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
    final action = TripAutomaticEvidenceCandidateAction.values.firstWhere(
      (item) => item.name == value['action'],
      orElse: () => TripAutomaticEvidenceCandidateAction.detected,
    );
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
      'Opens an editable review. No odometer, trip, stop, vehicle, profile, or '
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
      detectedAtUtc: detectedAt.toUtc(),
      evidenceStartedAtUtc: startedAt,
      evidenceEndedAtUtc: endedAt,
      reasonCode: decision.reasonCode,
      evidenceSources: List<String>.unmodifiable(sources),
      auditHistory: List<TripAutomaticEvidenceCandidateAudit>.unmodifiable([
        TripAutomaticEvidenceCandidateAudit(
          action: TripAutomaticEvidenceCandidateAction.detected,
          recordedAtUtc: detectedAt.toUtc(),
        ),
      ]),
      requiresPaidEntitlementOnAcceptance:
          decision.requiresPaidEntitlementOnAcceptance,
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
          recordedAtUtc: decidedAt.toUtc(),
        ),
      ]),
      requiresPaidEntitlementOnAcceptance: requiresPaidEntitlementOnAcceptance,
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
    final state = TripAutomaticEvidenceCandidateState.values.firstWhere(
      (item) => item.name == value['state'],
      orElse: () => TripAutomaticEvidenceCandidateState.expired,
    );
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
        revision is! int ||
        revision < 1 ||
        detectedAt == null ||
        startedAt == null ||
        endedAt == null ||
        endedAt.isBefore(startedAt) ||
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
    if (safeSources.isEmpty ||
        safeSources.length != sources.length ||
        safeAudits.isEmpty) {
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
      requiresPaidEntitlementOnAcceptance:
          value['requiresPaidEntitlementOnAcceptance'] == true,
      suggestedVehicleId: _safeId(value['suggestedVehicleId']?.toString()),
    );
  }
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
