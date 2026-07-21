import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_durable_record_bridge.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'one durable trip record contains reviewed stops events and adjustments',
    () async {
      final startedAt = DateTime.utc(2026, 7, 21, 12);
      final finishedAt = startedAt.add(const Duration(hours: 1));
      final review = TripTrackingReviewRecord(
        id: 'bundled_trip',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        estimatedEndingOdometer: 1010,
        confirmedEndingOdometer: 1011,
        odometerConfirmedAt: finishedAt,
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: startedAt,
        finishedAt: finishedAt,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 16000,
          walkingReviewSuggested: false,
        ),
        advisories: [
          TripTrackingAdvisoryEvent(
            id: 'stop_1',
            type: TripTrackingAdvisoryType.probableStop,
            sessionId: 'bundled_trip',
            vehicleId: 'vehicle_1',
            profile: TripTrackingProfile.deliveryVehicle,
            detectedAt: startedAt.add(const Duration(minutes: 20)),
            evidenceStartedAt: startedAt.add(const Duration(minutes: 18)),
            evidenceEndedAt: startedAt.add(const Duration(minutes: 20)),
            confidence: TripTrackingConfidence.high,
            suggestedAction: 'review_stop',
          ),
        ],
        tripEvents: [
          TripManualEvent(
            id: 'pickup_1',
            type: TripManualEventType.pickup,
            occurredAt: startedAt.add(const Duration(minutes: 25)),
            userConfirmed: true,
          ),
        ],
        manualAdjustments: [
          TripManualMileageAdjustment(
            id: 'adjustment_1',
            deltaMiles: 1,
            reason: TripManualMileageAdjustmentReason.gpsGap,
            createdAt: finishedAt,
            userConfirmed: true,
          ),
        ],
        transitionAudits: [
          TripTrackingSessionTransitionAudit(
            id: 'bundled_trip:2',
            sessionId: 'bundled_trip',
            vehicleId: 'vehicle_1',
            profile: TripTrackingProfile.deliveryVehicle,
            profileId: 'deliveryVehicle',
            fromState: TripTrackingSessionLifecycleState.ready,
            toState: TripTrackingSessionLifecycleState.starting,
            eventTimestamp: startedAt.add(const Duration(seconds: 1)),
            sequenceNumber: 2,
            reasonCode: 'gps_session_transition_allowed',
            initiatingSource: 'controller',
            revision: 2,
            permissionState: 'permission_granted',
            confidenceState: 'healthy',
            trackingQualityMode: 'high_quality',
          ),
        ],
        batteryStateSummary: TripTrackingBatteryStateSummary(
          observedAt: finishedAt,
          batteryPercent: 42,
          isCharging: false,
          lowPowerModeEnabled: false,
          allowsGps: true,
          reasonCode: 'battery_ok',
        ),
        permissionHistory: [
          TripTrackingPermissionEvidence(
            observedAt: startedAt,
            state: 'always',
            preciseLocation: true,
            canTrackInBackground: true,
            source: 'native_start',
          ),
        ],
        recoveryCount: 3,
      );
      final store = MaintainiacDurableRecordStore.memory();
      final saved = await TripTrackingDurableRecordBridge(
        store,
      ).saveReviewedTrip(review, now: finishedAt);

      expect(
        store.recordsFor(TripTrackingDurableRecordBridge.module),
        hasLength(1),
      );
      expect(saved.payload['advisories'], hasLength(1));
      expect(saved.payload['tripEvents'], hasLength(1));
      expect(saved.payload['manualAdjustments'], hasLength(1));
      expect(saved.payload['transitionAudits'], hasLength(1));
      expect(saved.payload['batteryStateSummary'], isA<Map>());
      expect(saved.payload['permissionHistory'], hasLength(1));
      expect(saved.payload['recoveryCount'], 3);
      expect(saved.payload['routeHistoryPersistedInDurableRecord'], isFalse);
      expect(saved.payload.toString(), isNot(contains('latitude')));
      expect(saved.payload.toString(), isNot(contains('longitude')));
    },
  );
}
