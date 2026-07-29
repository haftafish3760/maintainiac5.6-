import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('materials entry delegates to the Work Supplies owner flow', () {
    final source = File(
      'lib/shared/calendar/calendar_owner_entry_router.dart',
    ).readAsStringSync();

    expect(source, contains('work_supply_add_items_screen.dart'));
    expect(source, contains('CalendarEntryType.materials => appNativeRoute'));
    expect(source, contains('const WorkSupplyAddItemsScreen()'));
  });

  test('trip entry remains unavailable until its owner publishes a route', () {
    final source = File(
      'lib/shared/calendar/calendar_owner_entry_router.dart',
    ).readAsStringSync();

    expect(source, contains('CalendarEntryType.tripEntry => null'));
  });

  test(
    'job scheduling opens its owning Jobs screen with Calendar day context',
    () {
      final source = File(
        'lib/shared/calendar/calendar_owner_entry_router.dart',
      ).readAsStringSync();
      final jobsScreen = File(
        'lib/screens/work_supplies/jobs/work_supply_jobs_screen.dart',
      ).readAsStringSync();

      expect(source, contains('CalendarEntryType.job ||'));
      expect(source, contains('WorkSupplyJobsScreen(initialDay: day)'));
      expect(jobsScreen, contains('this.initialDay'));
      expect(jobsScreen, contains('widget.initialDay ?? DateTime.now()'));
    },
  );
}
