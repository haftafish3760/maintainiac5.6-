import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/dashboard/data/dashboard_firestore_mirror.dart';
import 'package:maintaniac/screens/dashboard/data/dashboard_trip_tracking_summary_reporter.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'dashboard_trip_tracking_summary_reporter_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test(
    'queues a reference-only dashboard summary from live trip state',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final mirror = DashboardFirestoreMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _RecordingSink(),
          uploadEnabled: true,
        ),
      );
      final odometer = GlobalOdometerController(initialReading: 1000);
      final tripTracking = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
      );
      addTearDown(tripTracking.dispose);
      addTearDown(odometer.dispose);
      expect(
        await tripTracking.start(
          tripId: 'dashboard_reporter_trip',
          vehicleId: odometer.vehicleId,
          profile: TripTrackingProfile.deliveryVehicle,
          startedAt: DateTime.utc(2026, 7, 17, 8),
        ),
        isTrue,
      );
      final settings = TripTrackingSettingsController.memory(
        const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          defaultProfile: TripTrackingProfile.deliveryVehicle,
          backupNetworkPolicy: TripTrackingBackupNetworkPolicy.wifiOnly,
        ),
      );
      addTearDown(settings.dispose);
      final reporter = DashboardTripTrackingSummaryReporter(
        mirror: mirror,
        settingsController: settings,
        uid: () => 'firebaseUid-1',
        dashboardId: () => 'today',
        activeVehicleId: () => odometer.vehicleId,
        activeWorkdayId: () => 'workday-1',
        activeWorkProfileId: () => 'delivery',
        tripTracking: tripTracking,
        storageReader: () async => const AppStorageCheck(
          availableBytes: AppStorageGuard.greenStorageBytes,
          operationBytes: AppStorageGuard.mileageTrackingWriteBytes,
          requiredBytes:
              AppStorageGuard.mileageTrackingWriteBytes +
              AppStorageGuard.textRecordDeviceReserveBytes,
          purpose: AppStoragePurpose.mileageTracking,
        ),
        wifiAvailable: () => true,
        mobileDataAvailable: () => false,
        syncsUsedInWindow: () => 2,
        clock: () => DateTime.utc(2026, 7, 17, 9),
      );

      final report = await reporter.queueNow();

      expect(report.queued, isTrue);
      expect(report.reasonCode, 'dashboard_summary_queued');
      expect(report.summary?.gpsAssistState, 'gps_assisted');
      expect(queue.pendingRecords, hasLength(1));
      final data = queue.pendingRecords.single.data;
      expect(data['dashboardMode'], 'gig_driver');
      expect(data['mileageMode'], 'gps_assisted');
      expect(data['syncMode'], 'wifi_only');
      expect(data['freeSyncsRemaining'], 4);
      expect(data['activeVehicleId'], odometer.vehicleId);
      expect(data['locationDataIncluded'], isFalse);
      expect(data['rawModuleDataIncluded'], isFalse);
      expect(data.keys, isNot(contains('latitude')));
      expect(data.keys, isNot(contains('route')));
    },
  );

  test('does not queue when dashboard identity is missing', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final reporter = DashboardTripTrackingSummaryReporter(
      mirror: DashboardFirestoreMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _RecordingSink(),
          uploadEnabled: true,
        ),
      ),
      settingsController: TripTrackingSettingsController.memory(),
      uid: () => ' ',
      dashboardId: () => 'today',
    );

    final report = await reporter.queueNow();

    expect(report.queued, isFalse);
    expect(report.reasonCode, 'dashboard_summary_identity_missing');
    expect(queue.pendingRecords, isEmpty);
  });

  test('storage and network reader failures fail gracefully', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final settings = TripTrackingSettingsController.memory(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        backupNetworkPolicy: TripTrackingBackupNetworkPolicy.wifiOnly,
      ),
    );
    addTearDown(settings.dispose);
    final reporter = DashboardTripTrackingSummaryReporter(
      mirror: DashboardFirestoreMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _RecordingSink(),
          uploadEnabled: true,
        ),
      ),
      settingsController: settings,
      uid: () => 'firebaseUid-1',
      dashboardId: () => 'today',
      storageReader: () => throw StateError('storage unavailable'),
      wifiAvailable: () => throw StateError('network unavailable'),
      mobileDataAvailable: () => false,
      syncsUsedInWindow: () => -1,
      clock: () => DateTime.utc(2026, 7, 17, 9),
    );

    final report = await reporter.queueNow();

    expect(report.queued, isTrue);
    expect(report.summary?.storageState, 'unknown');
    expect(report.summary?.freeSyncsRemaining, isNull);
    expect(queue.pendingRecords.single.data['storageState'], 'unknown');
    expect(
      queue.pendingRecords.single.data.keys,
      isNot(contains('freeSyncsRemaining')),
    );
  });

  test(
    'paused active workday queues a review-required dashboard summary',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final activeWorkday = ActiveWorkdayController.memory();
      await activeWorkday.startDay(
        vehicleId: 'vehicle-1',
        vehicleLabel: 'Truck',
        workProfileId: 'contractor',
        startOdometer: 1000,
        startedAt: DateTime.utc(2026, 7, 17, 8),
      );
      await activeWorkday.addEvent(
        type: ActiveWorkdayEventType.paused,
        odometerReading: 1000,
        occurredAt: DateTime.utc(2026, 7, 17, 9),
      );
      final reporter = DashboardTripTrackingSummaryReporter(
        mirror: DashboardFirestoreMirror(
          queueStore: queue,
          uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
            queue: queue,
            sink: _RecordingSink(),
            uploadEnabled: true,
          ),
        ),
        settingsController: TripTrackingSettingsController.memory(
          const TripTrackingSettings(
            gpsAssistedTrackingEnabled: true,
            defaultProfile: TripTrackingProfile.contractorVehicle,
          ),
        ),
        uid: () => 'firebaseUid-1',
        dashboardId: () => 'today',
        activeWorkdayId: () => activeWorkday.activeSession?.id,
        activeWorkProfileId: () => activeWorkday.activeSession?.workProfileId,
        activeWorkday: activeWorkday,
        clock: () => DateTime.utc(2026, 7, 17, 9, 1),
      );

      final report = await reporter.queueNow();

      expect(report.queued, isTrue);
      expect(report.summary?.reviewRequired, isTrue);
      expect(queue.pendingRecords.single.data['dashboardMode'], 'contractor');
      expect(queue.pendingRecords.single.data['reviewRequired'], isTrue);
    },
  );
}

class _RecordingSink implements MaintainiacFirestoreDocumentSink {
  final writes = <Map<String, Object?>>[];

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    writes.add(Map<String, Object?>.from(data));
  }
}
