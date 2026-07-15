import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_vehicle_profile_store.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  test(
    'vehicle profiles persist stable IDs and archive without deleting history',
    () async {
      final profiles = ExpenseVehicleProfileController.memory();
      final createdAt = DateTime.utc(2026, 7, 15);
      final saved = await profiles.save(
        ExpenseVehicleProfileRecord(
          id: 'truck-1',
          nickname: 'Work Truck',
          year: '2021',
          make: 'Ford',
          model: 'Transit',
          usage: VehicleUsage.businessOnly,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      expect(saved.displayName, 'Work Truck — 2021 Ford Transit');
      expect(profiles.profileById('truck-1')?.usage, VehicleUsage.businessOnly);
      await profiles.archive('truck-1');
      expect(profiles.activeProfiles, isEmpty);
      expect(profiles.profiles.single.archived, isTrue);
      final backup = profiles.toBackupMap(
        ownerUid: 'USER-1',
        exportedAtUtc: DateTime.utc(2026, 7, 15, 1),
      );
      expect(backup['schema'], 'expense_vehicle_profiles_v1');
      expect(
        (backup['profiles'] as List).single.toString(),
        contains('truck-1'),
      );
    },
  );
}
