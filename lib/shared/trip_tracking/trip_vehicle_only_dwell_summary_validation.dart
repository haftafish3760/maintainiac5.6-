part of 'trip_vehicle_only_dwell_policy.dart';

class TripVehicleOnlyDwellSummaryValidation {
  const TripVehicleOnlyDwellSummaryValidation._();

  static const _allowedStatuses = {
    'unavailable',
    'keepTracking',
    'trafficControlProtected',
    'manualFallbackRecommended',
    'unsafeEvidence',
  };

  static const _allowedReasons = {
    'unsafe_vehicle_only_dwell_evidence',
    'vehicle_only_dwell_not_needed_for_profile',
    'vehicle_only_dwell_waiting_for_clean_evidence',
    'vehicle_only_dwell_needs_more_drive_evidence',
    'vehicle_only_dwell_waiting_for_trusted_gps',
    'vehicle_only_dwell_traffic_control_protected',
    'vehicle_only_dwell_manual_fallback',
    'vehicle_only_dwell_keep_tracking',
  };

  static bool isValid(Map<String, Object?> summary) {
    if (summary['schemaVersion'] != 1) return false;
    if (!_allowedStatuses.contains(summary['status'])) return false;
    if (!_allowedReasons.contains(summary['reasonCode'])) return false;
    if (!_boundedSeconds(summary['minimumDwellSeconds'])) return false;
    if (!_boundedSeconds(summary['observedDwellSeconds'])) return false;
    if (!_safeCount(summary['acceptedDistanceCount'])) return false;
    if (!_safeCount(summary['rejectedDriftCount'])) return false;
    if (!_safeCount(summary['minimumAcceptedDistanceCount'])) return false;
    if (summary['hasEnoughCleanDriveEvidence'] is! bool) return false;
    if (summary['canSurfaceManualFallback'] is! bool) return false;
    if (summary['shouldContinueSampling'] is! bool) return false;
    if (!_validSafetyClaims(summary)) return false;
    if (!_validAuthorityClaims(summary)) return false;
    if (!_validTrafficClaims(summary)) return false;
    if (!_validPayloadClaims(summary)) return false;
    if (!_validStatusAuthority(summary)) return false;
    return !_containsSensitiveText(summary);
  }

  static bool _validSafetyClaims(Map<String, Object?> summary) {
    if (!_trueFlag(summary, 'vehicleOnlyStopRequiresUserReview')) return false;
    if (!_trueFlag(summary, 'manualFallbackRequiresActiveLocalTrip')) {
      return false;
    }
    if (!_trueFlag(summary, 'manualFallbackRequiresUserAction')) return false;
    if (!_falseFlag(summary, 'manualFallbackCanEditOdometer')) return false;
    if (!_falseFlag(summary, 'manualFallbackCanConfirmMileage')) return false;
    if (!_falseFlag(summary, 'manualFallbackCanInferAddress')) return false;
    return _falseFlag(summary, 'manualFallbackCanBackdateWithoutReview');
  }

  static bool _validAuthorityClaims(Map<String, Object?> summary) {
    if (!_falseFlag(summary, 'vehicleOnlyDwellCanCreateOfficialStop')) {
      return false;
    }
    if (!_falseFlag(summary, 'vehicleOnlyDwellCanEndTripAutomatically')) {
      return false;
    }
    if (!_falseFlag(summary, 'gpsCanConfirmVehicleOnlyStop')) return false;
    if (!_falseFlag(summary, 'mapboxCanConfirmVehicleOnlyStop')) return false;
    if (!_falseFlag(summary, 'mapboxCanInferVehicleOnlyStopAddress')) {
      return false;
    }
    if (!_falseFlag(summary, 'activityRecognitionCanConfirmVehicleOnlyStop')) {
      return false;
    }
    if (!_falseFlag(summary, 'walkingEvidenceCanBeReplayedFromCloud')) {
      return false;
    }
    if (!_falseFlag(summary, 'firestoreCanCreateVehicleOnlyStop')) return false;
    if (!_falseFlag(summary, 'cloudFunctionCanCreateVehicleOnlyStop')) {
      return false;
    }
    if (!_falseFlag(summary, 'remoteDwellCanSurfaceManualFallback')) {
      return false;
    }
    if (!_falseFlag(summary, 'dashboardCacheCanSurfaceManualFallback')) {
      return false;
    }
    if (!_trueFlag(summary, 'odometerRemainsOfficialMileageTruth')) {
      return false;
    }
    if (!_trueFlag(summary, 'odometerIsGlobalTruth')) return false;
    if (!_falseFlag(summary, 'dwellEvidenceCanCreateCalibration')) return false;
    if (!_falseFlag(summary, 'dwellEvidenceCanApplyCalibration')) return false;
    if (!_trueFlag(summary, 'calibrationRequiresTrustedGpsWindow')) {
      return false;
    }
    if (!_trueFlag(summary, 'poorGpsDaysExcludedFromCalibration')) return false;
    return _falseFlag(summary, 'mapsRequiredForVehicleOnlyDwell');
  }

  static bool _validTrafficClaims(Map<String, Object?> summary) {
    if (summary['longTrafficLightProtected'] is! bool) return false;
    if (!_falseFlag(summary, 'trafficControlCanSurfaceManualFallback')) {
      return false;
    }
    if (!_falseFlag(summary, 'trafficControlCanInferStopAddress')) return false;
    if (!_falseFlag(summary, 'trafficControlCanConfirmMileage')) return false;
    if (!_falseFlag(summary, 'gridlockCanCreateOfficialStop')) return false;
    if (!_falseFlag(summary, 'gridlockCanInferStopAddress')) return false;
    if (!_falseFlag(summary, 'gridlockCanConfirmMileage')) return false;
    if (!_trueFlag(summary, 'gridlockRequiresManualConfirmation')) return false;
    if (!_trueFlag(summary, 'twoPersonDeliveryRequiresManualConfirmation')) {
      return false;
    }
    return _trueFlag(summary, 'manualFallbackCannotInferJobsiteAddress');
  }

  static bool _validPayloadClaims(Map<String, Object?> summary) {
    if (!_falseFlag(summary, 'rawSamplesIncluded')) return false;
    if (!_falseFlag(summary, 'rawMotionPayloadIncluded')) return false;
    if (!_falseFlag(summary, 'coordinatesIncluded')) return false;
    if (!_falseFlag(summary, 'routeGeometryIncluded')) return false;
    return _falseFlag(summary, 'tokensIncluded');
  }

  static bool _validStatusAuthority(Map<String, Object?> summary) {
    final status = summary['status'];
    final reason = summary['reasonCode'];
    final canSurface = summary['canSurfaceManualFallback'] == true;
    final enoughDrive = summary['hasEnoughCleanDriveEvidence'] == true;
    final observed = summary['observedDwellSeconds'];
    final minimum = summary['minimumDwellSeconds'];
    if (observed is! int || minimum is! int) return false;
    if (status == 'manualFallbackRecommended') {
      return reason == 'vehicle_only_dwell_manual_fallback' &&
          canSurface &&
          enoughDrive &&
          observed >= minimum &&
          summary['longTrafficLightProtected'] == false;
    }
    if (canSurface) return false;
    if (status == 'trafficControlProtected') {
      return reason == 'vehicle_only_dwell_traffic_control_protected' &&
          summary['longTrafficLightProtected'] == true;
    }
    if (summary['longTrafficLightProtected'] == true) return false;
    if (status == 'unsafeEvidence') {
      return reason == 'unsafe_vehicle_only_dwell_evidence';
    }
    if (status == 'unavailable') {
      return reason == 'vehicle_only_dwell_not_needed_for_profile';
    }
    return status == 'keepTracking';
  }

  static bool _boundedSeconds(Object? value) =>
      value is int &&
      value >= 0 &&
      value <= const Duration(hours: 24).inSeconds;

  static bool _safeCount(Object? value) =>
      value is int && value >= 0 && value <= 100000;

  static bool _trueFlag(Map<String, Object?> summary, String key) =>
      summary[key] == true;

  static bool _falseFlag(Map<String, Object?> summary, String key) =>
      summary[key] == false;

  static bool _containsSensitiveText(Map<String, Object?> summary) {
    for (final entry in summary.entries) {
      final value = entry.value;
      if (value is Map || value is Iterable) return true;
      final normalized = value?.toString().toLowerCase() ?? '';
      if (normalized.contains('pk.') ||
          normalized.contains('sk.') ||
          normalized.contains('token') ||
          normalized.contains('latitude') ||
          normalized.contains('longitude') ||
          normalized.contains('coordinate') ||
          normalized.contains('geometry') ||
          normalized.contains('polyline') ||
          normalized.contains('gps trace') ||
          normalized.contains('raw sample')) {
        return true;
      }
    }
    return false;
  }
}
