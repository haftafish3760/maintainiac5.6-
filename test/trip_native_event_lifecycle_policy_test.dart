import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_native_event_lifecycle_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';

void main() {
  test('location events can activate a starting session and feed engine', () {
    final decision = TripNativeEventLifecyclePolicy.evaluate(
      currentState: TripTrackingSessionLifecycleState.starting,
      event: locationEvent(),
    );
    final safe = decision.toSafeSummary();

    expect(decision.action, TripNativeEventLifecycleAction.ingestLocation);
    expect(decision.to, TripTrackingSessionLifecycleState.active);
    expect(decision.canFeedEngine, isTrue);
    expect(safe['nativeEventTrustedAfterValidationOnly'], isTrue);
    expect(safe['nativeEventCanConfirmOdometer'], isFalse);
    expect(safe['nativeEventCanSetGlobalTruth'], isFalse);
    expect(safe['nativeEventCanChangeOfficialMileage'], isFalse);
  });

  test('activity events recover lifecycle but do not feed distance engine', () {
    final decision = TripNativeEventLifecyclePolicy.evaluate(
      currentState: TripTrackingSessionLifecycleState.recovering,
      event: activityEvent(),
    );

    expect(decision.action, TripNativeEventLifecycleAction.ingestActivity);
    expect(decision.to, TripTrackingSessionLifecycleState.active);
    expect(decision.canFeedEngine, isFalse);
  });

  test('permission loss requires user review and cannot complete trip', () {
    final decision = TripNativeEventLifecyclePolicy.evaluate(
      currentState: TripTrackingSessionLifecycleState.starting,
      event: authorizationEvent(TripTrackingAuthorizationState.denied),
    );
    final safe = decision.toSafeSummary();

    expect(
      decision.action,
      TripNativeEventLifecycleAction.requestUserPermissionReview,
    );
    expect(decision.to, TripTrackingSessionLifecycleState.permissionRequired);
    expect(decision.requiresUserReview, isTrue);
    expect(safe['permissionLossRequiresUserReview'], isTrue);
    expect(safe['permissionLossCannotFeedEngine'], isTrue);
    expect(safe['nativeEventCanForceComplete'], isFalse);
    expect(safe['backgroundPauseRequiresRecoveryPath'], isTrue);
  });

  test(
    'background restriction moves active trip to recoverable interruption',
    () {
      final decision = TripNativeEventLifecyclePolicy.evaluate(
        currentState: TripTrackingSessionLifecycleState.active,
        event: statusEvent('backgroundRestricted'),
      );

      expect(decision.action, TripNativeEventLifecycleAction.markInterrupted);
      expect(
        decision.reason,
        TripNativeEventLifecycleReason.backgroundRestricted,
      );
      expect(decision.to, TripTrackingSessionLifecycleState.interrupted);
      expect(decision.requiresUserReview, isTrue);
      expect(
        decision
            .toSafeSummary()['backgroundRestrictionCanOnlyInterruptRecoverably'],
        isTrue,
      );
      expect(
        decision.toSafeSummary()['foregroundServiceLossRequiresRecoveryPath'],
        isTrue,
      );
    },
  );

  test('native stopped status is ignored instead of ending local trip', () {
    final decision = TripNativeEventLifecyclePolicy.evaluate(
      currentState: TripTrackingSessionLifecycleState.active,
      event: statusEvent('stopped'),
    );
    final safe = decision.toSafeSummary();

    expect(decision.action, TripNativeEventLifecycleAction.ignoreEvent);
    expect(decision.to, TripTrackingSessionLifecycleState.active);
    expect(decision.requiresUserReview, isTrue);
    expect(safe['nativeEventCanForceComplete'], isFalse);
    expect(safe['lateNativeStoppedStatusCannotEndTrip'], isTrue);
    expect(safe['activityEventCannotFeedDistanceEngine'], isTrue);
    expect(safe['nativeStatusRequiresLocalStateMachineTransition'], isTrue);
  });

  test('completed sessions cannot resume from late native events', () {
    final decision = TripNativeEventLifecyclePolicy.evaluate(
      currentState: TripTrackingSessionLifecycleState.completed,
      event: locationEvent(),
    );

    expect(decision.action, TripNativeEventLifecycleAction.ignoreEvent);
    expect(
      decision.reason,
      TripNativeEventLifecycleReason.completedSessionProtected,
    );
    expect(decision.to, TripTrackingSessionLifecycleState.completed);
    expect(decision.canFeedEngine, isFalse);
  });

  test('location events cannot feed engine while permission is required', () {
    final decision = TripNativeEventLifecyclePolicy.evaluate(
      currentState: TripTrackingSessionLifecycleState.permissionRequired,
      event: locationEvent(),
    );
    final safe = decision.toSafeSummary();

    expect(decision.canFeedEngine, isFalse);
    expect(decision.requiresUserReview, isTrue);
    expect(safe['canFeedEngine'], isFalse);
    expect(safe['permissionLossRequiresUserReview'], isTrue);
    expect(safe['nativeEventCanConfirmOdometer'], isFalse);
  });

  test('location events cannot feed engine while trip is paused', () {
    final decision = TripNativeEventLifecyclePolicy.evaluate(
      currentState: TripTrackingSessionLifecycleState.paused,
      event: locationEvent(),
    );
    final safe = decision.toSafeSummary();

    expect(decision.action, TripNativeEventLifecycleAction.ingestLocation);
    expect(decision.to, TripTrackingSessionLifecycleState.paused);
    expect(decision.canFeedEngine, isFalse);
    expect(decision.requiresUserReview, isTrue);
    expect(safe['canFeedEngine'], isFalse);
    expect(safe['nativeEventCanConfirmOdometer'], isFalse);
    expect(safe['nativeEventCanSetGlobalTruth'], isFalse);
    expect(safe['nativeStatusRequiresLocalStateMachineTransition'], isTrue);
  });

  test('terminal failure cannot be revived by a late location event', () {
    final decision = TripNativeEventLifecyclePolicy.evaluate(
      currentState: TripTrackingSessionLifecycleState.failedTerminal,
      event: locationEvent(),
    );

    expect(decision.action, TripNativeEventLifecycleAction.ignoreEvent);
    expect(decision.to, TripTrackingSessionLifecycleState.failedTerminal);
    expect(decision.canFeedEngine, isFalse);
    expect(decision.requiresUserReview, isTrue);
  });

  test(
    'malformed native events fail into recovery without raw payload leakage',
    () {
      final decision = TripNativeEventLifecyclePolicy.evaluate(
        currentState: TripTrackingSessionLifecycleState.active,
        event: TripTrackingPlatformEvent.fromNativePayload('bad'),
      );
      final safe = decision.toSafeSummary();

      expect(decision.action, TripNativeEventLifecycleAction.markInterrupted);
      expect(decision.to, TripTrackingSessionLifecycleState.failedRecoverable);
      expect(safe['physicalOdometerRequiredForOfficialMileage'], isTrue);
      expect(safe['confirmedOdometerOverridesExternalMileage'], isTrue);
      expect(safe['externalMileageCannotBecomeGlobalTruth'], isTrue);
      expect(safe['gpsDistanceCanOnlyAdviseMileageReview'], isTrue);
      expect(safe['mapMatchingCanOnlyAdviseMileageReview'], isTrue);
      expect(safe['optimizationCannotChangeOfficialMileage'], isTrue);
      expect(safe['rawNativePayloadIncluded'], isFalse);
      expect(safe['rawLocationIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
      expect(safe.toString(), isNot(contains('pk.')));
      expect(safe.toString(), isNot(contains('sk.')));
    },
  );

  test('safe native lifecycle summary validates as renderable', () {
    final validation = TripNativeEventLifecycleSummaryValidation.fromSummary(
      TripNativeEventLifecyclePolicy.evaluate(
        currentState: TripTrackingSessionLifecycleState.starting,
        event: locationEvent(),
      ).toSafeSummary(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.action, TripNativeEventLifecycleAction.ingestLocation);
    expect(validation.reasons, isEmpty);
  });

  test('native lifecycle summary rejects mutation and sensitive claims', () {
    final validation = TripNativeEventLifecycleSummaryValidation.fromSummary(
      TripNativeEventLifecyclePolicy.evaluate(
        currentState: TripTrackingSessionLifecycleState.active,
        event: statusEvent('recovering'),
      ).toSafeSummary()..addAll({
        'nativeEventCanForceComplete': true,
        'nativeEventCanDeleteCheckpoint': true,
        'nativeEventCanConfirmOdometer': true,
        'nativeEventCanSetGlobalTruth': true,
        'nativeEventCanChangeOfficialMileage': true,
        'nativeEventCanCreateOfficialStop': true,
        'nativeEventCanPurgeLocalDataAfterBackup': true,
        'nativeEventCanBypassLocalCheckpoint': true,
        'mapboxEventCanForceLifecycle': true,
        'firestoreEventCanForceLifecycle': true,
        'cloudFunctionCanForceLifecycle': true,
        'remoteLifecycleCanOverrideLocalCheckpoint': true,
        'nativeEventCanBypassAuthorization': true,
        'nativeEventCanBypassUserConsent': true,
        'foregroundServiceLossRequiresRecoveryPath': false,
        'permissionLossCannotFeedEngine': false,
        'activityEventCannotFeedDistanceEngine': false,
        'rawNativePayloadIncluded': true,
        'rawLocationIncluded': true,
        'preciseTimestampIncluded': true,
        'tokensIncluded': true,
        'debug': 'sk.secret 35.123456,-80.123456',
      }),
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('native_event_can_mutate_trip_truth'));
    expect(validation.reasons, contains('remote_event_can_force_lifecycle'));
    expect(validation.reasons, contains('permission_boundary_missing'));
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_native_material'),
    );
    expect(validation.reasons, contains('summary_contains_sensitive_text'));
  });
}

TripTrackingPlatformEvent locationEvent() {
  return TripTrackingPlatformEvent.fromMap({
    'schemaVersion': 1,
    'type': 'location',
    'latitude': 35.0,
    'longitude': -80.0,
    'horizontalAccuracyMeters': 8,
    'recordedAt': DateTime.utc(2026, 7, 18, 12).toIso8601String(),
    'speedMetersPerSecond': 12,
  });
}

TripTrackingPlatformEvent activityEvent() {
  return TripTrackingPlatformEvent.fromMap({
    'schemaVersion': 1,
    'type': 'activity',
    'activity': 'walking',
    'confidence': 80,
    'recordedAt': DateTime.utc(2026, 7, 18, 12).toIso8601String(),
  });
}

TripTrackingPlatformEvent authorizationEvent(
  TripTrackingAuthorizationState state,
) {
  return TripTrackingPlatformEvent.fromMap({
    'schemaVersion': 1,
    'type': 'authorization',
    'state': state.name,
    'preciseLocation': state != TripTrackingAuthorizationState.denied,
  });
}

TripTrackingPlatformEvent statusEvent(String status) {
  return TripTrackingPlatformEvent.fromMap({
    'schemaVersion': 1,
    'type': 'status',
    'status': status,
  });
}
