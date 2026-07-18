enum TripTrackingOdometerTruthSource { physicalOdometer, userConfirmedReview }

enum TripTrackingMileageAssistSource {
  gps,
  mapbox,
  firebaseMirror,
  cloudFunction,
  importedFile,
  localCache,
  sensorFusion,
}

class TripTrackingOdometerTruthPolicy {
  const TripTrackingOdometerTruthPolicy._();

  static const int schemaVersion = 1;

  static const Map<String, Object?> safeSummaryClaims = {
    'odometerTruthPolicySchemaVersion': schemaVersion,
    'odometerIsGlobalTruth': true,
    'odometerRemainsCanonical': true,
    'physicalOdometerIsCanonical': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'userConfirmedOdometerReviewCanSetTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'gpsEstimateRemainsNonCanonical': true,
    'mapboxAssistAdvisoryOnly': true,
    'firebaseMirrorCanOverrideOdometer': false,
    'cloudFunctionCanOverrideOdometer': false,
    'mapboxCanOverrideOdometer': false,
    'gpsCanOverrideOdometer': false,
    'importedFileCanOverrideOdometer': false,
    'localCacheCanOverrideOdometer': false,
    'sensorFusionCanOverrideOdometer': false,
    'calibrationCanRewriteConfirmedOdometer': false,
    'calibrationCanChangeDisplayedConfirmedMiles': false,
    'calibrationCanMutateTripLog': false,
    'calibrationCanLowerConfirmedOdometer': false,
    'calibrationCanApplySilently': false,
    'calibrationAppliesToFutureGpsProjectionOnly': true,
    'calibrationRequiresUserOptIn': true,
    'calibrationRequiresAcceptedReview': true,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'singleDayCalibrationRejected': true,
  };

  static bool canSourceSetOfficialMileage(
    TripTrackingOdometerTruthSource source,
  ) {
    return switch (source) {
      TripTrackingOdometerTruthSource.physicalOdometer => true,
      TripTrackingOdometerTruthSource.userConfirmedReview => true,
    };
  }

  static bool canAssistSourceSetOfficialMileage(
    TripTrackingMileageAssistSource source,
  ) {
    return false;
  }

  static bool canAssistSourceApplyCalibration(
    TripTrackingMileageAssistSource source,
  ) {
    return false;
  }

  static TripTrackingOdometerTruthValidation validateSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    for (final entry in safeSummaryClaims.entries) {
      if (summary[entry.key] != entry.value) {
        reasons.add('missing_or_invalid_${entry.key}');
      }
    }
    if (summary['officialMileageSource'] is String &&
        !_isAllowedOfficialMileageSource(summary['officialMileageSource'])) {
      reasons.add('invalid_official_mileage_source');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('odometer_truth_summary_contains_sensitive_text');
    }
    return TripTrackingOdometerTruthValidation._(
      isValid: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  static bool _isAllowedOfficialMileageSource(Object? value) {
    return switch (value) {
      'physicalOdometer' => true,
      'userConfirmedReview' => true,
      _ => false,
    };
  }

  static bool _looksSensitive(Object? value) {
    if (value is! String) return false;
    final clean = value.trim();
    return clean.startsWith('pk.') ||
        clean.startsWith('sk.') ||
        clean.contains(RegExp(r'-?\\d{1,3}\\.\\d{5,}'));
  }
}

class TripTrackingOdometerTruthValidation {
  const TripTrackingOdometerTruthValidation._({
    required this.isValid,
    required this.reasons,
  });

  final bool isValid;
  final List<String> reasons;
}
