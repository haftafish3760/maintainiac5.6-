// Explainable plausibility decisions for manual odometer entries.
//
// Owns arithmetic checks using the entered reading, elapsed workday time, and
// confirmed dwell evidence. It does not own GPS, history learning, record
// persistence, business classification, or user confirmation. The global
// odometer controller and Dashboard review flow consume it. It may recommend
// review but must never rewrite or confirm an odometer reading.

import 'odometer_distance_value.dart';

enum OdometerEntryPlausibilityStatus { accepted, reviewRecommended }

class OdometerEntryPlausibilityContext {
  const OdometerEntryPlausibilityContext({
    this.workdayStartedAt,
    this.confirmedDwellDuration = Duration.zero,
    this.confirmedStopCount = 0,
    this.gpsEvidenceAvailable = false,
    this.historicalPatternsEnabled = false,
    this.distanceUnit = OdometerDistanceUnit.miles,
  });

  final DateTime? workdayStartedAt;
  final Duration confirmedDwellDuration;
  final int confirmedStopCount;
  final bool gpsEvidenceAvailable;
  final bool historicalPatternsEnabled;
  final OdometerDistanceUnit distanceUnit;
}

class OdometerEntryPlausibilityDecision {
  const OdometerEntryPlausibilityDecision({
    required this.status,
    required this.reasonCode,
    required this.explanation,
    required this.expectedResultIfAccepted,
    required this.evidenceSources,
    required this.deltaTenths,
    this.minimumAverageSpeed,
  });

  final OdometerEntryPlausibilityStatus status;
  final String reasonCode;
  final String explanation;
  final String expectedResultIfAccepted;
  final List<String> evidenceSources;
  final int deltaTenths;
  final double? minimumAverageSpeed;

  bool get requiresReview =>
      status == OdometerEntryPlausibilityStatus.reviewRecommended;

  Map<String, Object?> toSafeMap() => {
    'status': status.name,
    'reasonCode': reasonCode,
    'explanation': explanation,
    'expectedResultIfAccepted': expectedResultIfAccepted,
    'evidenceSources': List.unmodifiable(evidenceSources),
    'deltaTenths': deltaTenths,
    'minimumAverageSpeed': minimumAverageSpeed,
    'requiresUserReview': requiresReview,
    'canWriteOdometer': false,
    'canClassifyBusinessUse': false,
    'confidenceScoreShown': false,
  };
}

class OdometerEntryPlausibilityPolicy {
  const OdometerEntryPlausibilityPolicy({
    this.reviewAverageMilesPerHour = 85,
    this.manualOnlyReviewMiles = 500,
  });

  final double reviewAverageMilesPerHour;
  final double manualOnlyReviewMiles;

  OdometerEntryPlausibilityDecision evaluate({
    required OdometerDistanceValue current,
    required OdometerDistanceValue candidate,
    required DateTime enteredAt,
    OdometerEntryPlausibilityContext context =
        const OdometerEntryPlausibilityContext(),
  }) {
    if (candidate.unit != current.unit) {
      return _review(
        reasonCode: 'odometer_unit_mismatch',
        explanation:
            'The entered reading uses a different unit than this vehicle. Confirm the vehicle and its miles or kilometers setting.',
        current: current,
        candidate: candidate,
        evidenceSources: const ['manual_odometer', 'vehicle_distance_unit'],
      );
    }
    if (candidate.tenths < current.tenths) {
      return _review(
        reasonCode: 'odometer_lower_than_confirmed',
        explanation:
            'The entered reading is lower than the confirmed vehicle odometer. Choose whether the entry was mistyped, belongs to another vehicle, is backdated, or needs a correction review.',
        current: current,
        candidate: candidate,
        evidenceSources: const ['manual_odometer', 'confirmed_odometer'],
      );
    }
    final deltaTenths = candidate.tenths - current.tenths;
    if (deltaTenths == 0) {
      return _accepted(deltaTenths, const ['manual_odometer']);
    }

    final startedAt = context.workdayStartedAt;
    if (startedAt == null) {
      final thresholdTenths = _manualReviewThresholdTenths(current.unit);
      if (deltaTenths >= thresholdTenths) {
        return _review(
          reasonCode: 'manual_only_large_odometer_jump',
          explanation:
              'This is a large mileage change and no elapsed workday evidence is available. Double-check the vehicle reading before continuing.',
          current: current,
          candidate: candidate,
          evidenceSources: const ['manual_odometer'],
        );
      }
      return _accepted(deltaTenths, const ['manual_odometer']);
    }

    final elapsed = enteredAt.toUtc().difference(startedAt.toUtc());
    final safeDwell = context.confirmedDwellDuration.isNegative
        ? Duration.zero
        : context.confirmedDwellDuration;
    if (elapsed <= Duration.zero || safeDwell >= elapsed) {
      return _review(
        reasonCode: 'odometer_elapsed_time_invalid',
        explanation:
            'The available workday timing cannot explain this mileage. Verify the reading and workday times before continuing.',
        current: current,
        candidate: candidate,
        evidenceSources: const ['manual_odometer', 'workday_elapsed_time'],
      );
    }

    final possibleDrivingHours =
        (elapsed - safeDwell).inMilliseconds / Duration.millisecondsPerHour;
    final distance = deltaTenths / 10;
    final minimumAverageSpeed = distance / possibleDrivingHours;
    final reviewSpeed = _reviewSpeed(current.unit);
    final evidenceSources = <String>[
      'manual_odometer',
      'workday_elapsed_time',
      if (safeDwell > Duration.zero) 'confirmed_stop_dwell',
      if (context.confirmedStopCount > 0) 'confirmed_stop_count',
      if (context.gpsEvidenceAvailable) 'gps_advisory_evidence',
      if (context.historicalPatternsEnabled) 'opted_in_confirmed_history',
    ];
    if (minimumAverageSpeed > reviewSpeed) {
      final unitLabel = current.unit == OdometerDistanceUnit.miles
          ? 'mph'
          : 'km/h';
      return _review(
        reasonCode: 'odometer_speed_plausibility_review',
        explanation:
            'This entry requires at least ${minimumAverageSpeed.toStringAsFixed(1)} $unitLabel across the available driving time. Double-check the reading, vehicle, stops, and workday times.',
        current: current,
        candidate: candidate,
        evidenceSources: evidenceSources,
        minimumAverageSpeed: minimumAverageSpeed,
      );
    }
    return _accepted(
      deltaTenths,
      evidenceSources,
      minimumAverageSpeed: minimumAverageSpeed,
    );
  }

  int _manualReviewThresholdTenths(OdometerDistanceUnit unit) =>
      (manualOnlyReviewMiles *
              (unit == OdometerDistanceUnit.miles ? 1 : 1.609344) *
              10)
          .round();

  double _reviewSpeed(OdometerDistanceUnit unit) =>
      reviewAverageMilesPerHour *
      (unit == OdometerDistanceUnit.miles ? 1 : 1.609344);

  OdometerEntryPlausibilityDecision _accepted(
    int deltaTenths,
    List<String> evidenceSources, {
    double? minimumAverageSpeed,
  }) => OdometerEntryPlausibilityDecision(
    status: OdometerEntryPlausibilityStatus.accepted,
    reasonCode: 'odometer_entry_plausible',
    explanation:
        'The entered reading is plausible from the evidence currently available.',
    expectedResultIfAccepted:
        'The reading may continue to mileage classification and user confirmation.',
    evidenceSources: List.unmodifiable(evidenceSources),
    deltaTenths: deltaTenths,
    minimumAverageSpeed: minimumAverageSpeed,
  );

  OdometerEntryPlausibilityDecision _review({
    required String reasonCode,
    required String explanation,
    required OdometerDistanceValue current,
    required OdometerDistanceValue candidate,
    required List<String> evidenceSources,
    double? minimumAverageSpeed,
  }) => OdometerEntryPlausibilityDecision(
    status: OdometerEntryPlausibilityStatus.reviewRecommended,
    reasonCode: reasonCode,
    explanation: explanation,
    expectedResultIfAccepted:
        'The user-confirmed reading may continue; this policy changes no record by itself.',
    evidenceSources: List.unmodifiable(evidenceSources),
    deltaTenths: candidate.tenths - current.tenths,
    minimumAverageSpeed: minimumAverageSpeed,
  );
}
