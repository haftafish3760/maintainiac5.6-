import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('work-profile settings retain a visible restore path', () {
    final source = File(
      'lib/screens/expenses/profiles/expense_work_profile_screen.dart',
    ).readAsStringSync();

    expect(source, contains('final archivedProfiles = profiles.allProfiles'));
    expect(source, contains("'Archived profiles'"));
    expect(source, contains('_ArchivedProfileTile('));
    expect(source, contains("child: const Text('Restore')"));
    expect(
      source,
      contains('ExpenseWorkProfileScope.of(context).restore(profile.id)'),
    );
    expect(source, contains('Existing expenses keep this profile'));
  });
}
