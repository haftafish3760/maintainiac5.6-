import 'trip_stop_debounce_policy.dart';
import 'trip_stop_summary_validation.dart';

/// Trust-boundary validation for rendered stop-debounce dashboard summaries.
///
/// A debounce summary may come from a local dashboard cache, a synced Firestore
/// mirror, an imported diagnostics file, or a background handoff. This validator
/// keeps that data render-only: it may explain what the GPS-assisted tracker is
/// thinking, but it cannot open review, create stops, end trips, replace
/// odometer truth, or smuggle raw route/location material into logs.
class TripStopDebounceSummaryValidation {
  const TripStopDebounceSummaryValidation._({
    required this.isRenderable,
    required this.status,
    required this.reasonCode,
    required this.reasons,
  });

  factory TripStopDebounceSummaryValidation.fromDashboardMap(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeDebounceStatus(summary['status']);
    final reasonCode = _safeDebounceReason(summary['reasonCode']);
    final classification = summary['classification'];
    final evidenceDigest = summary['evidenceDigest'];

    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (status == null) reasons.add('invalid_debounce_status');
    if (reasonCode == null) reasons.add('invalid_debounce_reason');
    if (classification is! Map<String, Object?>) {
      reasons.add('invalid_classification_summary');
    } else {
      final classificationValidation = TripStopSummaryValidation.fromSummary(
        classification,
      );
      if (!classificationValidation.isRenderable) {
        reasons.add('invalid_classification_boundary');
      }
    }
    if (evidenceDigest is! Map<String, Object?>) {
      reasons.add('invalid_evidence_digest');
    } else {
      reasons.addAll(_validateEvidenceDigest(evidenceDigest));
    }
    if (summary['gpsAssistedOnly'] != true) {
      reasons.add('debounce_not_gps_assisted');
    }
    if (summary['mapsRequiredForStopDebounce'] != false ||
        summary['mapboxCanCreateStop'] != false ||
        summary['mapboxCanConfirmStop'] != false ||
        summary['mapboxDirectionsCanConfirmStop'] != false ||
        summary['mapboxMatrixCanConfirmStop'] != false ||
        summary['mapboxMapMatchingCanReplaceMileage'] != false ||
        summary['mapboxOptimizationCanCreateStopOrder'] != false ||
        summary['mapboxTrafficSignalCanCreateStop'] != false ||
        summary['mapboxGeocodeCanConfirmStopAddress'] != false) {
      reasons.add('mapbox_can_control_stop_debounce');
    }
    if (summary['firestoreCanCreateStop'] != false ||
        summary['cloudFunctionCanCreateStop'] != false ||
        summary['remoteDebounceCanOverrideLocalTrip'] != false ||
        summary['remoteDebounceCanOpenReview'] != false ||
        summary['remoteDebounceCanEndTrip'] != false ||
        summary['importedDebounceCanOpenReview'] != false ||
        summary['dashboardCacheCanOpenReview'] != false) {
      reasons.add('remote_debounce_can_control_trip');
    }
    if (summary['authenticatedUserStillNeedsAuthorization'] != true) {
      reasons.add('authentication_treated_as_authorization');
    }
    if (summary['localTripLogRequiredForReview'] != true) {
      reasons.add('local_trip_log_not_required_for_review');
    }
    if (summary['malformedStopDebounceObservationFailsClosed'] != true) {
      reasons.add('malformed_debounce_not_fail_closed');
    }
    if (summary['stopReviewCannotCommitWithoutUserAction'] != true ||
        summary['stopReviewRequiredForOfficialStop'] != true) {
      reasons.add('stop_review_not_user_action_gated');
    }
    if (summary['activityRecognitionCanCreateOfficialStop'] != false ||
        summary['vehicleOnlyDwellCanCreateOfficialStop'] != false) {
      reasons.add('advisory_evidence_can_create_stop');
    }
    if (summary['stopEvidenceCanCreateCalibration'] != false ||
        summary['walkingEvidenceCanCreateCalibration'] != false ||
        summary['trafficControlCanCreateCalibration'] != false ||
        summary['stopEvidenceCanSetGlobalTruth'] != false ||
        summary['stopEvidenceCanConfirmOfficialMileage'] != false ||
        summary['stopEvidenceCanChangeOfficialMileage'] != false ||
        summary['walkingEvidenceCanConfirmOfficialMileage'] != false ||
        summary['trafficControlCanConfirmOfficialMileage'] != false ||
        summary['calibrationRequiresTrustedGpsWindow'] != true ||
        summary['poorGpsDaysExcludedFromCalibration'] != true) {
      reasons.add('stop_evidence_can_create_calibration');
    }
    if (summary['walkingEvidenceCanOnlySuggestReview'] != true ||
        summary['walkingEvidenceRequiresUserSensorOptIn'] != true ||
        summary['walkingEvidenceRequiresCurrentDeviceSensor'] != true ||
        summary['walkingEvidenceCannotBeReplayedFromCloud'] != true ||
        summary['walkingEvidenceCannotBeImportedFromFile'] != true ||
        summary['walkingEvidenceCannotCommitStop'] != true) {
      reasons.add('walking_evidence_not_advisory_only');
    }
    if (summary['vehicleOnlyDwellCanOnlySuggestManualFallback'] != true ||
        summary['vehicleOnlyDwellCannotInferAddress'] != true ||
        summary['manualFallbackCannotInferAddress'] != true ||
        summary['manualFallbackCannotConfirmMileage'] != true ||
        summary['longStoplightCannotCreateOfficialStop'] != true ||
        summary['longStoplightCannotInferAddress'] != true ||
        summary['gridlockCannotCreateOfficialStop'] != true ||
        summary['gridlockCannotInferAddress'] != true ||
        summary['twoPersonDeliveryRequiresManualConfirmation'] != true ||
        summary['driverProfileThresholdsAreLocalPolicy'] != true) {
      reasons.add('vehicle_only_dwell_not_manual_only');
    }
    if (summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true) {
      reasons.add('odometer_not_official_truth');
    }
    if (summary['rawSamplesIncluded'] != false ||
        summary['coordinatesIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('debounce_contains_sensitive_route_material');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('debounce_contains_sensitive_text');
    }

    return TripStopDebounceSummaryValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status : null,
      reasonCode: reasons.isEmpty ? reasonCode : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripStopDebounceStatus? status;
  final String? reasonCode;
  final List<String> reasons;
}

List<String> _validateEvidenceDigest(Map<String, Object?> digest) {
  final reasons = <String>[];
  final acceptedDistanceCount = digest['acceptedDistanceCount'];
  final rejectedDriftCount = digest['rejectedDriftCount'];
  final rejectedUnsafeCount = digest['rejectedUnsafeCount'];
  final walkingEvidenceCount = digest['walkingEvidenceCount'];

  for (final entry in {
    'acceptedDistanceCount': acceptedDistanceCount,
    'rejectedDriftCount': rejectedDriftCount,
    'rejectedUnsafeCount': rejectedUnsafeCount,
    'walkingEvidenceCount': walkingEvidenceCount,
  }.entries) {
    final value = entry.value;
    if (value is! int || value < 0 || value > 100000) {
      reasons.add('invalid_${entry.key}');
    }
  }
  if (digest['providerValuesUsable'] is! bool ||
      digest['walkingBurstProtected'] is! bool ||
      digest['walkingEvidenceCurrent'] is! bool) {
    reasons.add('invalid_evidence_boolean');
  }
  if (digest['rawSamplesIncluded'] != false ||
      digest['coordinatesIncluded'] != false ||
      digest['routeGeometryIncluded'] != false ||
      digest['tokensIncluded'] != false) {
    reasons.add('evidence_digest_contains_sensitive_route_material');
  }
  if (digest.values.any(_looksSensitive)) {
    reasons.add('evidence_digest_contains_sensitive_text');
  }
  return reasons;
}

TripStopDebounceStatus? _safeDebounceStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripStopDebounceStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

String? _safeDebounceReason(Object? value) {
  if (value is! String) return null;
  return switch (value) {
    'unsafe_stop_debounce_evidence' => value,
    'vehicle_movement_required_before_stop_review' => value,
    'traffic_control_debounce_protected' => value,
    'vehicle_only_dwell_traffic_control_protected' => value,
    'vehicle_only_dwell_manual_fallback' => value,
    'vehicle_speed_blocks_stop_review' => value,
    'walking_burst_debounce_protected' => value,
    'future_walking_evidence_rejected' => value,
    'stale_walking_evidence_rejected' => value,
    'undated_walking_evidence_rejected' => value,
    'walking_stop_debounce_ready' => value,
    'stop_debounce_waiting_for_confirmation' => value,
    'stop_debounce_keep_tracking' => value,
    _ => null,
  };
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
