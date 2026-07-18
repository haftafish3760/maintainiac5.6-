import 'trip_tracking_device_operational_policy.dart';
import 'trip_tracking_onboarding_profile_policy.dart';
import 'trip_tracking_storage_policy.dart' as durable_storage;

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
    'gpsDistanceCanReplaceOdometerSilently': false,
    'mapRouteCanReplaceOdometerSilently': false,
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

class TripTrackingCommandPolicy {
  const TripTrackingCommandPolicy._();

  static TripTrackingCommandDecision evaluate(
    TripTrackingCommandContext context,
  ) {
    final sourceBlock = _blockedSourceReason(context);
    if (sourceBlock != null) {
      return _blocked(context, sourceBlock);
    }
    if (!context.storageDecision.canWriteTextRecord) {
      return _blocked(context, 'local_text_record_storage_blocked');
    }

    return switch (context.command) {
      TripTrackingDashboardCommand.startManualDay => _startManualDay(context),
      TripTrackingDashboardCommand.startGpsTrip => _startGpsTrip(context),
      TripTrackingDashboardCommand.addStopReview => _reviewEvent(
        context,
        'manual_stop_review_ready',
      ),
      TripTrackingDashboardCommand.addPickupReview => _reviewEvent(
        context,
        'pickup_review_ready',
      ),
      TripTrackingDashboardCommand.addDropoffReview => _reviewEvent(
        context,
        'dropoff_review_ready',
      ),
      TripTrackingDashboardCommand.endTripForOdometerReview => _endTrip(
        context,
      ),
      TripTrackingDashboardCommand.reviewMileage => _reviewMileage(context),
    };
  }
}

TripTrackingCommandDecision _startManualDay(
  TripTrackingCommandContext context,
) {
  if (context.activeTripInProgress) {
    return _blocked(context, 'trip_already_active');
  }
  return _allowed(
    context,
    reasonCode: context.userConfirmedAction
        ? 'manual_day_start_confirmed'
        : 'manual_day_start_ready',
    gpsTrackingRequested: false,
    warning: _storageWarning(context),
  );
}

TripTrackingCommandDecision _startGpsTrip(TripTrackingCommandContext context) {
  if (context.activeTripInProgress) {
    return _blocked(context, 'trip_already_active');
  }
  if (!context.deviceConsentDecision.canStartGpsTracking) {
    return _blocked(context, 'gps_tracking_not_ready_or_consented');
  }
  return _allowed(
    context,
    reasonCode: context.userConfirmedAction
        ? 'gps_trip_start_confirmed'
        : 'gps_trip_start_ready',
    gpsTrackingRequested: true,
    warning: _storageWarning(context),
  );
}

TripTrackingCommandDecision _reviewEvent(
  TripTrackingCommandContext context,
  String reasonCode,
) {
  if (!context.activeTripInProgress || !context.localSessionAvailable) {
    return _blocked(context, 'active_local_trip_required');
  }
  if (context.pendingStopReview) {
    return _blocked(context, 'stop_review_pending');
  }
  return _allowed(
    context,
    reasonCode: reasonCode,
    gpsTrackingRequested: context.deviceConsentDecision.canStartGpsTracking,
    requiresStopReview: true,
    warning: _storageWarning(context),
  );
}

TripTrackingCommandDecision _endTrip(TripTrackingCommandContext context) {
  if (!context.activeTripInProgress || !context.localSessionAvailable) {
    return _blocked(context, 'active_local_trip_required');
  }
  return _allowed(
    context,
    reasonCode: 'end_trip_requires_odometer_review',
    gpsTrackingRequested: context.deviceConsentDecision.canStartGpsTracking,
    requiresOdometerReview: true,
    warning: _storageWarning(context),
  );
}

TripTrackingCommandDecision _reviewMileage(TripTrackingCommandContext context) {
  if (!context.localSessionAvailable) {
    return _blocked(context, 'local_session_required');
  }
  if (!context.pendingOdometerReview && context.activeTripInProgress) {
    return _blocked(context, 'finish_trip_before_mileage_review');
  }
  return _allowed(
    context,
    reasonCode: 'odometer_review_ready',
    gpsTrackingRequested: false,
    requiresOdometerReview: true,
    warning: _storageWarning(context),
  );
}

String? _blockedSourceReason(TripTrackingCommandContext context) {
  if (context.source == TripTrackingCommandSource.localUser) return null;
  if (context.source == TripTrackingCommandSource.employerDashboard &&
      context.mutualFleetTrackingConsent &&
      context.command == TripTrackingDashboardCommand.reviewMileage) {
    return null;
  }
  return 'remote_or_third_party_command_not_authorized';
}

TripTrackingCommandDecision _allowed(
  TripTrackingCommandContext context, {
  required String reasonCode,
  required bool gpsTrackingRequested,
  bool requiresStopReview = false,
  bool requiresOdometerReview = false,
  String? warning,
}) {
  final warnings = warning == null ? const <String>[] : <String>[warning];
  return TripTrackingCommandDecision(
    status: warnings.isEmpty
        ? TripTrackingCommandStatus.allowed
        : TripTrackingCommandStatus.warningAllowed,
    reasonCode: reasonCode,
    command: context.command,
    dashboardStartButtonVisible: true,
    localTextRecordWillBeWritten: true,
    gpsTrackingRequested: gpsTrackingRequested,
    mapsRequired: false,
    createsOfficialStop: false,
    requiresStopReview: requiresStopReview,
    requiresOdometerReview: requiresOdometerReview,
    canUploadMirror: true,
    allowedWarnings: List.unmodifiable(warnings),
  );
}

TripTrackingCommandDecision _blocked(
  TripTrackingCommandContext context,
  String reasonCode,
) {
  return TripTrackingCommandDecision(
    status: TripTrackingCommandStatus.blocked,
    reasonCode: reasonCode,
    command: context.command,
    dashboardStartButtonVisible: true,
    localTextRecordWillBeWritten: false,
    gpsTrackingRequested: false,
    mapsRequired: false,
    createsOfficialStop: false,
    requiresStopReview: false,
    requiresOdometerReview: false,
    canUploadMirror: false,
    allowedWarnings: const [],
  );
}

String? _storageWarning(TripTrackingCommandContext context) {
  if (context.storageDecision.shouldWarnUser) {
    return 'low_storage_text_record_allowed';
  }
  if (context.storageDecision.action ==
      durable_storage.TripTrackingStorageAction.unknown) {
    return 'storage_unknown_text_record_allowed';
  }
  return null;
}

bool _requiresLocalSession(TripTrackingDashboardCommand command) {
  return switch (command) {
    TripTrackingDashboardCommand.startManualDay ||
    TripTrackingDashboardCommand.startGpsTrip => false,
    TripTrackingDashboardCommand.addStopReview ||
    TripTrackingDashboardCommand.addPickupReview ||
    TripTrackingDashboardCommand.addDropoffReview ||
    TripTrackingDashboardCommand.endTripForOdometerReview ||
    TripTrackingDashboardCommand.reviewMileage => true,
  };
}

String _safeReason(String value) {
  final clean = value.trim();
  return switch (clean) {
    'manual_day_start_ready' ||
    'manual_day_start_confirmed' ||
    'gps_trip_start_ready' ||
    'gps_trip_start_confirmed' ||
    'manual_stop_review_ready' ||
    'pickup_review_ready' ||
    'dropoff_review_ready' ||
    'end_trip_requires_odometer_review' ||
    'odometer_review_ready' ||
    'remote_or_third_party_command_not_authorized' ||
    'local_text_record_storage_blocked' ||
    'trip_already_active' ||
    'gps_tracking_not_ready_or_consented' ||
    'active_local_trip_required' ||
    'stop_review_pending' ||
    'local_session_required' ||
    'finish_trip_before_mileage_review' => clean,
    _ => 'trip_command_not_authorized',
  };
}
