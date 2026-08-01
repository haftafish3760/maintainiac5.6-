// odometerIsGlobalTruth: true.
import 'automatic_evidence_capture_allowance_policy.dart';
import 'trip_tracking_models.dart';

enum TripAutomaticStartDisposition {
  disabled,
  paidEntitlementRequired,
  activeSessionExists,
  insufficientEvidence,
  candidate,
}

enum TripAutomaticStartAccessLevel { free, paid }

class TripAutomaticStartObservation {
  const TripAutomaticStartObservation({
    required this.recordedAt,
    required this.speedMetersPerSecond,
    required this.displacementMeters,
    required this.horizontalAccuracyMeters,
    this.activity = TripActivity.unknown,
    this.activityConfidence = 0,
    this.bluetoothVehicleId,
  });

  final DateTime recordedAt;
  final double speedMetersPerSecond;
  final double displacementMeters;
  final double horizontalAccuracyMeters;
  final TripActivity activity;
  final int activityConfidence;
  final String? bluetoothVehicleId;
}

class TripAutomaticStartDecision {
  const TripAutomaticStartDecision({
    required this.disposition,
    required this.reasonCode,
    required this.confidence,
    required this.evidenceStartedAt,
    required this.evidenceEndedAt,
    required this.suggestedVehicleId,
    this.allowanceDecision,
  });

  final TripAutomaticStartDisposition disposition;
  final String reasonCode;
  final TripTrackingConfidence confidence;
  final DateTime? evidenceStartedAt;
  final DateTime? evidenceEndedAt;
  final String? suggestedVehicleId;
  final AutomaticEvidenceCaptureAllowanceDecision? allowanceDecision;

  bool get shouldSuggestStart =>
      disposition == TripAutomaticStartDisposition.candidate;
  bool get requiresPaidEntitlement =>
      disposition == TripAutomaticStartDisposition.paidEntitlementRequired;
  bool get canInventStartingOdometer => false;
  bool get canAssignBusinessPurpose => false;
  bool get canAssignJob => false;
  bool get canFinalizeTripLog => false;
  bool get canClassifyMileage => false;

  Map<String, Object?> toMap() => {
    'schemaVersion': 1,
    'disposition': disposition.name,
    'reasonCode': reasonCode,
    'confidence': confidence.name,
    'evidenceStartedAt': evidenceStartedAt?.toUtc().toIso8601String(),
    'evidenceEndedAt': evidenceEndedAt?.toUtc().toIso8601String(),
    'suggestedVehicleId': _safeVehicleId(suggestedVehicleId),
    'shouldSuggestStart': shouldSuggestStart,
    'requiresPaidEntitlement': requiresPaidEntitlement,
    'paidEntitlementVerified':
        disposition == TripAutomaticStartDisposition.candidate,
    'canInventStartingOdometer': false,
    'canAssignBusinessPurpose': false,
    'canAssignJob': false,
    'canFinalizeTripLog': false,
    'canClassifyMileage': false,
    'coordinatesIncluded': false,
    'confidenceScoreShown': false,
    'allowance': allowanceDecision?.toSafeMap(),
  };
}

class TripAutomaticStartDetector {
  const TripAutomaticStartDetector({
    this.minimumEvidenceSpan = const Duration(seconds: 20),
    this.maximumEvidenceWindow = const Duration(minutes: 2),
    this.maximumObservationAge = const Duration(minutes: 2),
    this.minimumMovingObservations = 3,
    this.minimumSpeedMetersPerSecond = 3,
    this.minimumDisplacementMeters = 10,
    this.maximumAccuracyMeters = 50,
    this.minimumActivityConfidence = 70,
  });

  final Duration minimumEvidenceSpan;
  final Duration maximumEvidenceWindow;
  final Duration maximumObservationAge;
  final int minimumMovingObservations;
  final double minimumSpeedMetersPerSecond;
  final double minimumDisplacementMeters;
  final double maximumAccuracyMeters;
  final int minimumActivityConfidence;

  TripAutomaticStartDecision evaluate({
    required bool enabled,
    required TripAutomaticStartAccessLevel accessLevel,
    required bool hasActiveOrRecoverableSession,
    required Iterable<TripAutomaticStartObservation> observations,
    required DateTime evaluatedAt,
    int acceptedFreeUsesInPeriod = 0,
    AutomaticEvidenceCaptureAllowancePolicy allowancePolicy =
        const AutomaticEvidenceCaptureAllowancePolicy(),
  }) {
    if (!enabled) return _decision(TripAutomaticStartDisposition.disabled);
    if (hasActiveOrRecoverableSession) {
      return _decision(TripAutomaticStartDisposition.activeSessionExists);
    }
    final ordered = observations.toList(growable: false)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    if (ordered.isEmpty) {
      return _decision(TripAutomaticStartDisposition.insufficientEvidence);
    }
    final latestAt = ordered.last.recordedAt.toUtc();
    final now = evaluatedAt.toUtc();
    if (latestAt.isAfter(now) ||
        now.difference(latestAt) > maximumObservationAge) {
      return _decision(
        TripAutomaticStartDisposition.insufficientEvidence,
        reasonCode: 'stale_or_future_automatic_evidence',
      );
    }
    final allowance = allowancePolicy.evaluate(
      access: accessLevel == TripAutomaticStartAccessLevel.paid
          ? AutomaticEvidenceCaptureAccess.paid
          : AutomaticEvidenceCaptureAccess.free,
      occurredAt: latestAt,
      acceptedFreeUsesInPeriod: acceptedFreeUsesInPeriod,
    );
    if (!allowance.allowed) {
      return _decision(
        TripAutomaticStartDisposition.paidEntitlementRequired,
        allowanceDecision: allowance,
      );
    }
    final window = ordered
        .where(
          (item) =>
              !item.recordedAt.toUtc().isAfter(latestAt) &&
              latestAt.difference(item.recordedAt.toUtc()) <=
                  maximumEvidenceWindow,
        )
        .toList(growable: false);
    final moving = window
        .where(
          (item) =>
              item.speedMetersPerSecond.isFinite &&
              item.speedMetersPerSecond >= minimumSpeedMetersPerSecond &&
              item.displacementMeters.isFinite &&
              item.displacementMeters >= minimumDisplacementMeters &&
              item.horizontalAccuracyMeters.isFinite &&
              item.horizontalAccuracyMeters >= 0 &&
              item.horizontalAccuracyMeters <= maximumAccuracyMeters,
        )
        .toList(growable: false);
    final hasTimeSpan =
        moving.length >= 2 &&
        moving.last.recordedAt.toUtc().difference(
              moving.first.recordedAt.toUtc(),
            ) >=
            minimumEvidenceSpan;
    final automotiveEvidence = window.any(
      (item) =>
          item.activity == TripActivity.automotive &&
          item.activityConfidence >= minimumActivityConfidence,
    );
    final bluetoothVehicleIds = window
        .map((item) => _safeVehicleId(item.bluetoothVehicleId))
        .whereType<String>()
        .toSet();
    final bluetoothCorroborated = bluetoothVehicleIds.length == 1;
    if (moving.length < minimumMovingObservations ||
        !hasTimeSpan ||
        (!automotiveEvidence && !bluetoothCorroborated)) {
      return _decision(
        TripAutomaticStartDisposition.insufficientEvidence,
        startedAt: moving.isEmpty ? null : moving.first.recordedAt,
        endedAt: moving.isEmpty ? null : moving.last.recordedAt,
      );
    }
    return _decision(
      TripAutomaticStartDisposition.candidate,
      confidence: automotiveEvidence && bluetoothCorroborated
          ? TripTrackingConfidence.high
          : TripTrackingConfidence.medium,
      startedAt: moving.first.recordedAt,
      endedAt: moving.last.recordedAt,
      vehicleId: bluetoothCorroborated ? bluetoothVehicleIds.single : null,
      allowanceDecision: allowance,
    );
  }

  TripAutomaticStartDecision _decision(
    TripAutomaticStartDisposition disposition, {
    TripTrackingConfidence confidence = TripTrackingConfidence.unknown,
    DateTime? startedAt,
    DateTime? endedAt,
    String? vehicleId,
    String? reasonCode,
    AutomaticEvidenceCaptureAllowanceDecision? allowanceDecision,
  }) => TripAutomaticStartDecision(
    disposition: disposition,
    reasonCode:
        reasonCode ??
        switch (disposition) {
          TripAutomaticStartDisposition.disabled => 'automatic_start_disabled',
          TripAutomaticStartDisposition.paidEntitlementRequired =>
            'paid_automatic_tracking_required',
          TripAutomaticStartDisposition.activeSessionExists =>
            'active_or_recoverable_session_exists',
          TripAutomaticStartDisposition.insufficientEvidence =>
            'insufficient_multi_signal_movement_evidence',
          TripAutomaticStartDisposition.candidate =>
            'probable_vehicle_movement_candidate',
        },
    confidence: confidence,
    evidenceStartedAt: startedAt?.toUtc(),
    evidenceEndedAt: endedAt?.toUtc(),
    suggestedVehicleId: _safeVehicleId(vehicleId),
    allowanceDecision: allowanceDecision,
  );
}

String? _safeVehicleId(String? value) {
  final clean = value?.trim() ?? '';
  if (clean.isEmpty || clean.length > 160) return null;
  return RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean) ? clean : null;
}
