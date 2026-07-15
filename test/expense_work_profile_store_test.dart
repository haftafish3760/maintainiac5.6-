import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';

void main() {
  test(
    'a default profile exists until the user creates and selects another',
    () async {
      final profiles = ExpenseWorkProfileController.memory();

      expect(
        profiles.activeWorkProfile.id,
        ExpenseWorkProfileController.defaultProfileId,
      );
      expect(profiles.activeWorkProfile.name, 'Default work profile');

      final added = await profiles.save(
        ExpenseWorkProfile(
          id: '',
          name: 'Evening delivery',
          createdAt: DateTime(2026, 7, 15),
          updatedAt: DateTime(2026, 7, 15),
        ),
      );
      await profiles.select(added.id);

      expect(profiles.activeWorkProfile.id, added.id);
      expect(profiles.profiles, hasLength(2));
    },
  );

  test('the default profile is never deletable', () async {
    final profiles = ExpenseWorkProfileController.memory();

    await expectLater(
      profiles.delete(ExpenseWorkProfileController.defaultProfileId),
      throwsStateError,
    );
  });

  test(
    'deleting a work profile archives its stable historical identity',
    () async {
      final profiles = ExpenseWorkProfileController.memory();
      final added = await profiles.save(
        ExpenseWorkProfile(
          id: 'weekend-contract',
          name: 'Weekend contract',
          createdAt: DateTime(2026, 7, 15),
          updatedAt: DateTime(2026, 7, 15),
        ),
      );

      await profiles.delete(added.id);

      expect(
        profiles.profiles.any((profile) => profile.id == added.id),
        isFalse,
      );
      expect(profiles.profileById(added.id)?.name, 'Weekend contract');
      expect(profiles.profileById(added.id)?.isArchived, isTrue);

      await profiles.restore(added.id);
      expect(
        profiles.profiles.any((profile) => profile.id == added.id),
        isTrue,
      );
    },
  );
}
