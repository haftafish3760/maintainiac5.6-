import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/screens/expenses/profiles/expense_work_profile_screen.dart';
import 'package:maintaniac/shared/context/operational_context_store.dart';
import 'package:maintaniac/shared/profiles/user_profile_models.dart';

void main() {
  testWidgets('selecting a work profile updates the global calendar context', (
    tester,
  ) async {
    final profiles = ExpenseWorkProfileController.memory();
    final profile = await profiles.save(
      ExpenseWorkProfile(
        id: 'evening-delivery',
        name: 'Evening delivery',
        createdAt: DateTime.utc(2026, 7, 29),
        updatedAt: DateTime.utc(2026, 7, 29),
      ),
    );
    final operational = OperationalContextController.memory(
      profile: UserProfileRecord.starterContractor(),
    );
    addTearDown(profiles.dispose);
    addTearDown(operational.dispose);

    await tester.pumpWidget(
      OperationalContextScope(
        controller: operational,
        child: ExpenseWorkProfileScope(
          controller: profiles,
          child: const MaterialApp(home: ExpenseWorkProfileScreen()),
        ),
      ),
    );

    await tester.tap(find.text(profile.name).first);
    await tester.pumpAndSettle();

    expect(operational.context.workProfileId, profile.id);
    expect(operational.context.workProfileName, profile.name);
  });

  testWidgets(
    'archiving the active work profile resets global calendar context',
    (tester) async {
      final profiles = ExpenseWorkProfileController.memory();
      final profile = await profiles.save(
        ExpenseWorkProfile(
          id: 'seasonal-work',
          name: 'Seasonal work',
          createdAt: DateTime.utc(2026, 7, 29),
          updatedAt: DateTime.utc(2026, 7, 29),
        ),
      );
      await profiles.select(profile.id);
      final operational = OperationalContextController.memory(
        profile: UserProfileRecord.starterContractor(),
      );
      await operational.setActiveWorkProfile(
        workProfileId: profile.id,
        workProfileName: profile.name,
      );
      addTearDown(profiles.dispose);
      addTearDown(operational.dispose);

      await tester.pumpWidget(
        OperationalContextScope(
          controller: operational,
          child: ExpenseWorkProfileScope(
            controller: profiles,
            child: const MaterialApp(home: ExpenseWorkProfileScreen()),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(
        operational.context.workProfileId,
        ExpenseWorkProfileController.defaultProfileId,
      );
      expect(operational.context.workProfileName, 'Default work profile');
    },
  );

  testWidgets(
    'renaming an active profile refreshes its calendar context name',
    (tester) async {
      final profiles = ExpenseWorkProfileController.memory();
      final profile = await profiles.save(
        ExpenseWorkProfile(
          id: 'delivery-route',
          name: 'Delivery route',
          createdAt: DateTime.utc(2026, 7, 29),
          updatedAt: DateTime.utc(2026, 7, 29),
        ),
      );
      await profiles.select(profile.id);
      final operational = OperationalContextController.memory(
        profile: UserProfileRecord.starterContractor(),
      );
      await operational.setActiveWorkProfile(
        workProfileId: profile.id,
        workProfileName: profile.name,
      );
      addTearDown(profiles.dispose);
      addTearDown(operational.dispose);

      await tester.pumpWidget(
        OperationalContextScope(
          controller: operational,
          child: ExpenseWorkProfileScope(
            controller: profiles,
            child: const MaterialApp(home: ExpenseWorkProfileScreen()),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Late-night delivery');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(operational.context.workProfileId, profile.id);
      expect(operational.context.workProfileName, 'Late-night delivery');
    },
  );
}
