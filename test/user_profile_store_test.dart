import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/profiles/user_profile_models.dart';
import 'package:maintaniac/shared/profiles/user_profile_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() {
    hiveDirectory = Directory.systemTemp.createTempSync('profiles_test_');
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  test('starts as a local-first contractor owner profile', () async {
    final controller = await UserProfileController.create();
    final profile = controller.activeProfile;

    expect(profile.type, UserProfileType.contractor);
    expect(profile.role, UserRole.owner);
    expect(profile.cloudBackupEnabled, isFalse);
    expect(controller.can(UserPermission.createInvoices), isTrue);
    expect(controller.can(UserPermission.manageProfiles), isTrue);
  });

  test('profile mode changes persist locally', () async {
    final controller = await UserProfileController.create();

    await controller.setProfileType(UserProfileType.driver);
    expect(controller.activeProfile.type, UserProfileType.driver);
    await Hive.close();

    Hive.init(hiveDirectory.path);
    final reloaded = await UserProfileController.create();
    expect(reloaded.activeProfile.type, UserProfileType.driver);
    expect(reloaded.activeProfile.customerFacingEnabled, isFalse);
  });

  test('primary vehicle assignment persists locally', () async {
    final controller = await UserProfileController.create();

    await controller.setPrimaryVehicleId('truck-1');
    expect(controller.activeProfile.primaryVehicleId, 'truck-1');
    await Hive.close();

    Hive.init(hiveDirectory.path);
    final reloaded = await UserProfileController.create();
    expect(reloaded.activeProfile.primaryVehicleId, 'truck-1');
  });

  test('helper role does not inherit owner-only financial access', () {
    final helper = UserProfileRecord(
      id: 'helper',
      name: 'Helper',
      type: UserProfileType.contractor,
      role: UserRole.helper,
      permissions: permissionsForRole(UserRole.helper),
    );

    expect(helper.can(UserPermission.recordMileage), isTrue);
    expect(helper.can(UserPermission.viewFinancials), isFalse);
    expect(helper.can(UserPermission.approveInvoices), isFalse);
  });
}
