import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'corrupt newest snapshot restores prior committed revision once',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'trip_snapshot_recovery_',
      );
      Hive.init(directory.path);
      final store = await TripTrackingSessionStore.create();
      addTearDown(() async {
        await Hive.close();
        if (directory.existsSync()) await directory.delete(recursive: true);
      });
      final started = DateTime.utc(2026, 7, 20, 12);
      final claim = await store.claimActive(
        TripTrackingSessionRecord(
          id: 'trip_snapshot_fallback',
          vehicleId: 'vehicle_1',
          profileId: 'profile_1',
          startingOdometer: 1000,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: started,
          updatedAt: started,
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 0,
            walkingReviewSuggested: false,
          ),
        ),
      );
      var current = claim.session!;
      current = await store.checkpoint(
        current.copyWith(
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 100,
            walkingReviewSuggested: false,
          ),
        ),
        expectedRevision: current.revision,
      );
      current = await store.checkpoint(
        current.copyWith(
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 200,
            walkingReviewSuggested: false,
          ),
        ),
        expectedRevision: current.revision,
      );
      expect(current.engineSnapshot.totalAcceptedMeters, 200);

      final box = Hive.box<dynamic>(TripTrackingSessionStore.boxName);
      final head = box.get('activeSnapshot:head') as int;
      final newestKey = head.isOdd ? 'activeSnapshot:a' : 'activeSnapshot:b';
      final corrupt = Map<String, Object?>.from(box.get(newestKey) as Map);
      corrupt['checksum'] = 'corrupt';
      await box.put(newestKey, corrupt);
      await box.put('activeSession', {'corrupt': true});

      final firstRecovery = await store.recoverActive();
      final secondRecovery = await store.recoverActive();

      expect(firstRecovery.usedFallback, isTrue);
      expect(firstRecovery.session?.engineSnapshot.totalAcceptedMeters, 100);
      expect(secondRecovery.session?.revision, firstRecovery.session?.revision);
      expect(store.recoveryDiagnostics, hasLength(1));
      expect(
        store.recoveryDiagnostics.single.code,
        'corrupt_latest_snapshot_fallback',
      );
    },
  );
}
