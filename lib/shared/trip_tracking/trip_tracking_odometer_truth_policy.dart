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

class TripTrackingOfficialMileageDecision {
  const TripTrackingOfficialMileageDecision._({
    required this.accepted,
    required this.officialMileageMiles,
    required this.reasonCode,
    required this.source,
    required this.externalMileageWasAdvisoryOnly,
    required this.reviewRequired,
  });

  final bool accepted;
  final double? officialMileageMiles;
  final String reasonCode;
  final String source;
  final bool externalMileageWasAdvisoryOnly;
  final bool reviewRequired;

  Map<String, Object?> toSafeSummary() => {
    ...TripTrackingOdometerTruthPolicy.safeSummaryClaims,
    'accepted': accepted,
    'officialMileageMiles': _safeRoundedMileage(officialMileageMiles),
    'reasonCode': _safeOdometerTruthReason(reasonCode),
    'officialMileageSource': source,
    'externalMileageWasAdvisoryOnly': externalMileageWasAdvisoryOnly,
    'reviewRequired': reviewRequired,
    'locationHistoryIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripTrackingOdometerTruthPolicy {
  const TripTrackingOdometerTruthPolicy._();

  static const int schemaVersion = 1;

  static const Map<String, Object?> safeSummaryClaims = {
    'odometerTruthPolicySchemaVersion': schemaVersion,
    'odometerIsGlobalTruth': true,
    'odometerRemainsCanonical': true,
    'physicalOdometerIsCanonical': true,
    'globalTruthSource': 'physical_odometer_or_user_confirmed_review',
    'onlyPhysicalOdometerOrUserReviewCanSetGlobalTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'userConfirmedOdometerReviewCanSetTruth': true,
    'assistSourceCanSetGlobalTruth': false,
    'remoteSourceCanSetGlobalTruth': false,
    'mapboxCanSetGlobalTruth': false,
    'gpsCanSetGlobalTruth': false,
    'firebaseMirrorCanSetGlobalTruth': false,
    'cloudFunctionCanSetGlobalTruth': false,
    'importedFileCanSetGlobalTruth': false,
    'localCacheCanSetGlobalTruth': false,
    'sensorFusionCanSetGlobalTruth': false,
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

  static bool canAssistSourceSetGlobalTruth(
    TripTrackingMileageAssistSource source,
  ) {
    return false;
  }

  static bool canAssistSourceApplyCalibration(
    TripTrackingMileageAssistSource source,
  ) {
    return false;
  }

  static TripTrackingOfficialMileageDecision decideOfficialMileage({
    required TripTrackingOdometerTruthSource? truthSource,
    required double? confirmedOdometerMiles,
    required TripTrackingMileageAssistSource? assistSource,
    required double? externalEstimatedMiles,
  }) {
    final hasConfirmedOdometer =
        confirmedOdometerMiles != null &&
        confirmedOdometerMiles.isFinite &&
        confirmedOdometerMiles >= 0 &&
        confirmedOdometerMiles <= 2000;
    final hasExternalEstimate =
        externalEstimatedMiles != null &&
        externalEstimatedMiles.isFinite &&
        externalEstimatedMiles >= 0 &&
        externalEstimatedMiles <= 2000;
    final safeSource = truthSource == null
        ? 'unconfirmed'
        : _safeOfficialMileageSourceName(truthSource);

    if (!hasConfirmedOdometer) {
      return TripTrackingOfficialMileageDecision._(
        accepted: false,
        officialMileageMiles: null,
        reasonCode: hasExternalEstimate
            ? 'external_mileage_requires_odometer_review'
            : 'missing_confirmed_odometer',
        source: 'unconfirmed',
        externalMileageWasAdvisoryOnly: hasExternalEstimate,
        reviewRequired: true,
      );
    }

    if (truthSource == null || !canSourceSetOfficialMileage(truthSource)) {
      return TripTrackingOfficialMileageDecision._(
        accepted: false,
        officialMileageMiles: confirmedOdometerMiles,
        reasonCode: 'invalid_truth_source',
        source: 'unconfirmed',
        externalMileageWasAdvisoryOnly: hasExternalEstimate,
        reviewRequired: true,
      );
    }

    return TripTrackingOfficialMileageDecision._(
      accepted: true,
      officialMileageMiles: confirmedOdometerMiles,
      reasonCode: assistSource == null || !hasExternalEstimate
          ? 'confirmed_odometer'
          : 'confirmed_odometer_external_advisory_only',
      source: safeSource,
      externalMileageWasAdvisoryOnly: hasExternalEstimate,
      reviewRequired: false,
    );
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
    if (summary['globalTruthSource'] is String &&
        summary['globalTruthSource'] !=
            'physical_odometer_or_user_confirmed_review') {
      reasons.add('invalid_global_truth_source');
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

String _safeOfficialMileageSourceName(TripTrackingOdometerTruthSource source) {
  return switch (source) {
    TripTrackingOdometerTruthSource.physicalOdometer => 'physicalOdometer',
    TripTrackingOdometerTruthSource.userConfirmedReview =>
      'userConfirmedReview',
  };
}

String _safeOdometerTruthReason(String value) {
  return switch (value.trim()) {
    'confirmed_odometer' => 'confirmed_odometer',
    'confirmed_odometer_external_advisory_only' =>
      'confirmed_odometer_external_advisory_only',
    'external_mileage_requires_odometer_review' =>
      'external_mileage_requires_odometer_review',
    'missing_confirmed_odometer' => 'missing_confirmed_odometer',
    'invalid_truth_source' => 'invalid_truth_source',
    _ => 'missing_confirmed_odometer',
  };
}

double? _safeRoundedMileage(double? value) {
  if (value == null || !value.isFinite || value < 0 || value > 2000) {
    return null;
  }
  return double.parse(value.toStringAsFixed(2));
}

class TripTrackingOdometerTruthValidation {
  const TripTrackingOdometerTruthValidation._({
    required this.isValid,
    required this.reasons,
  });

  final bool isValid;
  final List<String> reasons;
}
