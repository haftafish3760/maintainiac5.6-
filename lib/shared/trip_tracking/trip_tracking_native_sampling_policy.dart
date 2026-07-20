import 'trip_tracking_models.dart';
import 'trip_tracking_policy.dart';

class TripTrackingNativeSamplingPolicy {
  const TripTrackingNativeSamplingPolicy._();

  static Map<String, Object?> safeRecommendationSummary({
    required TripSamplingRecommendation? recommendation,
    required bool adaptiveSamplingEnabled,
    required bool nativeTracking,
    required bool platformAvailable,
    required bool sessionAvailable,
  }) => {
    'schemaVersion': 1,
    'hasRecommendation': recommendation != null,
    'mode': recommendation?.mode.name,
    'intervalSeconds': recommendation?.interval.inSeconds,
    'minimumDisplacementMeters': recommendation?.minimumDisplacementMeters,
    'adaptiveSamplingEnabled': adaptiveSamplingEnabled,
    'nativeTracking': nativeTracking,
    'platformAvailable': platformAvailable,
    'sessionAvailable': sessionAvailable,
    'canUpdateNativeCadence':
        recommendation != null &&
        adaptiveSamplingEnabled &&
        nativeTracking &&
        platformAvailable &&
        sessionAvailable,
    'validatedSampleRequired': true,
    'safeDecisionRequired': true,
    'localSessionRequired': true,
    'nativePlatformRequired': true,
    'mockedLocationCanChangeCadence': false,
    'futureSampleCanChangeCadence': false,
    'rejectedInvalidCanChangeCadence': false,
    'stationarySpeedConflictCanOnlyDowngradePrecision': true,
    'remoteSampleCanChangeCadence': false,
    'mapboxCanChangeNativeCadence': false,
    'firestoreCanChangeNativeCadence': false,
    'cloudFunctionCanChangeNativeCadence': false,
    'nativeSamplingCanConfirmOdometer': false,
    'nativeSamplingCanSetGlobalTruth': false,
    'nativeSamplingCanChangeOfficialMileage': false,
    'nativeSamplingCanCreateOfficialStop': false,
    'nativeSamplingCanDeleteLocalData': false,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'mapsRequiredForNativeSampling': false,
    'rawLocationIncluded': false,
    'preciseLocationIncluded': false,
    'preciseTimestampIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };

  static TripSamplingRecommendation? nextRecommendation({
    required TripTrackingPolicy policy,
    required TripTrackingProfile profile,
    required TripLocationSample sample,
    required TripSampleDecision? decision,
    required TripSamplingRecommendation? current,
    required bool adaptiveSamplingEnabled,
    required bool nativeTracking,
    required bool platformAvailable,
    required bool sessionAvailable,
  }) {
    if (!adaptiveSamplingEnabled ||
        !platformAvailable ||
        !sessionAvailable ||
        !nativeTracking ||
        !_safeSampleForNativeSampling(sample) ||
        decision == null) {
      return null;
    }
    final canDowngradeForStationaryConflict =
        decision.disposition == TripSampleDisposition.rejectedSpeedConflict &&
        canDeescalatePrecision(
          policy: policy,
          sample: sample,
          current: current,
        );
    if (!isSafeDecisionForNativeSampling(decision) &&
        !canDowngradeForStationaryConflict) {
      return null;
    }
    if (!decision.accepted &&
        !canDeescalatePrecision(
          policy: policy,
          sample: sample,
          current: current,
        )) {
      return null;
    }
    final next = policy.samplingFor(
      speedMetersPerSecond: sample.speedMetersPerSecond,
      vehicleMovementConfirmed:
          decision.disposition == TripSampleDisposition.acceptedDistance,
      profile: profile,
      currentMode: current?.mode,
      activeTrip: true,
    );
    return isSameRecommendation(current, next) ? null : next;
  }

  static bool canDeescalatePrecision({
    required TripTrackingPolicy policy,
    required TripLocationSample sample,
    required TripSamplingRecommendation? current,
  }) {
    final speed = sample.speedMetersPerSecond;
    final configuredExitSpeed = policy.precisionExitSpeedMetersPerSecond;
    final precisionExitSpeed =
        configuredExitSpeed.isFinite && configuredExitSpeed > 0
        ? configuredExitSpeed
        : 5.6;
    return current?.mode == TripSamplingMode.precision &&
        speed != null &&
        speed.isFinite &&
        speed >= 0 &&
        speed < precisionExitSpeed;
  }

  static bool isSafeDecisionForNativeSampling(TripSampleDecision decision) {
    return switch (decision.disposition) {
      TripSampleDisposition.acceptedAnchor ||
      TripSampleDisposition.acceptedDistance ||
      TripSampleDisposition.rejectedDrift ||
      TripSampleDisposition.excludedWalking => true,
      TripSampleDisposition.rejectedInvalid ||
      TripSampleDisposition.rejectedMockLocation ||
      TripSampleDisposition.rejectedAccuracy ||
      TripSampleDisposition.rejectedOutOfOrder ||
      TripSampleDisposition.rejectedImplausibleSpeed ||
      TripSampleDisposition.rejectedSpeedConflict ||
      TripSampleDisposition.rejectedGap ||
      TripSampleDisposition.rejectedFutureTimestamp => false,
    };
  }

  static bool isSafeSampleForNativeSampling(TripLocationSample sample) =>
      _safeSampleForNativeSampling(sample);

  static bool isSameRecommendation(
    TripSamplingRecommendation? current,
    TripSamplingRecommendation next,
  ) =>
      current != null &&
      current.mode == next.mode &&
      current.interval == next.interval &&
      current.minimumDisplacementMeters == next.minimumDisplacementMeters;
}

class TripTrackingNativeSamplingSummaryValidation {
  const TripTrackingNativeSamplingSummaryValidation._({
    required this.isRenderable,
    required this.canUpdateNativeCadence,
    required this.reasons,
  });

  factory TripTrackingNativeSamplingSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    final hasRecommendation = summary['hasRecommendation'];
    if (hasRecommendation is! bool) reasons.add('has_recommendation_not_bool');
    final mode = summary['mode'];
    if (mode != null && !_safeMode(mode)) reasons.add('invalid_sampling_mode');
    final interval = summary['intervalSeconds'];
    if (interval != null &&
        (interval is! int || interval < 1 || interval > 3600)) {
      reasons.add('invalid_sampling_interval');
    }
    final displacement = summary['minimumDisplacementMeters'];
    if (displacement != null &&
        (displacement is! num ||
            !displacement.isFinite ||
            displacement < 0 ||
            displacement > 1000)) {
      reasons.add('invalid_sampling_displacement');
    }
    for (final key in const [
      'adaptiveSamplingEnabled',
      'nativeTracking',
      'platformAvailable',
      'sessionAvailable',
      'canUpdateNativeCadence',
      'validatedSampleRequired',
      'safeDecisionRequired',
      'localSessionRequired',
      'nativePlatformRequired',
      'mockedLocationCanChangeCadence',
      'futureSampleCanChangeCadence',
      'rejectedInvalidCanChangeCadence',
      'stationarySpeedConflictCanOnlyDowngradePrecision',
      'remoteSampleCanChangeCadence',
      'mapboxCanChangeNativeCadence',
      'firestoreCanChangeNativeCadence',
      'cloudFunctionCanChangeNativeCadence',
      'nativeSamplingCanConfirmOdometer',
      'nativeSamplingCanSetGlobalTruth',
      'nativeSamplingCanChangeOfficialMileage',
      'nativeSamplingCanCreateOfficialStop',
      'nativeSamplingCanDeleteLocalData',
      'odometerRemainsOfficialMileageTruth',
      'odometerIsGlobalTruth',
      'hiveRemainsOperationalSourceOfTruth',
      'mapsRequiredForNativeSampling',
      'rawLocationIncluded',
      'preciseLocationIncluded',
      'preciseTimestampIncluded',
      'routeGeometryIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['canUpdateNativeCadence'] == true &&
        (hasRecommendation != true ||
            summary['adaptiveSamplingEnabled'] != true ||
            summary['nativeTracking'] != true ||
            summary['platformAvailable'] != true ||
            summary['sessionAvailable'] != true)) {
      reasons.add('unsafe_native_cadence_update_claim');
    }
    if (hasRecommendation == false &&
        (summary['mode'] != null ||
            summary['intervalSeconds'] != null ||
            summary['minimumDisplacementMeters'] != null)) {
      reasons.add('native_sampling_recommendation_shape_mismatch');
    }
    if (hasRecommendation == true &&
        (summary['mode'] == null ||
            summary['intervalSeconds'] == null ||
            summary['minimumDisplacementMeters'] == null)) {
      reasons.add('native_sampling_recommendation_shape_mismatch');
    }
    if (summary['validatedSampleRequired'] != true ||
        summary['safeDecisionRequired'] != true ||
        summary['localSessionRequired'] != true ||
        summary['nativePlatformRequired'] != true) {
      reasons.add('native_sampling_boundary_missing');
    }
    if (summary['mockedLocationCanChangeCadence'] != false ||
        summary['futureSampleCanChangeCadence'] != false ||
        summary['rejectedInvalidCanChangeCadence'] != false ||
        summary['stationarySpeedConflictCanOnlyDowngradePrecision'] != true ||
        summary['remoteSampleCanChangeCadence'] != false ||
        summary['mapboxCanChangeNativeCadence'] != false ||
        summary['firestoreCanChangeNativeCadence'] != false ||
        summary['cloudFunctionCanChangeNativeCadence'] != false) {
      reasons.add('external_or_unsafe_sample_can_change_cadence');
    }
    if (summary['nativeSamplingCanConfirmOdometer'] != false ||
        summary['nativeSamplingCanSetGlobalTruth'] != false ||
        summary['nativeSamplingCanChangeOfficialMileage'] != false ||
        summary['nativeSamplingCanCreateOfficialStop'] != false ||
        summary['nativeSamplingCanDeleteLocalData'] != false ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['hiveRemainsOperationalSourceOfTruth'] != true) {
      reasons.add('native_sampling_claims_trip_truth');
    }
    if (summary['mapsRequiredForNativeSampling'] != false ||
        summary['rawLocationIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['preciseTimestampIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_sampling_material');
    }
    return TripTrackingNativeSamplingSummaryValidation._(
      isRenderable: reasons.isEmpty,
      canUpdateNativeCadence:
          reasons.isEmpty && summary['canUpdateNativeCadence'] == true,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final bool canUpdateNativeCadence;
  final List<String> reasons;
}

bool _safeSampleForNativeSampling(TripLocationSample sample) {
  if (!sample.hasValidCoordinate || !sample.hasValidAccuracy) return false;
  if (sample.mockedLocation == true) return false;
  if (sample.horizontalAccuracyMeters > 250) return false;
  final speed = sample.speedMetersPerSecond;
  if (speed != null && (!speed.isFinite || speed < 0 || speed > 70)) {
    return false;
  }
  final year = sample.recordedAt.toUtc().year;
  return year >= 2020 && year <= 2100;
}

bool _safeMode(Object? value) {
  if (value is! String) return false;
  for (final mode in TripSamplingMode.values) {
    if (mode.name == value) return true;
  }
  return false;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains('token=') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}'));
}
