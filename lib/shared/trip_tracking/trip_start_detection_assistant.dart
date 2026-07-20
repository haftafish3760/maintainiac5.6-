import 'trip_tracking_models.dart';
import 'trip_tracking_settings_store.dart';

enum TripStartMotionHint { unknown, stationary, walking, inVehicle }

enum TripStartDetectionDisposition {
  disabled,
  insufficientEvidence,
  suggestStart,
  beginAssistedSession,
}

class TripStartEvidenceObservation {
  const TripStartEvidenceObservation({
    required this.observedAtUtc,
    required this.credibleLocation,
    required this.displacementMeters,
    this.speedMetersPerSecond,
    this.motionHint = TripStartMotionHint.unknown,
    this.bluetoothVehicleMatched = false,
  });

  final DateTime observedAtUtc;
  final bool credibleLocation;
  final double displacementMeters;
  final double? speedMetersPerSecond;
  final TripStartMotionHint motionHint;
  final bool bluetoothVehicleMatched;
}

class TripStartDetectionDecision {
  const TripStartDetectionDecision({
    required this.disposition,
    required this.confidence,
    required this.reasonCode,
    required this.credibleObservationCount,
    required this.totalDisplacementMeters,
  });

  final TripStartDetectionDisposition disposition;
  final TripTrackingConfidence confidence;
  final String reasonCode;
  final int credibleObservationCount;
  final double totalDisplacementMeters;

  bool get shouldBeginAssistedSession =>
      disposition == TripStartDetectionDisposition.beginAssistedSession;

  Map<String, Object?> toSafeSummary() => {
    'disposition': disposition.name,
    'confidence': confidence.name,
    'reasonCode': reasonCode,
    'credibleObservationCount': credibleObservationCount,
    'totalDisplacementMeters': totalDisplacementMeters,
    'canFinalizeTrip': false,
    'canInventOdometer': false,
    'canAssignJob': false,
    'rawLocationsIncluded': false,
  };
}

class TripStartDetectionAssistant {
  const TripStartDetectionAssistant._();

  static TripStartDetectionDecision evaluate({
    required TripTrackingSettings settings,
    required List<TripStartEvidenceObservation> observations,
    required bool hasActiveOrRecoverableSession,
  }) {
    if (!settings.gpsAssistedTrackingEnabled ||
        !settings.assistedStartSuggestionsEnabled ||
        hasActiveOrRecoverableSession) {
      return const TripStartDetectionDecision(
        disposition: TripStartDetectionDisposition.disabled,
        confidence: TripTrackingConfidence.unknown,
        reasonCode: 'assisted_start_disabled_or_session_exists',
        credibleObservationCount: 0,
        totalDisplacementMeters: 0,
      );
    }
    final credible =
        observations
            .where(
              (item) =>
                  item.credibleLocation &&
                  item.displacementMeters.isFinite &&
                  item.displacementMeters >= 0 &&
                  item.displacementMeters <= 5000 &&
                  (item.speedMetersPerSecond == null ||
                      (item.speedMetersPerSecond!.isFinite &&
                          item.speedMetersPerSecond! >= 0 &&
                          item.speedMetersPerSecond! <= 90)),
            )
            .toList()
          ..sort((a, b) => a.observedAtUtc.compareTo(b.observedAtUtc));
    final totalDisplacement = credible.fold<double>(
      0,
      (sum, item) => sum + item.displacementMeters,
    );
    final span = credible.length < 2
        ? Duration.zero
        : credible.last.observedAtUtc.difference(credible.first.observedAtUtc);
    final vehicleSpeedCount = credible
        .where((item) => (item.speedMetersPerSecond ?? 0) >= 3.5)
        .length;
    final independentVehicleHint = credible.any(
      (item) =>
          item.motionHint == TripStartMotionHint.inVehicle ||
          item.bluetoothVehicleMatched,
    );
    final strongGpsPattern =
        credible.length >= 3 &&
        span >= const Duration(seconds: 15) &&
        totalDisplacement >= 80 &&
        vehicleSpeedCount >= 2;
    if (!strongGpsPattern) {
      return TripStartDetectionDecision(
        disposition: TripStartDetectionDisposition.insufficientEvidence,
        confidence: TripTrackingConfidence.low,
        reasonCode: 'assisted_start_requires_sustained_vehicle_evidence',
        credibleObservationCount: credible.length,
        totalDisplacementMeters: totalDisplacement,
      );
    }
    final canBegin =
        settings.automaticAssistedStartEnabled && independentVehicleHint;
    return TripStartDetectionDecision(
      disposition: canBegin
          ? TripStartDetectionDisposition.beginAssistedSession
          : TripStartDetectionDisposition.suggestStart,
      confidence: independentVehicleHint
          ? TripTrackingConfidence.high
          : TripTrackingConfidence.medium,
      reasonCode: canBegin
          ? 'assisted_start_explicit_auto_consent_and_multi_signal'
          : 'assisted_start_suggestion_requires_user_action',
      credibleObservationCount: credible.length,
      totalDisplacementMeters: totalDisplacement,
    );
  }
}
