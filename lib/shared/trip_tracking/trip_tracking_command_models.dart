part of 'trip_tracking_command_policy.dart';

enum TripTrackingDashboardCommand {
  startManualDay,
  startGpsTrip,
  addStopReview,
  addPickupReview,
  addDropoffReview,
  endTripForOdometerReview,
  reviewMileage,
}

enum TripTrackingCommandStatus { allowed, warningAllowed, blocked }

enum TripTrackingCommandSource {
  localUser,
  firebaseMirror,
  cloudFunction,
  mapbox,
  employerDashboard,
}

class TripTrackingCommandContext {
  const TripTrackingCommandContext({
    required this.command,
    required this.source,
    required this.profileDecision,
    required this.deviceConsentDecision,
    required this.storageDecision,
    required this.localSessionAvailable,
    required this.activeTripInProgress,
    required this.pendingOdometerReview,
    required this.pendingStopReview,
    required this.userConfirmedAction,
    required this.mutualFleetTrackingConsent,
  });

  final TripTrackingDashboardCommand command;
  final TripTrackingCommandSource source;
  final TripTrackingOnboardingProfileDecision profileDecision;
  final TripTrackingDeviceConsentDecision deviceConsentDecision;
  final durable_storage.TripTrackingStorageDecision storageDecision;
  final bool localSessionAvailable;
  final bool activeTripInProgress;
  final bool pendingOdometerReview;
  final bool pendingStopReview;
  final bool userConfirmedAction;
  final bool mutualFleetTrackingConsent;
}

class TripTrackingCommandDecision {
  const TripTrackingCommandDecision({
    required this.status,
    required this.reasonCode,
    required this.command,
    required this.dashboardStartButtonVisible,
    required this.localTextRecordWillBeWritten,
    required this.gpsTrackingRequested,
    required this.mapsRequired,
    required this.createsOfficialStop,
    required this.requiresStopReview,
    required this.requiresOdometerReview,
    required this.canUploadMirror,
    required this.allowedWarnings,
  });

  final TripTrackingCommandStatus status;
  final String reasonCode;
  final TripTrackingDashboardCommand command;
  final bool dashboardStartButtonVisible;
  final bool localTextRecordWillBeWritten;
  final bool gpsTrackingRequested;
  final bool mapsRequired;
  final bool createsOfficialStop;
  final bool requiresStopReview;
  final bool requiresOdometerReview;
  final bool canUploadMirror;
  final List<String> allowedWarnings;

  bool get isAllowed =>
      status == TripTrackingCommandStatus.allowed ||
      status == TripTrackingCommandStatus.warningAllowed;

  Map<String, Object?> toSafeDashboardCommandMap() => {
    'schemaVersion': 1,
    'command': command.name,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'dashboardStartButtonVisible': dashboardStartButtonVisible,
    'localTextRecordWillBeWritten': localTextRecordWillBeWritten,
    'gpsTrackingRequested': gpsTrackingRequested,
    'gpsStartRequiresLocalUserConfirmation':
        command == TripTrackingDashboardCommand.startGpsTrip,
    'gpsStartRequiresValidatedPlatformGrant':
        command == TripTrackingDashboardCommand.startGpsTrip,
    'gpsStartRequiresCurrentDeviceConsent':
        command == TripTrackingDashboardCommand.startGpsTrip,
    'manualStartCanRunWithoutGps':
        command == TripTrackingDashboardCommand.startManualDay,
    'gpsTrackingCanRunWithoutMaps': true,
    'mapsRequired': false,
    'mapsRequiredForCommand': false,
    'mapboxCanStartTracking': false,
    'firebaseCanStartTracking': false,
    'cloudFunctionCanStartTracking': false,
    'remoteMirrorCanStartTracking': false,
    'employerCanStartTracking': false,
    'employerCanTrackWithoutMutualConsent': false,
    'mutualFleetTrackingConsentRequired': true,
    'createsOfficialStop': false,
    'walkingEvidenceCanOnlySuggestReview': true,
    'requiresStopReview': requiresStopReview,
    'pendingStopReviewBlocksDuplicateReview':
        reasonCode == 'stop_review_pending',
    'requiresOdometerReview': requiresOdometerReview,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'gpsDistanceCanReplaceOdometerSilently': false,
    'mapRouteCanReplaceOdometerSilently': false,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'commandCanApplyCalibration': false,
    'commandCanCreateOfficialMileage': false,
    'commandCanSetGlobalTruth': false,
    'commandCanChangeOfficialMileage': false,
    'localSessionRequired': _requiresLocalSession(command),
    'canUploadMirror': canUploadMirror,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'remoteTotalsCanonical': false,
    'canDeleteLocalData': false,
    'canPurgeLocalDataSilently': false,
    'durableStorageIsSharedAcrossModules': true,
    'profile': profileToken,
    'warnings': allowedWarnings,
    'rawLocationIncluded': false,
    'preciseRouteIncluded': false,
    'rawSensorPayloadIncluded': false,
    'tokensIncluded': false,
  };

  String get profileToken {
    final parts = reasonCode.split(':');
    if (parts.length == 2 && parts.first == 'profile') return parts.last;
    return 'validated_trip_tracking_profile';
  }
}
