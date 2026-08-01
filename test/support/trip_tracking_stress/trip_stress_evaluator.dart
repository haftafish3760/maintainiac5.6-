// Production-policy evaluator for deterministic GPS stress scenarios.
//
// Owns cross-policy invariant checks and concise failure evidence. It does not
// persist sessions, access devices, or retain route geometry. The bounded
// stress runner consumes it for generated and saved regression scenarios.

import 'package:maintaniac/shared/trip_tracking/trip_automatic_start_detector.dart';
import 'package:maintaniac/shared/trip_tracking/trip_battery_gps_continuation_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_location_sample_intake_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_state_machine.dart';

import 'trip_stress_scenario.dart';

final class TripStressEvaluation {
  const TripStressEvaluation({required this.passed, required this.evidence});

  final bool passed;
  final Map<String, Object?> evidence;
}

final class TripStressEvaluator {
  const TripStressEvaluator();

  TripStressEvaluation evaluate(TripStressScenario scenario) =>
      switch (scenario.family) {
        TripStressFamily.providerStartup => _provider(scenario),
        TripStressFamily.locationEvidence => _location(scenario),
        TripStressFamily.motionStops => _motion(scenario),
        TripStressFamily.lifecycleRecovery => _lifecycle(scenario),
        TripStressFamily.batteryDevice => _battery(scenario),
        TripStressFamily.bluetooth => _bluetooth(scenario),
        TripStressFamily.automaticStart => _automaticStart(scenario),
        TripStressFamily.distanceOdometer => _distance(scenario),
      };

  TripStressEvaluation _provider(TripStressScenario scenario) {
    final states = TripTrackingSessionLifecycleState.values;
    final from = states[scenario.initialLifecycleIndex % states.length];
    final to = states[scenario.targetLifecycleIndex % states.length];
    final decision = TripTrackingSessionStateMachine.evaluateTransition(
      from,
      to,
    );
    final confirmedHistory =
        from == TripTrackingSessionLifecycleState.completed;
    final passed = !confirmedHistory || from == to || !decision.allowed;
    return _result(passed, {
      'from': from.name,
      'to': to.name,
      'allowed': decision.allowed,
      'confirmedHistoryProtected': confirmedHistory,
    });
  }

  TripStressEvaluation _location(TripStressScenario scenario) {
    final now = DateTime.utc(
      2026,
      7,
      28,
      12,
    ).add(Duration(seconds: scenario.index % 3600));
    final safePermission =
        scenario.permissionState == TripStressPermissionState.always ||
        scenario.permissionState == TripStressPermissionState.whileInUse;
    final safeProvider =
        scenario.providerState != TripStressProviderState.unavailable;
    final expectedAccepted = safePermission && safeProvider;
    final recordedAt = expectedAccepted
        ? now.subtract(const Duration(seconds: 2))
        : now.subtract(const Duration(days: 2));
    final decision = TripLocationSampleIntakeGuard.evaluate(
      payload: {
        'schemaVersion': 1,
        'ownerUid': 'stress_owner',
        'sessionId': 'stress_session',
        'source': 'native_location',
        'sample': {
          'latitude': 35.0,
          'longitude': -80.0,
          'recordedAt': recordedAt.millisecondsSinceEpoch,
          'horizontalAccuracyMeters': 8.0,
          'speedMetersPerSecond': 4.0,
        },
      },
      expectedOwnerUid: 'stress_owner',
      expectedSessionId: 'stress_session',
      receivedAt: now,
    );
    final passed = decision.canFeedTripEngine == expectedAccepted;
    return _result(passed, {
      'expectedAccepted': expectedAccepted,
      'actualAccepted': decision.canFeedTripEngine,
      'reason': decision.reason.name,
    });
  }

  TripStressEvaluation _motion(TripStressScenario scenario) {
    final start = DateTime.utc(2026, 7, 28, 12);
    final engine = TripTrackingEngine();
    TripLocationSample sample(double longitude, int seconds) =>
        TripLocationSample(
          latitude: 35,
          longitude: longitude,
          recordedAt: start.add(Duration(seconds: seconds)),
          horizontalAccuracyMeters: 5,
        );
    TripActivityObservation activity(TripActivity value, int seconds) =>
        TripActivityObservation(
          activity: value,
          confidence: 90,
          recordedAt: start.add(Duration(seconds: seconds)),
        );
    engine.ingest(
      sample(-80, 0),
      activity: activity(TripActivity.automotive, 0),
    );
    engine.ingest(
      sample(-79.9997, 15),
      activity: activity(TripActivity.automotive, 15),
    );
    final beforeWalk = engine.totalAcceptedMeters;
    final walk = engine.ingest(
      sample(-79.9987, 60),
      activity: activity(TripActivity.walking, 60),
    );
    final returned = engine.ingest(sample(-79.9997, 75));
    final passed =
        walk.disposition == TripSampleDisposition.excludedWalking &&
        returned.disposition == TripSampleDisposition.rejectedDrift &&
        engine.totalAcceptedMeters == beforeWalk;
    return _result(passed, {
      'stopClass': scenario.stopClass.name,
      'walkDisposition': walk.disposition.name,
      'returnDisposition': returned.disposition.name,
      'distanceBeforeWalk': beforeWalk,
      'distanceAfterReturn': engine.totalAcceptedMeters,
    });
  }

  TripStressEvaluation _lifecycle(TripStressScenario scenario) {
    final states = TripTrackingSessionLifecycleState.values;
    final from = scenario.variant.isEven
        ? TripTrackingSessionLifecycleState.completed
        : states[scenario.initialLifecycleIndex % states.length];
    final to = states[scenario.targetLifecycleIndex % states.length];
    final allowed = TripTrackingSessionStateMachine.canTransition(from, to);
    final passed =
        from != TripTrackingSessionLifecycleState.completed ||
        from == to ||
        !allowed;
    return _result(passed, {
      'from': from.name,
      'to': to.name,
      'allowed': allowed,
    });
  }

  TripStressEvaluation _battery(TripStressScenario scenario) {
    final charging = scenario.batteryState == TripStressBatteryState.charging;
    final percent = switch (scenario.batteryState) {
      TripStressBatteryState.critical => 4,
      TripStressBatteryState.low => 12,
      _ => 75,
    };
    final batteryDecision = const TripTrackingPolicy().gpsBatteryDecision(
      batteryPercent: percent,
      isCharging: charging,
      lowBatteryProtectionEnabled: true,
      lowBatteryOverrideEnabled: false,
      lowBatteryWarningDismissed: false,
    );
    final decision = TripBatteryGpsContinuationPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.active,
      localSessionAvailable: true,
      batteryDecision: batteryDecision,
      appInBackground:
          scenario.lifecycleEvent == TripStressLifecycleEvent.background,
      foregroundServiceAvailable: scenario.variant % 3 != 0,
      backgroundTrackingPermissionGranted:
          scenario.permissionState == TripStressPermissionState.always,
    );
    return _result(
      decision.shouldKeepTripSessionAlive &&
          decision.shouldKeepTextTripLogWritable,
      {
        'status': decision.status.name,
        'tripAlive': decision.shouldKeepTripSessionAlive,
        'tripLogWritable': decision.shouldKeepTextTripLogWritable,
      },
    );
  }

  TripStressEvaluation _bluetooth(TripStressScenario scenario) {
    final trustedObservation =
        scenario.bluetoothState == TripStressBluetoothState.correct ||
        scenario.bluetoothState == TripStressBluetoothState.reconnect;
    final link = trustedObservation
        ? TripTrackingBluetoothVehicleLink(
            deviceId: 'stress_device',
            vehicleId: scenario.vehicleId,
            createdAt: DateTime.utc(2026, 7, 28),
          )
        : null;
    final decision = resolveBluetoothVehicleMatchDecision(
      settings: TripTrackingSettings(
        bluetoothVehicleRecognitionEnabled:
            scenario.bluetoothRecognitionEnabled,
        automaticVehicleSwitchEnabled: scenario.automaticVehicleSwitchEnabled,
      ),
      link: link,
      hasActiveGpsTrip: scenario.hasActiveSession,
      hasUnfinishedStoredSession: scenario.hasUnfinishedSession,
      activeVehicleId: scenario.hasActiveSession ? 'vehicle_locked' : null,
    );
    final passed =
        (!scenario.hasActiveSession || !decision.canSwitchVehicle) &&
        (trustedObservation ||
            (!decision.canSwitchVehicle && decision.vehicleId == null));
    return _result(passed, {
      'bluetoothState': scenario.bluetoothState.name,
      'trustedObservation': trustedObservation,
      'disposition': decision.disposition.name,
      'canSwitchVehicle': decision.canSwitchVehicle,
    });
  }

  TripStressEvaluation _automaticStart(TripStressScenario scenario) {
    final start = DateTime.utc(2026, 7, 28, 12);
    final trustedBluetooth =
        scenario.bluetoothState == TripStressBluetoothState.correct ||
        scenario.bluetoothState == TripStressBluetoothState.reconnect;
    final observations = List.generate(
      3,
      (index) => TripAutomaticStartObservation(
        recordedAt: start.add(Duration(seconds: index * 15)),
        speedMetersPerSecond: 7,
        displacementMeters: 25,
        horizontalAccuracyMeters: 8,
        activity: TripActivity.automotive,
        activityConfidence: 90,
        bluetoothVehicleId: trustedBluetooth ? scenario.vehicleId : null,
      ),
    );
    final decision = const TripAutomaticStartDetector().evaluate(
      enabled: true,
      accessLevel: scenario.paidAccess
          ? TripAutomaticStartAccessLevel.paid
          : TripAutomaticStartAccessLevel.free,
      hasActiveOrRecoverableSession:
          scenario.hasActiveSession || scenario.hasUnfinishedSession,
      observations: observations,
    );
    final blocked = scenario.hasActiveSession || scenario.hasUnfinishedSession;
    final passed =
        (!blocked || !decision.shouldSuggestStart) &&
        (trustedBluetooth || decision.suggestedVehicleId == null);
    return _result(passed, {
      'bluetoothState': scenario.bluetoothState.name,
      'trustedBluetooth': trustedBluetooth,
      'disposition': decision.disposition.name,
      'shouldSuggestStart': decision.shouldSuggestStart,
    });
  }

  TripStressEvaluation _distance(TripStressScenario scenario) {
    final engine = TripTrackingEngine();
    final start = DateTime.utc(2026, 7, 28, 12);
    TripLocationSample sample(double longitude, int seconds) =>
        TripLocationSample(
          latitude: 35,
          longitude: longitude,
          recordedAt: start.add(Duration(seconds: seconds)),
          horizontalAccuracyMeters: 5,
        );
    engine.ingest(sample(-80, 0));
    switch (scenario.distanceClass) {
      case TripStressDistanceClass.zero:
        break;
      case TripStressDistanceClass.measured:
        engine.ingest(sample(-79.9997, 15));
        break;
      case TripStressDistanceClass.estimatedGap:
        engine.ingest(sample(-79.99, 200));
        break;
      case TripStressDistanceClass.rejected:
        engine.ingest(sample(-79.9, 5));
        break;
      case TripStressDistanceClass.mixed:
        engine.ingest(sample(-79.9997, 15));
        engine.ingest(sample(-79.99, 200));
        break;
    }
    final acceptedMeters = engine.totalAcceptedMeters;
    final passed =
        acceptedMeters.isFinite &&
        acceptedMeters >= 0 &&
        engine.odometerIsGlobalTruth &&
        !engine.engineCanConfirmOdometer &&
        !engine.engineCanApplyCalibration &&
        (scenario.distanceClass != TripStressDistanceClass.zero ||
            acceptedMeters == 0);
    return _result(passed, {
      'distanceClass': scenario.distanceClass.name,
      'acceptedMeters': acceptedMeters,
      'odometerIsGlobalTruth': engine.odometerIsGlobalTruth,
      'engineCanConfirmOdometer': engine.engineCanConfirmOdometer,
    });
  }

  TripStressEvaluation _result(bool passed, Map<String, Object?> evidence) =>
      TripStressEvaluation(passed: passed, evidence: evidence);
}
