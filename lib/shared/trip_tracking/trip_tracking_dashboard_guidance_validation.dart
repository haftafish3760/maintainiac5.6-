import 'trip_tracking_dashboard_guidance.dart';

/// Validates dashboard guidance maps before another dashboard/widget trusts
/// them for rendering. Guidance can be mirrored through local state, Firestore,
/// imports, or background handoff code, so every consumer should treat it as an
/// external boundary and refuse payloads that can mutate trip truth.
class TripTrackingDashboardGuidanceValidation {
  const TripTrackingDashboardGuidanceValidation._({
    required this.isRenderable,
    required this.enabled,
    required this.modeToken,
    required this.reasons,
  });

  factory TripTrackingDashboardGuidanceValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final enabled = summary['enabled'];
    final modeToken = _safeModeToken(summary['modeToken']);
    final profileLabel = _safeProfileLabel(summary['profileLabel']);
    final badges = summary['dashboardBadges'];

    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (enabled is! bool) reasons.add('enabled_not_bool');
    if (modeToken == null) reasons.add('invalid_mode_token');
    if (profileLabel == null) reasons.add('invalid_profile_label');
    if (badges is! List ||
        badges.any((badge) => badge is! String || badge.length > 96)) {
      reasons.add('invalid_dashboard_badges');
    }
    if (!_safeStatusText(summary['primaryStatus'])) {
      reasons.add('invalid_primary_status');
    }
    if (!_safeStatusText(summary['safetyStatus'])) {
      reasons.add('invalid_safety_status');
    }
    if (!_safeStatusText(summary['syncStatus'])) {
      reasons.add('invalid_sync_status');
    }
    if (!_safeStatusText(summary['syncReason'])) {
      reasons.add('invalid_sync_reason');
    }
    if (!_safeStatusText(summary['mapStatus'])) {
      reasons.add('invalid_map_status');
    }
    if (!_safeStatusText(summary['stopDetectionStatus'], maxLength: 240)) {
      reasons.add('invalid_stop_detection_status');
    }
    if (!_safeStatusText(summary['odometerStatus'], maxLength: 260)) {
      reasons.add('invalid_odometer_status');
    }
    for (final key in const [
      'shouldShowActivityRecognitionRecommendation',
      'shouldShowBatterySafety',
      'shouldShowOdometerReview',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['advisoryOnly'] != true) {
      reasons.add('guidance_not_advisory_only');
    }
    if (summary['startActionShouldRemainPrimary'] != true) {
      reasons.add('start_action_not_primary');
    }
    if (summary['dashboardWidgetsUserCustomizable'] != true) {
      reasons.add('dashboard_not_user_customizable');
    }
    if (summary['dashboardCanImportModuleSummaries'] != true) {
      reasons.add('dashboard_imports_not_available');
    }
    if (summary['moduleImportsCanMutateSourceModules'] != false) {
      reasons.add('module_imports_can_mutate_sources');
    }
    if (summary['gpsAssistedTrackingAvailableWithoutMaps'] != true ||
        summary['mapsRequiredForTracking'] != false) {
      reasons.add('gps_tracking_depends_on_maps');
    }
    if (summary['odometerRemainsCanonical'] != true ||
        summary['mapboxCanReplaceOdometer'] != false ||
        summary['mapboxCanWriteConfirmedTripLog'] != false ||
        summary['remoteTotalsCanBecomeCanonical'] != false) {
      reasons.add('remote_or_map_can_mutate_mileage_truth');
    }
    if (summary['localTripLogProtected'] != true) {
      reasons.add('local_trip_log_not_protected');
    }
    if (summary['locationSharingRequiresActiveOptIn'] != true ||
        summary['employeeTrackingRequiresMutualConsent'] != true ||
        summary['employerGodModeAllowed'] != false) {
      reasons.add('privacy_or_employee_tracking_boundary_invalid');
    }
    if (summary['tokensIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['rawLocationIncluded'] != false ||
        summary['rawSensorPayloadIncluded'] != false ||
        summary['rawModuleDataIncluded'] != false) {
      reasons.add('guidance_contains_sensitive_payload');
    }

    return TripTrackingDashboardGuidanceValidation._(
      isRenderable: reasons.isEmpty,
      enabled: reasons.isEmpty ? enabled as bool : false,
      modeToken: reasons.isEmpty ? modeToken : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  factory TripTrackingDashboardGuidanceValidation.fromGuidance(
    TripTrackingDashboardGuidance guidance,
  ) => TripTrackingDashboardGuidanceValidation.fromSummary(
    guidance.toSafeDashboardMap(),
  );

  final bool isRenderable;
  final bool enabled;
  final String? modeToken;
  final List<String> reasons;
}

String? _safeModeToken(Object? value) {
  if (value is! String) return null;
  return switch (value) {
    'default' || 'gig_driver' || 'contractor' => value,
    _ => null,
  };
}

String? _safeProfileLabel(Object? value) {
  if (value is! String) return null;
  return switch (value) {
    'Road vehicle' ||
    'Rideshare' ||
    'Delivery' ||
    'Contractor' ||
    'Equipment' => value,
    _ => null,
  };
}

bool _safeStatusText(Object? value, {int maxLength = 160}) {
  if (value is! String) return false;
  final clean = value.trim();
  if (clean.isEmpty || clean.length > maxLength) return false;
  final lower = clean.toLowerCase();
  return !lower.contains('token=') &&
      !lower.contains('pk.') &&
      !lower.contains('sk.') &&
      !lower.contains('lat=') &&
      !lower.contains('lng=') &&
      !lower.contains('longitude=');
}
