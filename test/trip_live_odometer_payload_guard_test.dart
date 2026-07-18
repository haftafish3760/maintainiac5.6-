import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/live_odometer_display.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_odometer_payload_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_odometer_ui_validation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_live_odometer_broadcast.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  test('live broadcast embeds a passing display-only payload guard', () {
    final broadcast = TripTrackingLiveOdometerBroadcast.fromSnapshot(
      LiveOdometerDisplaySnapshot(
        confirmedReading: 1000,
        displayReading: 1002,
        isLive: true,
        liveUpdatedAt: now,
        projectionRevision: 2,
      ),
      now: now,
      activeTripId: 'trip_live',
      expectedTripId: 'trip_live',
    );
    final safe = broadcast.toSafeDashboardMap();
    final guard = safe['payloadGuard'] as Map<String, Object?>;
    final validation = TripLiveOdometerUiValidation.fromBroadcastMap(safe);

    expect(
      broadcast.status,
      TripTrackingLiveOdometerBroadcastStatus.renderable,
    );
    expect(guard['status'], TripLiveOdometerPayloadGuardStatus.passed.name);
    expect(guard['canRenderAdvisoryLiveOdometer'], isTrue);
    expect(guard['liveUiMayRefresh'], isTrue);
    expect(guard['liveUiMayCommitMileage'], isFalse);
    expect(guard['manualConfirmationRequiredBeforeOfficialMileage'], isTrue);
    expect(guard['hiveRemainsSourceOfTruth'], isTrue);
    expect(guard['firestoreMirrorOnly'], isTrue);
    expect(guard['remotePayloadCanConfirmOdometer'], isFalse);
    expect(guard['mapboxCanRenderWithoutLocalTrip'], isFalse);
    expect(validation.isRenderable, isTrue);
  });

  test('guard matrix blocks authority, malformed, and sensitive payloads', () {
    final clean = TripTrackingLiveOdometerBroadcast.fromSnapshot(
      LiveOdometerDisplaySnapshot(
        confirmedReading: 1000,
        displayReading: 1002,
        isLive: true,
        liveUpdatedAt: now,
        projectionRevision: 2,
      ),
      now: now,
      activeTripId: 'trip_live',
      expectedTripId: 'trip_live',
    ).toSafeDashboardMap();
    final cases = <_GuardCase>[
      _GuardCase(
        name: 'odometer authority',
        payload: {...clean, 'writesConfirmedOdometer': true},
        status: TripLiveOdometerPayloadGuardStatus.blockedOdometerAuthority,
        reason: 'payload_claims_odometer_authority',
      ),
      _GuardCase(
        name: 'remote authority',
        payload: {...clean, 'remoteDisplayCanOverrideLocalTrip': true},
        status: TripLiveOdometerPayloadGuardStatus.blockedRemoteAuthority,
        reason: 'payload_claims_remote_display_authority',
      ),
      _GuardCase(
        name: 'malformed advisory contract',
        payload: {...clean, 'advisoryOnly': false},
        status: TripLiveOdometerPayloadGuardStatus.blockedMalformedPayload,
        reason: 'missing_advisory_display_contract',
      ),
      _GuardCase(
        name: 'sensitive payload',
        payload: {
          ...clean,
          'debug': '35.123456,-80.123456',
          'tokenEcho': 'pk.redacted',
        },
        status: TripLiveOdometerPayloadGuardStatus.blockedSensitivePayload,
        reason: 'payload_contains_sensitive_trip_material',
      ),
    ];

    for (final entry in cases) {
      final guard = TripLiveOdometerPayloadGuard.evaluate(entry.payload);
      expect(guard.status, entry.status, reason: entry.name);
      expect(guard.reasonCodes, contains(entry.reason), reason: entry.name);
      expect(guard.canRenderAdvisoryLiveOdometer, isFalse, reason: entry.name);
      expect(guard.toSafeDashboardMap().toString(), isNot(contains('35.')));
      expect(guard.toSafeDashboardMap().toString(), isNot(contains('pk.')));
    }
  });

  test('UI validation rejects forged guard claims on unsafe payloads', () {
    final payload =
        TripTrackingLiveOdometerBroadcast.fromSnapshot(
          LiveOdometerDisplaySnapshot(
            confirmedReading: 1000,
            displayReading: 1002,
            isLive: true,
            liveUpdatedAt: now,
            projectionRevision: 2,
          ),
          now: now,
          activeTripId: 'trip_live',
          expectedTripId: 'trip_live',
        ).toSafeDashboardMap()..addAll({
          'writesConfirmedOdometer': true,
          'payloadGuard': const TripLiveOdometerPayloadGuardDecision(
            status: TripLiveOdometerPayloadGuardStatus.passed,
            reasonCodes: ['live_odometer_payload_guard_passed'],
          ).toSafeDashboardMap(),
        });

    final validation = TripLiveOdometerUiValidation.fromBroadcastMap(payload);

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('payload_can_replace_odometer'));
    expect(
      validation.reasons,
      contains('payload_guard_rejected_live_odometer'),
    );
  });
}

class _GuardCase {
  const _GuardCase({
    required this.name,
    required this.payload,
    required this.status,
    required this.reason,
  });

  final String name;
  final Map<String, Object?> payload;
  final TripLiveOdometerPayloadGuardStatus status;
  final String reason;
}
