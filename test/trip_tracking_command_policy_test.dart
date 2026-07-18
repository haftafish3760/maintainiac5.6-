import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_command_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_device_operational_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_onboarding_profile_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_storage_policy.dart'
    as durable_storage;

void main() {
  test('manual day start is available without maps or GPS consent', () {
    final decision = TripTrackingCommandPolicy.evaluate(context());
    final safe = decision.toSafeDashboardCommandMap();

    expect(decision.isAllowed, isTrue);
    expect(decision.gpsTrackingRequested, isFalse);
    expect(safe['dashboardStartButtonVisible'], isTrue);
    expect(safe['gpsTrackingCanRunWithoutMaps'], isTrue);
    expect(safe['mapsRequiredForCommand'], isFalse);
    expect(safe['mapboxCanStartTracking'], isFalse);
    expect(safe['localTextRecordWillBeWritten'], isTrue);
  });

  test('GPS trip start requires explicit GPS readiness and user consent', () {
    final blocked = TripTrackingCommandPolicy.evaluate(
      context(command: TripTrackingDashboardCommand.startGpsTrip),
    );
    final allowed = TripTrackingCommandPolicy.evaluate(
      context(
        command: TripTrackingDashboardCommand.startGpsTrip,
        deviceConsentDecision: deviceConsent(ready: true),
      ),
    );

    expect(blocked.status, TripTrackingCommandStatus.blocked);
    expect(blocked.reasonCode, 'gps_tracking_not_ready_or_consented');
    expect(allowed.status, TripTrackingCommandStatus.allowed);
    expect(allowed.reasonCode, 'gps_trip_start_ready');
    expect(
      allowed
          .toSafeDashboardCommandMap()['gpsStartRequiresLocalUserConfirmation'],
      isTrue,
    );
    expect(
      allowed
          .toSafeDashboardCommandMap()['gpsStartRequiresValidatedPlatformGrant'],
      isTrue,
    );
    expect(
      allowed
          .toSafeDashboardCommandMap()['gpsStartRequiresCurrentDeviceConsent'],
      isTrue,
    );
  });

  test(
    'remote, Mapbox, Firebase, and employer sources cannot start tracking',
    () {
      for (final source in const [
        TripTrackingCommandSource.firebaseMirror,
        TripTrackingCommandSource.cloudFunction,
        TripTrackingCommandSource.mapbox,
        TripTrackingCommandSource.employerDashboard,
      ]) {
        final decision = TripTrackingCommandPolicy.evaluate(
          context(
            command: TripTrackingDashboardCommand.startGpsTrip,
            source: source,
            deviceConsentDecision: deviceConsent(ready: true),
          ),
        );
        final safe = decision.toSafeDashboardCommandMap();

        expect(decision.status, TripTrackingCommandStatus.blocked);
        expect(
          decision.reasonCode,
          'remote_or_third_party_command_not_authorized',
        );
        expect(safe['firebaseCanStartTracking'], isFalse);
        expect(safe['remoteMirrorCanStartTracking'], isFalse);
        expect(safe['employerCanStartTracking'], isFalse);
      }
    },
  );

  test('pickup, dropoff, and stop buttons create review records only', () {
    for (final command in const [
      TripTrackingDashboardCommand.addStopReview,
      TripTrackingDashboardCommand.addPickupReview,
      TripTrackingDashboardCommand.addDropoffReview,
    ]) {
      final decision = TripTrackingCommandPolicy.evaluate(
        context(
          command: command,
          activeTripInProgress: true,
          localSessionAvailable: true,
          deviceConsentDecision: deviceConsent(ready: true),
        ),
      );
      final safe = decision.toSafeDashboardCommandMap();

      expect(decision.isAllowed, isTrue);
      expect(decision.requiresStopReview, isTrue);
      expect(decision.createsOfficialStop, isFalse);
      expect(safe['createsOfficialStop'], isFalse);
      expect(safe['walkingEvidenceCanOnlySuggestReview'], isTrue);
    }
  });

  test(
    'stop review commands require an active local session and no duplicate review',
    () {
      final noSession = TripTrackingCommandPolicy.evaluate(
        context(command: TripTrackingDashboardCommand.addStopReview),
      );
      final duplicate = TripTrackingCommandPolicy.evaluate(
        context(
          command: TripTrackingDashboardCommand.addStopReview,
          activeTripInProgress: true,
          localSessionAvailable: true,
          pendingStopReview: true,
        ),
      );

      expect(noSession.reasonCode, 'active_local_trip_required');
      expect(duplicate.reasonCode, 'stop_review_pending');
      expect(
        duplicate
            .toSafeDashboardCommandMap()['pendingStopReviewBlocksDuplicateReview'],
        isTrue,
      );
    },
  );

  test('ending a trip opens odometer review instead of confirming mileage', () {
    final decision = TripTrackingCommandPolicy.evaluate(
      context(
        command: TripTrackingDashboardCommand.endTripForOdometerReview,
        activeTripInProgress: true,
        localSessionAvailable: true,
        deviceConsentDecision: deviceConsent(ready: true),
      ),
    );
    final safe = decision.toSafeDashboardCommandMap();

    expect(decision.isAllowed, isTrue);
    expect(decision.requiresOdometerReview, isTrue);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['gpsDistanceCanReplaceOdometerSilently'], isFalse);
    expect(safe['mapRouteCanReplaceOdometerSilently'], isFalse);
    expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
    expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
    expect(safe['commandCanApplyCalibration'], isFalse);
    expect(safe['commandCanCreateOfficialMileage'], isFalse);
  });

  test(
    'low and unknown storage warn but still allow cheap trip text records',
    () {
      final low = TripTrackingCommandPolicy.evaluate(
        context(
          storageDecision: storage(
            durable_storage.TripTrackingStorageAction.warn,
          ),
        ),
      );
      final unknown = TripTrackingCommandPolicy.evaluate(
        context(
          storageDecision: storage(
            durable_storage.TripTrackingStorageAction.unknown,
          ),
        ),
      );

      expect(low.status, TripTrackingCommandStatus.warningAllowed);
      expect(low.allowedWarnings, contains('low_storage_text_record_allowed'));
      expect(unknown.status, TripTrackingCommandStatus.warningAllowed);
      expect(
        unknown.allowedWarnings,
        contains('storage_unknown_text_record_allowed'),
      );
    },
  );

  test('blocked storage blocks new command writes without deleting data', () {
    final decision = TripTrackingCommandPolicy.evaluate(
      context(
        storageDecision: storage(
          durable_storage.TripTrackingStorageAction.block,
        ),
      ),
    );
    final safe = decision.toSafeDashboardCommandMap();

    expect(decision.status, TripTrackingCommandStatus.blocked);
    expect(decision.reasonCode, 'local_text_record_storage_blocked');
    expect(safe['canDeleteLocalData'], isFalse);
    expect(safe['canPurgeLocalDataSilently'], isFalse);
    expect(safe['durableStorageIsSharedAcrossModules'], isTrue);
  });

  test(
    'safe command summaries never include tokens, raw routes, or remote totals',
    () {
      final safe = TripTrackingCommandPolicy.evaluate(
        context(
          command: TripTrackingDashboardCommand.endTripForOdometerReview,
          activeTripInProgress: true,
          localSessionAvailable: true,
        ),
      ).toSafeDashboardCommandMap();

      expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
      expect(safe['firestoreMirrorOnly'], isTrue);
      expect(safe['remoteTotalsCanonical'], isFalse);
      expect(safe['rawLocationIncluded'], isFalse);
      expect(safe['preciseRouteIncluded'], isFalse);
      expect(safe['rawSensorPayloadIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
      expect(safe.toString(), isNot(contains('pk.')));
      expect(safe.toString(), isNot(contains('sk.')));
    },
  );

  test('safe command summary validates start and storage boundaries', () {
    final validation = TripTrackingCommandSummaryValidation.fromSummary(
      TripTrackingCommandPolicy.evaluate(
        context(
          command: TripTrackingDashboardCommand.startGpsTrip,
          deviceConsentDecision: deviceConsent(ready: true),
        ),
      ).toSafeDashboardCommandMap(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.reasons, isEmpty);
  });

  test('forged command summaries cannot start tracking remotely', () {
    final validation = TripTrackingCommandSummaryValidation.fromSummary(
      TripTrackingCommandPolicy.evaluate(context()).toSafeDashboardCommandMap()
        ..addAll({
          'mapboxCanStartTracking': true,
          'firebaseCanStartTracking': true,
          'cloudFunctionCanStartTracking': true,
          'remoteMirrorCanStartTracking': true,
          'employerCanStartTracking': true,
          'employerCanTrackWithoutMutualConsent': true,
          'mutualFleetTrackingConsentRequired': false,
          'mapsRequired': true,
          'mapsRequiredForCommand': true,
          'gpsTrackingCanRunWithoutMaps': false,
          'createsOfficialStop': true,
          'walkingEvidenceCanOnlySuggestReview': false,
          'odometerRemainsOfficialMileageTruth': false,
          'odometerIsGlobalTruth': false,
          'gpsDistanceCanReplaceOdometerSilently': true,
          'mapRouteCanReplaceOdometerSilently': true,
          'calibrationRequiresTrustedGpsWindow': false,
          'poorGpsDaysExcludedFromCalibration': false,
          'commandCanApplyCalibration': true,
          'commandCanCreateOfficialMileage': true,
          'hiveRemainsOperationalSourceOfTruth': false,
          'firestoreMirrorOnly': false,
          'remoteTotalsCanonical': true,
          'canDeleteLocalData': true,
          'canPurgeLocalDataSilently': true,
          'durableStorageIsSharedAcrossModules': false,
          'rawLocationIncluded': true,
          'preciseRouteIncluded': true,
          'rawSensorPayloadIncluded': true,
          'tokensIncluded': true,
          'debug': 'sk.secret 35.123456,-80.123456',
        }),
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      contains('remote_or_employer_can_start_tracking'),
    );
    expect(validation.reasons, contains('maps_required_for_trip_command'));
    expect(validation.reasons, contains('command_can_create_trip_truth'));
    expect(validation.reasons, contains('command_storage_boundary_missing'));
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_command_material'),
    );
  });
}

TripTrackingCommandContext context({
  TripTrackingDashboardCommand command =
      TripTrackingDashboardCommand.startManualDay,
  TripTrackingCommandSource source = TripTrackingCommandSource.localUser,
  TripTrackingDeviceConsentDecision? deviceConsentDecision,
  durable_storage.TripTrackingStorageDecision? storageDecision,
  bool localSessionAvailable = false,
  bool activeTripInProgress = false,
  bool pendingOdometerReview = false,
  bool pendingStopReview = false,
  bool userConfirmedAction = false,
  bool mutualFleetTrackingConsent = false,
}) {
  return TripTrackingCommandContext(
    command: command,
    source: source,
    profileDecision: TripTrackingOnboardingProfilePolicy.choose(
      workIntent: TripTrackingOnboardingWorkIntent.delivery,
      driverPattern: TripTrackingOnboardingDriverPattern.exitsVehicleAtStops,
      userWantsBusinessTracking: true,
      userWantsMultipleVehicles: false,
      userWantsMultipleWorkProfiles: false,
    ),
    deviceConsentDecision: deviceConsentDecision ?? deviceConsent(),
    storageDecision:
        storageDecision ??
        storage(durable_storage.TripTrackingStorageAction.allow),
    localSessionAvailable: localSessionAvailable,
    activeTripInProgress: activeTripInProgress,
    pendingOdometerReview: pendingOdometerReview,
    pendingStopReview: pendingStopReview,
    userConfirmedAction: userConfirmedAction,
    mutualFleetTrackingConsent: mutualFleetTrackingConsent,
  );
}

TripTrackingDeviceConsentDecision deviceConsent({bool ready = false}) {
  return TripTrackingDeviceConsentPolicy.evaluate(
    settings: const TripTrackingSettings().copyWith(
      gpsAssistedTrackingEnabled: ready,
      backgroundTrackingEnabled: false,
      activityRecognitionEnabled: false,
    ),
    capabilities: const TripTrackingPlatformCapabilities(
      locationAvailable: true,
      backgroundTrackingAvailable: true,
      activityRecognitionAvailable: true,
      batteryStateAvailable: true,
      lowPowerModeAvailable: true,
    ),
    userConsentedToGps: ready,
    userConsentedToBackground: false,
    userConsentedToActivityRecognition: false,
  );
}

durable_storage.TripTrackingStorageDecision storage(
  durable_storage.TripTrackingStorageAction action,
) {
  return durable_storage.TripTrackingStorageDecision(
    action: action,
    storageState: action.name,
    safeReason: action.name,
    message: '',
    availableBytes: null,
    requiredBytes: 1,
  );
}
