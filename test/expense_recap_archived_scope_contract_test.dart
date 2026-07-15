import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'recap scope retains archived vehicle and work-profile identities',
    () async {
      final screen = await File(
        'lib/screens/expenses/reports/expense_recap_screen.dart',
      ).readAsString();
      final panel = await File(
        'lib/screens/expenses/reports/expense_recap_scope_panel.dart',
      ).readAsString();

      expect(screen, contains('vehicles: appState.allVehicles'));
      expect(screen, contains('workProfiles: profiles.allProfiles'));
      expect(panel, contains(r"'${profile.name} · Archived'"));
      expect(panel, contains(r"'${vehicle.displayName} · Archived'"));
    },
  );
}
