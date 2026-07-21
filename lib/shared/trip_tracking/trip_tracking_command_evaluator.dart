part of 'trip_tracking_command_policy.dart';

// odometerIsGlobalTruth: true. Commands are policy gates; they never override
// or replace official odometer truth and only route to the mandatory review flow.
const bool odometerIsGlobalTruth = true;

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
      TripTrackingDashboardCommand.cancelActiveTrip => _cancelActiveTrip(context),
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

TripTrackingCommandDecision _cancelActiveTrip(
  TripTrackingCommandContext context,
) {
  if (!context.activeTripInProgress || !context.localSessionAvailable) {
    return _blocked(context, 'active_local_trip_required');
  }
  return _allowed(
    context,
    reasonCode: context.userConfirmedAction
        ? 'trip_cancel_confirmed'
        : 'trip_cancel_ready',
    gpsTrackingRequested: false,
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
    TripTrackingDashboardCommand.cancelActiveTrip ||
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
    'trip_cancel_ready' ||
    'trip_cancel_confirmed' ||
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

TripTrackingDashboardCommand? _safeCommand(Object? value) {
  if (value is! String) return null;
  for (final command in TripTrackingDashboardCommand.values) {
    if (command.name == value) return command;
  }
  return null;
}

TripTrackingCommandStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripTrackingCommandStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
