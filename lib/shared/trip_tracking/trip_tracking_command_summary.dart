part of 'trip_tracking_command_policy.dart';

class TripTrackingCommandSummaryValidation {
  const TripTrackingCommandSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripTrackingCommandSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (_safeCommand(summary['command']) == null) {
      reasons.add('invalid_trip_command');
    }
    if (_safeStatus(summary['status']) == null) {
      reasons.add('invalid_command_status');
    }
    if (_safeReason(summary['reasonCode']?.toString() ?? '') !=
        summary['reasonCode']) {
      reasons.add('invalid_command_reason');
    }
    for (final key in const [
      'dashboardStartButtonVisible',
      'localTextRecordWillBeWritten',
      'gpsTrackingRequested',
      'gpsStartRequiresLocalUserConfirmation',
      'gpsStartRequiresValidatedPlatformGrant',
      'gpsStartRequiresCurrentDeviceConsent',
      'manualStartCanRunWithoutGps',
      'gpsTrackingCanRunWithoutMaps',
      'mapsRequired',
      'mapsRequiredForCommand',
      'mapboxCanStartTracking',
      'firebaseCanStartTracking',
      'cloudFunctionCanStartTracking',
      'remoteMirrorCanStartTracking',
      'employerCanStartTracking',
      'employerCanTrackWithoutMutualConsent',
      'mutualFleetTrackingConsentRequired',
      'createsOfficialStop',
      'walkingEvidenceCanOnlySuggestReview',
      'requiresStopReview',
      'requiresOdometerReview',
      'odometerRemainsOfficialMileageTruth',
      'odometerIsGlobalTruth',
      'gpsDistanceCanReplaceOdometerSilently',
      'mapRouteCanReplaceOdometerSilently',
      'calibrationRequiresTrustedGpsWindow',
      'poorGpsDaysExcludedFromCalibration',
      'commandCanApplyCalibration',
      'commandCanCreateOfficialMileage',
      'commandCanSetGlobalTruth',
      'commandCanChangeOfficialMileage',
      'localSessionRequired',
      'canUploadMirror',
      'hiveRemainsOperationalSourceOfTruth',
      'firestoreMirrorOnly',
      'remoteTotalsCanonical',
      'canDeleteLocalData',
      'canPurgeLocalDataSilently',
      'durableStorageIsSharedAcrossModules',
      'rawLocationIncluded',
      'preciseRouteIncluded',
      'rawSensorPayloadIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['mapboxCanStartTracking'] != false ||
        summary['firebaseCanStartTracking'] != false ||
        summary['cloudFunctionCanStartTracking'] != false ||
        summary['remoteMirrorCanStartTracking'] != false ||
        summary['employerCanStartTracking'] != false ||
        summary['employerCanTrackWithoutMutualConsent'] != false ||
        summary['mutualFleetTrackingConsentRequired'] != true) {
      reasons.add('remote_or_employer_can_start_tracking');
    }
    if (summary['mapsRequired'] != false ||
        summary['mapsRequiredForCommand'] != false ||
        summary['gpsTrackingCanRunWithoutMaps'] != true) {
      reasons.add('maps_required_for_trip_command');
    }
    if (summary['createsOfficialStop'] != false ||
        summary['walkingEvidenceCanOnlySuggestReview'] != true ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['gpsDistanceCanReplaceOdometerSilently'] != false ||
        summary['mapRouteCanReplaceOdometerSilently'] != false ||
        summary['calibrationRequiresTrustedGpsWindow'] != true ||
        summary['poorGpsDaysExcludedFromCalibration'] != true ||
        summary['commandCanApplyCalibration'] != false ||
        summary['commandCanCreateOfficialMileage'] != false ||
        summary['commandCanSetGlobalTruth'] != false ||
        summary['commandCanChangeOfficialMileage'] != false) {
      reasons.add('command_can_create_trip_truth');
    }
    if (summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true ||
        summary['remoteTotalsCanonical'] != false ||
        summary['canDeleteLocalData'] != false ||
        summary['canPurgeLocalDataSilently'] != false ||
        summary['durableStorageIsSharedAcrossModules'] != true) {
      reasons.add('command_storage_boundary_missing');
    }
    if (summary['rawLocationIncluded'] != false ||
        summary['preciseRouteIncluded'] != false ||
        summary['rawSensorPayloadIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_command_material');
    }

    return TripTrackingCommandSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
}
