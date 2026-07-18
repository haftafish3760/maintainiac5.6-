import 'trip_tracking_backup_scope_policy.dart';
import 'trip_tracking_sensor_consent_boundary.dart';
import 'trip_tracking_session_store.dart';

enum TripLocationVisibilityMode {
  privateOnly,
  personalBackupOnly,
  organizationSummary,
  liveOrganizationLocation,
}

enum TripLocationVisibilityStatus {
  allowed,
  blockedNoGpsConsent,
  blockedNoOrganizationScope,
  blockedNoEmployeeConsent,
  blockedNoEmployerConsent,
  blockedUnsafeActor,
  blockedLiveSharingDisabled,
}

class TripLocationVisibilityConsentDecision {
  const TripLocationVisibilityConsentDecision({
    required this.status,
    required this.mode,
    required this.reasonCode,
    required this.canShowLiveLocationToOrganization,
    required this.canMirrorReviewedMileageToOrganization,
    required this.canShowRouteHistoryToOrganization,
  });

  final TripLocationVisibilityStatus status;
  final TripLocationVisibilityMode mode;
  final String reasonCode;
  final bool canShowLiveLocationToOrganization;
  final bool canMirrorReviewedMileageToOrganization;
  final bool canShowRouteHistoryToOrganization;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'mode': mode.name,
    'reasonCode': _safeReason(reasonCode),
    'canShowLiveLocationToOrganization': canShowLiveLocationToOrganization,
    'canMirrorReviewedMileageToOrganization':
        canMirrorReviewedMileageToOrganization,
    'canShowRouteHistoryToOrganization': canShowRouteHistoryToOrganization,
    'employeeTrackingRequiresMutualConsent': true,
    'employerGodModeAllowed': false,
    'accountOwnerAloneCanEnableEmployeeTracking': false,
    'authenticationDoesNotImplyAuthorization': true,
    'authorizationCheckedAfterAuthentication': true,
    'gpsConsentRequiredBeforeLocationVisibility': true,
    'backgroundTrackingRequiresSeparateOptIn': true,
    'routeHistoryRequiresSeparateOptIn': true,
    'mapsRequiredForGpsTripTracking': false,
    'mapboxCanEnableLocationSharing': false,
    'firestoreCanEnableLocationSharing': false,
    'cloudFunctionCanEnableLocationSharing': false,
    'remotePolicyCanOverrideLocalConsent': false,
    'liveSharingCanConfirmStops': false,
    'liveSharingCanConfirmOdometer': false,
    'liveSharingCanDeleteLocalData': false,
    'odometerRemainsOfficialMileageTruth': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'accountIdIncluded': false,
    'organizationIdIncluded': false,
    'tokensIncluded': false,
  };
}

class TripLocationVisibilityConsentPolicy {
  const TripLocationVisibilityConsentPolicy._();

  static TripLocationVisibilityConsentDecision evaluate({
    required TripTrackingSensorConsentBoundary sensorConsent,
    required TripTrackingBackupScopeDecision backupScope,
    required TripTrackingCloudBackupScope requestedScope,
    required bool employeeConsentedToLocationSharing,
    required bool employerConsentedToLocationSharingTerms,
    required bool liveLocationSharingEnabled,
    required bool routeHistorySharingEnabled,
    required String authenticatedUid,
    required String? recordOwnerUid,
    required String? organizationId,
  }) {
    if (!_safeActor(authenticatedUid) ||
        !_safeOptionalActor(recordOwnerUid) ||
        !_safeOptionalActor(organizationId)) {
      return _blocked(
        TripLocationVisibilityStatus.blockedUnsafeActor,
        'unsafe_location_visibility_actor',
      );
    }
    if (!sensorConsent.gpsAllowed) {
      return _blocked(
        TripLocationVisibilityStatus.blockedNoGpsConsent,
        'gps_consent_required_for_visibility',
      );
    }

    if (requestedScope == TripTrackingCloudBackupScope.personal) {
      return const TripLocationVisibilityConsentDecision(
        status: TripLocationVisibilityStatus.allowed,
        mode: TripLocationVisibilityMode.personalBackupOnly,
        reasonCode: 'personal_visibility_only',
        canShowLiveLocationToOrganization: false,
        canMirrorReviewedMileageToOrganization: false,
        canShowRouteHistoryToOrganization: false,
      );
    }

    if (!backupScope.canQueue || organizationId == null) {
      return _blocked(
        TripLocationVisibilityStatus.blockedNoOrganizationScope,
        'organization_scope_required_for_visibility',
      );
    }
    if (!employeeConsentedToLocationSharing) {
      return _blocked(
        TripLocationVisibilityStatus.blockedNoEmployeeConsent,
        'employee_location_consent_required',
      );
    }
    if (!employerConsentedToLocationSharingTerms) {
      return _blocked(
        TripLocationVisibilityStatus.blockedNoEmployerConsent,
        'employer_location_terms_required',
      );
    }
    if (!liveLocationSharingEnabled) {
      return const TripLocationVisibilityConsentDecision(
        status: TripLocationVisibilityStatus.allowed,
        mode: TripLocationVisibilityMode.organizationSummary,
        reasonCode: 'organization_summary_visibility_only',
        canShowLiveLocationToOrganization: false,
        canMirrorReviewedMileageToOrganization: true,
        canShowRouteHistoryToOrganization: false,
      );
    }
    if (!sensorConsent.backgroundTrackingAllowed) {
      return _blocked(
        TripLocationVisibilityStatus.blockedLiveSharingDisabled,
        'background_permission_required_for_live_visibility',
      );
    }
    return TripLocationVisibilityConsentDecision(
      status: TripLocationVisibilityStatus.allowed,
      mode: TripLocationVisibilityMode.liveOrganizationLocation,
      reasonCode: 'live_organization_visibility_allowed',
      canShowLiveLocationToOrganization: true,
      canMirrorReviewedMileageToOrganization: true,
      canShowRouteHistoryToOrganization: routeHistorySharingEnabled,
    );
  }
}

TripLocationVisibilityConsentDecision _blocked(
  TripLocationVisibilityStatus status,
  String reasonCode,
) {
  return TripLocationVisibilityConsentDecision(
    status: status,
    mode: TripLocationVisibilityMode.privateOnly,
    reasonCode: reasonCode,
    canShowLiveLocationToOrganization: false,
    canMirrorReviewedMileageToOrganization: false,
    canShowRouteHistoryToOrganization: false,
  );
}

bool _safeActor(String value) {
  final clean = value.trim();
  return clean == value &&
      TripTrackingBackupScopePolicy.isSafeCloudToken(clean) &&
      !clean.toLowerCase().contains('token') &&
      !clean.toLowerCase().contains('secret');
}

bool _safeOptionalActor(String? value) {
  if (value == null) return true;
  return _safeActor(value);
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'unsafe_location_visibility_actor' => 'unsafe_location_visibility_actor',
    'gps_consent_required_for_visibility' =>
      'gps_consent_required_for_visibility',
    'personal_visibility_only' => 'personal_visibility_only',
    'organization_scope_required_for_visibility' =>
      'organization_scope_required_for_visibility',
    'employee_location_consent_required' =>
      'employee_location_consent_required',
    'employer_location_terms_required' => 'employer_location_terms_required',
    'organization_summary_visibility_only' =>
      'organization_summary_visibility_only',
    'background_permission_required_for_live_visibility' =>
      'background_permission_required_for_live_visibility',
    'live_organization_visibility_allowed' =>
      'live_organization_visibility_allowed',
    _ => 'unsafe_location_visibility_actor',
  };
}
