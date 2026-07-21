import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('battery safety summary survives local session recovery', () async {
    final store = TripTrackingSessionStore.memory();
    final observedAt = DateTime.utc(2026, 7, 21, 17, 14);
    await store.save(
      TripTrackingSessionRecord(
        id: 'trip_battery_recovery',
        vehicleId: 'vehicle_1',
        startingOdometer: 42000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: observedAt.subtract(const Duration(minutes: 10)),
        updatedAt: observedAt,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 1200,
          walkingReviewSuggested: false,
        ),
        batteryStateSummary: TripTrackingBatteryStateSummary(
          observedAt: observedAt,
          batteryPercent: 14,
          isCharging: false,
          lowPowerModeEnabled: true,
          allowsGps: false,
          reasonCode: 'battery_low_gps_blocked',
        ),
      ),
    );

    final recovered = store.activeSession;
    final summary = recovered!.batteryStateSummary!;
    expect(summary.observedAt, observedAt);
    expect(summary.batteryPercent, 14);
    expect(summary.isCharging, isFalse);
    expect(summary.lowPowerModeEnabled, isTrue);
    expect(summary.allowsGps, isFalse);
    expect(summary.reasonCode, 'battery_low_gps_blocked');
    expect(recovered.engineSnapshot.totalAcceptedMeters, 1200);
  });

  test('malformed battery summary is isolated without losing session', () {
    final startedAt = DateTime.utc(2026, 7, 21, 17);
    final record = TripTrackingSessionRecord.fromMap({
      'id': 'trip_malformed_battery',
      'vehicleId': 'vehicle_1',
      'startingOdometer': 42000,
      'profile': TripTrackingProfile.roadVehicle.name,
      'startedAt': startedAt.toIso8601String(),
      'updatedAt': startedAt.toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ).toMap(),
      'batteryStateSummary': {
        'observedAt': startedAt.toIso8601String(),
        'batteryPercent': 140,
        'isCharging': false,
        'lowPowerModeEnabled': false,
        'allowsGps': true,
        'reasonCode': 'invalid',
      },
    });

    expect(record.batteryStateSummary, isNull);
    expect(record.id, 'trip_malformed_battery');
    expect(record.hasValidTimeline, isTrue);
  });

  test('permission history is bounded and survives local recovery', () async {
    final store = TripTrackingSessionStore.memory();
    final startedAt = DateTime.utc(2026, 7, 21, 18);
    final history = List.generate(
      30,
      (index) => TripTrackingPermissionEvidence(
        observedAt: startedAt.add(Duration(minutes: index)),
        state: index.isEven ? 'always' : 'denied',
        preciseLocation: index.isEven,
        canTrackInBackground: index.isEven,
        source: 'native_event',
      ),
    );
    await store.save(
      TripTrackingSessionRecord(
        id: 'trip_permission_recovery',
        vehicleId: 'vehicle_1',
        startingOdometer: 43000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
        updatedAt: startedAt.add(const Duration(minutes: 30)),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 500,
          walkingReviewSuggested: false,
        ),
        permissionHistory: history,
      ),
    );

    final recovered = TripTrackingSessionRecord.fromMap(
      store.activeSession!.toMap(),
    );
    expect(recovered.permissionHistory, hasLength(24));
    expect(recovered.permissionHistory.first.observedAt, history[6].observedAt);
    expect(recovered.permissionHistory.last.state, 'denied');
    expect(recovered.engineSnapshot.totalAcceptedMeters, 500);
  });

  test('malformed permission evidence is isolated independently', () {
    final startedAt = DateTime.utc(2026, 7, 21, 18);
    final record = TripTrackingSessionRecord.fromMap({
      'id': 'trip_bad_permission',
      'vehicleId': 'vehicle_1',
      'startingOdometer': 43000,
      'profile': TripTrackingProfile.roadVehicle.name,
      'startedAt': startedAt.toIso8601String(),
      'updatedAt': startedAt.toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 55,
        walkingReviewSuggested: false,
      ).toMap(),
      'permissionHistory': [
        {
          'observedAt': startedAt.toIso8601String(),
          'state': 'always',
          'preciseLocation': true,
          'canTrackInBackground': true,
          'source': 'native_event',
        },
        {'state': 42},
      ],
    });

    expect(record.permissionHistory, hasLength(1));
    expect(record.engineSnapshot.totalAcceptedMeters, 55);
  });

  test('system pause ownership survives session serialization', () {
    final at = DateTime.utc(2026, 7, 21, 19);
    final record = TripTrackingSessionRecord.fromMap(
      TripTrackingSessionRecord(
        id: 'trip_system_pause',
        vehicleId: 'vehicle_1',
        startingOdometer: 44000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
        updatedAt: at,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 250,
          walkingReviewSuggested: false,
        ),
        lifecycleState: TripTrackingSessionLifecycleState.paused,
        pauseKind: TripTrackingPauseKind.system,
      ).toMap(),
    );

    expect(record.pauseKind, TripTrackingPauseKind.system);
    expect(
      record.effectiveContractState,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
    );
  });
}
