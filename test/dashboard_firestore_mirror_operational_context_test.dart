import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/dashboard/data/dashboard_firestore_mirror.dart';
import 'package:maintaniac/shared/context/operational_context_models.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/profiles/user_profile_models.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'dashboard_firestore_context_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('queues operational dashboard context using Firestore-safe tokens', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final mirror = DashboardFirestoreMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: _NoopSink(),
        uploadEnabled: true,
      ),
    );

    await mirror.queueOperationalContextSummary(
      uid: 'firebaseUid-1',
      dashboardId: 'today',
      operationalContext: ActiveOperationalContext(
        userProfileId: 'user_1',
        userName: 'User',
        profileType: UserProfileType.contractor,
        role: UserRole.owner,
        permissions: permissionsForRole(UserRole.owner),
        companyMode: OperationalCompanyMode.companyOwner,
        dashboardMode: OperationalDashboardMode.fleetOwner,
        mileageMode: OperationalMileageMode.fleetReview,
        syncMode: OperationalSyncMode.companySync,
        workProfileId: 'work_1',
        workProfileName: 'Work',
        activeVehicleId: 'vehicle_1',
        activeVehicleLabel: 'Vehicle 1',
        activeVehicleUsage: VehicleUsage.businessPersonal,
        updatedAt: DateTime.utc(2026, 7, 17, 12),
        companyId: 'org_1',
      ),
      activeWorkdayId: 'workday_1',
      updatedAtUtc: DateTime.utc(2026, 7, 17, 12),
      gpsAssistState: 'on',
      storageState: 'green',
    );

    final data = queue.pendingRecords.single.data;
    expect(queue.pendingRecords.single.path, 'orgs/org_1/dashboardSummaries/today');
    expect(data['dashboardMode'], 'fleet_owner');
    expect(data['mileageMode'], 'fleet_review');
    expect(data['syncMode'], 'company_sync');
    expect(data['activeVehicleId'], 'vehicle_1');
    expect(data['activeWorkProfileId'], 'work_1');
    expect(data['locationDataIncluded'], isFalse);
    expect(data['rawModuleDataIncluded'], isFalse);
  });
}

class _NoopSink implements MaintainiacFirestoreDocumentSink {
  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {}
}
