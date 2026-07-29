import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/context/operational_context_models.dart';
import 'package:maintaniac/shared/context/operational_context_store.dart';
import 'package:maintaniac/shared/profiles/user_profile_models.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() {
    hiveDirectory = Directory.systemTemp.createTempSync(
      'operational_context_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  test('starts from the active contractor owner profile and vehicle', () async {
    final profile = UserProfileRecord.starterContractor();
    final controller = await OperationalContextController.create(
      profile: profile,
      activeVehicleId: 'truck-1',
      activeVehicleLabel: 'Work Truck 1',
      activeVehicleUsage: VehicleUsage.businessPersonal,
    );

    expect(
      controller.context.dashboardMode,
      OperationalDashboardMode.soloContractor,
    );
    expect(controller.context.mileageMode, OperationalMileageMode.workday);
    expect(controller.context.syncMode, OperationalSyncMode.localOnly);
    expect(controller.context.activeVehicleId, 'truck-1');
    expect(controller.can(UserPermission.recordMileage), isTrue);
    expect(controller.context.showsMileage, isTrue);
  });

  test(
    'persists dashboard, mileage, sync, and active vehicle context',
    () async {
      final controller = await OperationalContextController.create(
        profile: UserProfileRecord.starterContractor(),
        activeVehicleId: 'truck-1',
        activeVehicleLabel: 'Work Truck 1',
        activeVehicleUsage: VehicleUsage.businessPersonal,
      );

      await controller.setDashboardMode(OperationalDashboardMode.fleetOwner);
      await controller.setSyncMode(OperationalSyncMode.companySync);
      await controller.setActiveVehicle(
        vehicleId: 'truck-2',
        vehicleLabel: 'Work Truck 2',
        usage: VehicleUsage.businessOnly,
      );

      await Hive.close();
      Hive.init(hiveDirectory.path);

      final reloaded = await OperationalContextController.create(
        profile: UserProfileRecord.starterContractor(),
        activeVehicleId: 'truck-1',
        activeVehicleLabel: 'Work Truck 1',
        activeVehicleUsage: VehicleUsage.businessPersonal,
      );

      expect(
        reloaded.context.dashboardMode,
        OperationalDashboardMode.fleetOwner,
      );
      expect(reloaded.context.mileageMode, OperationalMileageMode.fleetReview);
      expect(reloaded.context.syncMode, OperationalSyncMode.companySync);
      expect(reloaded.context.activeVehicleId, 'truck-2');
      expect(reloaded.context.activeVehicleUsage, VehicleUsage.businessOnly);
    },
  );

  test('persists the active source-owned work profile context', () async {
    final controller = await OperationalContextController.create(
      profile: UserProfileRecord.starterContractor(),
      activeVehicleId: 'truck-1',
      activeVehicleLabel: 'Work Truck 1',
      activeVehicleUsage: VehicleUsage.businessPersonal,
    );

    await controller.setActiveWorkProfile(
      workProfileId: 'evening-delivery',
      workProfileName: 'Evening delivery',
    );

    await Hive.close();
    Hive.init(hiveDirectory.path);
    final reloaded = await OperationalContextController.create(
      profile: UserProfileRecord.starterContractor(),
      activeVehicleId: 'truck-1',
      activeVehicleLabel: 'Work Truck 1',
      activeVehicleUsage: VehicleUsage.businessPersonal,
    );

    expect(reloaded.context.workProfileId, 'evening-delivery');
    expect(reloaded.context.workProfileName, 'Evening delivery');
  });

  test('helper context can track mileage but cannot see financials', () {
    final helper = UserProfileRecord(
      id: 'helper-1',
      name: 'Crew Helper',
      type: UserProfileType.contractor,
      role: UserRole.helper,
      permissions: permissionsForRole(UserRole.helper),
    );

    final controller = OperationalContextController.memory(
      profile: helper,
      activeVehicleId: 'truck-7',
      activeVehicleLabel: 'Crew Truck 7',
    );

    expect(controller.context.dashboardMode, OperationalDashboardMode.employee);
    expect(
      controller.context.mileageMode,
      OperationalMileageMode.employeeShift,
    );
    expect(controller.context.can(UserPermission.recordMileage), isTrue);
    expect(controller.context.can(UserPermission.viewFinancials), isFalse);
    expect(controller.context.showsMileage, isTrue);
  });

  test('does not replace local context when storage is full', () async {
    final controller = await OperationalContextController.create(
      profile: UserProfileRecord.starterContractor(),
      activeVehicleId: 'truck-1',
      activeVehicleLabel: 'Work Truck 1',
      activeVehicleUsage: VehicleUsage.businessPersonal,
      storageCheck: _fullStorageCheck,
    );

    await expectLater(
      controller.setSyncMode(OperationalSyncMode.firebaseBackup),
      throwsA(isA<StateError>()),
    );

    expect(controller.context.syncMode, OperationalSyncMode.localOnly);
  });

  test(
    'serializes concurrent context updates without losing either update',
    () async {
      final controller = await OperationalContextController.create(
        profile: UserProfileRecord.starterContractor(),
        activeVehicleId: 'truck-1',
        activeVehicleLabel: 'Work Truck 1',
        activeVehicleUsage: VehicleUsage.businessPersonal,
        storageCheck: _availableStorageCheck,
      );

      await Future.wait([
        controller.setDashboardMode(OperationalDashboardMode.gigDriver),
        controller.setSyncMode(OperationalSyncMode.firebaseBackup),
      ]);

      expect(
        controller.context.dashboardMode,
        OperationalDashboardMode.gigDriver,
      );
      expect(controller.context.syncMode, OperationalSyncMode.firebaseBackup);
    },
  );

  test(
    'rejects unsafe dashboard context reference ids before persistence',
    () async {
      final controller = await OperationalContextController.create(
        profile: UserProfileRecord.starterContractor(),
        activeVehicleId: 'truck-1',
        activeVehicleLabel: 'Work Truck 1',
        activeVehicleUsage: VehicleUsage.businessPersonal,
        storageCheck: _availableStorageCheck,
      );

      await expectLater(
        controller.setActiveVehicle(
          vehicleId: 'truck/../other',
          vehicleLabel: 'Bad Truck',
          usage: VehicleUsage.businessOnly,
        ),
        throwsArgumentError,
      );

      expect(controller.context.activeVehicleId, 'truck-1');
    },
  );

  test(
    'unsafe restored dashboard context ids fall back to profile context',
    () async {
      final box = await Hive.openBox<dynamic>(
        OperationalContextController.boxName,
      );
      await box.put('activeContext', {
        'userProfileId': 'user_1',
        'userName': 'User',
        'profileType': 'contractor',
        'role': 'owner',
        'permissions': ['recordMileage'],
        'companyMode': 'solo',
        'dashboardMode': 'fleetOwner',
        'mileageMode': 'fleetReview',
        'syncMode': 'companySync',
        'workProfileId': 'business',
        'workProfileName': 'Business',
        'activeVehicleId': 'truck/../other',
        'activeVehicleLabel': 'Bad Truck',
        'activeVehicleUsage': 'businessOnly',
        'updatedAt': DateTime.utc(2026, 7, 17, 12).toIso8601String(),
      });

      final controller = await OperationalContextController.create(
        profile: UserProfileRecord.starterContractor(),
        activeVehicleId: 'truck-1',
        activeVehicleLabel: 'Work Truck 1',
        activeVehicleUsage: VehicleUsage.businessPersonal,
      );

      expect(controller.context.activeVehicleId, 'truck-1');
      expect(
        controller.context.dashboardMode,
        OperationalDashboardMode.soloContractor,
      );
    },
  );
}

Future<AppStorageCheck> _fullStorageCheck() async => const AppStorageCheck(
  availableBytes: 0,
  operationBytes: AppStorageGuard.smallRecordWriteBytes,
  requiredBytes:
      AppStorageGuard.minimumDeviceReserveBytes +
      AppStorageGuard.smallRecordWriteBytes,
  purpose: AppStoragePurpose.smallRecordWrite,
);

Future<AppStorageCheck> _availableStorageCheck() async => const AppStorageCheck(
  availableBytes: 1024 * 1024 * 1024,
  operationBytes: AppStorageGuard.smallRecordWriteBytes,
  requiredBytes:
      AppStorageGuard.minimumDeviceReserveBytes +
      AppStorageGuard.smallRecordWriteBytes,
  purpose: AppStoragePurpose.smallRecordWrite,
);
