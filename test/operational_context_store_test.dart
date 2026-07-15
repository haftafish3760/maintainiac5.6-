import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/context/operational_context_models.dart';
import 'package:maintaniac/shared/context/operational_context_store.dart';
import 'package:maintaniac/shared/profiles/user_profile_models.dart';
import 'package:maintaniac/shared/state/app_state.dart';

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
      await controller.setWorkProfile(
        workProfileId: 'delivery-evening',
        workProfileName: 'Evening Delivery',
      );
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
      expect(reloaded.context.workProfileId, 'delivery-evening');
      expect(reloaded.context.workProfileName, 'Evening Delivery');
      expect(reloaded.context.activeVehicleId, 'truck-2');
      expect(reloaded.context.activeVehicleUsage, VehicleUsage.businessOnly);
    },
  );

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
}
