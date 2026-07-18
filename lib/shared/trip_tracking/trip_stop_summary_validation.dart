import 'trip_stop_classification.dart';

/// Validates stop-review summary payloads before dashboard/UI rendering.
///
/// Stop summaries can be mirrored through Firestore, local storage, import
/// files, or background handoff code, so the dashboard must not trust the map
/// shape just because it came from a known source. This validator keeps stop
/// detection advisory-only and prevents remote data from creating official
/// stops, ending trips, replacing odometer truth, or leaking route material.
class TripStopSummaryValidation {
  const TripStopSummaryValidation._({
    required this.isRenderable,
    required this.signal,
    required this.reasonCode,
    required this.reasons,
  });

  factory TripStopSummaryValidation.fromSummary(Map<String, Object?> summary) {
    final reasons = <String>[];
    final schemaVersion = summary['schemaVersion'];
    final signal = _safeSignal(summary['signal']);
    final reasonCode = _safeReasonCode(summary['reasonCode']);
    final reviewConfidence = _safeReviewConfidence(summary['reviewConfidence']);

    if (schemaVersion != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (signal == null) {
      reasons.add('invalid_stop_signal');
    }
    if (reasonCode == null) {
      reasons.add('invalid_reason_code');
    }
    if (reviewConfidence == null) {
      reasons.add('invalid_review_confidence');
    }
    if (summary['reviewOnly'] != true || summary['advisoryOnly'] != true) {
      reasons.add('stop_summary_not_review_only');
    }
    if (summary['gpsAssistedOnly'] != true) {
      reasons.add('stop_summary_not_gps_assisted');
    }
    if (summary['walkingEvidenceCanOnlySuggestReview'] != true) {
      reasons.add('walking_evidence_can_create_stop');
    }
    if (summary['vehicleOnlyStopFallbackAvailable'] != true ||
        summary['manualStopFallbackAvailable'] != true) {
      reasons.add('manual_stop_fallback_policy_missing');
    }
    if (summary['shouldSurfaceManualStopFallback'] == true &&
        signal != TripStopSignal.reviewOnlyStop &&
        signal != TripStopSignal.stopCandidate &&
        signal != TripStopSignal.likelyTrafficControl) {
      reasons.add('manual_stop_fallback_on_unsafe_signal');
    }
    if (summary['activityRecognitionCanCreateOfficialStop'] != false) {
      reasons.add('activity_recognition_can_create_stop');
    }
    if (summary['unsafeEvidenceCanCreateStop'] != false) {
      reasons.add('unsafe_evidence_can_create_stop');
    }
    if (summary['remoteStopSummaryCanOverrideLocalTrip'] != false) {
      reasons.add('remote_summary_can_override_local_trip');
    }
    if (summary['remoteDashboardCanOpenStopReview'] != false ||
        summary['importedStopSummaryCanOpenStopReview'] != false) {
      reasons.add('remote_summary_can_open_stop_review');
    }
    if (summary['localTripLogRequiredForReview'] != true) {
      reasons.add('local_trip_log_not_required_for_review');
    }
    if (summary['authenticatedUserStillNeedsAuthorization'] != true) {
      reasons.add('authentication_treated_as_authorization');
    }
    if (summary['fleetObserverCanCreateStop'] != false) {
      reasons.add('fleet_observer_can_create_stop');
    }
    if (summary['firestoreCanCreateOfficialStop'] != false) {
      reasons.add('firestore_can_create_stop');
    }
    if (summary['cloudFunctionCanCreateOfficialStop'] != false) {
      reasons.add('cloud_function_can_create_stop');
    }
    if (summary['canCreateOfficialStop'] != false ||
        summary['canEndTripAutomatically'] != false ||
        summary['canReplaceOdometer'] != false) {
      reasons.add('summary_can_mutate_trip_truth');
    }
    if (summary['officialStopSource'] != 'user_review') {
      reasons.add('official_stop_source_not_user_review');
    }
    if (summary['officialMileageSource'] != 'odometer') {
      reasons.add('official_mileage_source_not_odometer');
    }
    if (summary['mapsRequiredForStopReview'] != false ||
        summary['mapboxCanCreateStop'] != false ||
        summary['mapboxCanEndTrip'] != false ||
        summary['mapboxDirectionsCanCreateStop'] != false ||
        summary['mapboxMatrixCanCreateStop'] != false ||
        summary['mapboxMapMatchingCanReplaceMileage'] != false ||
        summary['mapboxOptimizationCanReorderOfficialStops'] != false) {
      reasons.add('mapbox_can_control_stop_review');
    }
    if (summary['rawSamplesIncluded'] != false ||
        summary['rawMotionPayloadIncluded'] != false ||
        summary['coordinatesIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['mapboxGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('summary_contains_sensitive_route_material');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripStopSummaryValidation._(
      isRenderable: reasons.isEmpty,
      signal: reasons.isEmpty ? signal : null,
      reasonCode: reasons.isEmpty ? reasonCode : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripStopSignal? signal;
  final String? reasonCode;
  final List<String> reasons;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}

TripStopSignal? _safeSignal(Object? value) {
  if (value is! String) return null;
  for (final signal in TripStopSignal.values) {
    if (signal.name == value) return signal;
  }
  return null;
}

String? _safeReasonCode(Object? value) {
  if (value is! String) return null;
  return switch (value) {
    'unsafe_stop_evidence_rejected' => value,
    'equipment_walking_evidence_ignored' => value,
    'walking_stop_without_vehicle_movement' => value,
    'delivery_stop_walk_review' => value,
    'contractor_stop_walk_review' => value,
    'rideshare_stop_requires_extra_evidence' => value,
    'road_vehicle_stop_walk_review' => value,
    'stop_candidate_waiting_for_stronger_evidence' => value,
    'stop_candidate_waiting_for_confirmation' => value,
    'traffic_control_or_stationary_jitter' => value,
    'no_stop_review_needed' => value,
    _ => null,
  };
}

TripStopReviewConfidence? _safeReviewConfidence(Object? value) {
  if (value is! String) return null;
  for (final confidence in TripStopReviewConfidence.values) {
    if (confidence.name == value) return confidence;
  }
  return null;
}
