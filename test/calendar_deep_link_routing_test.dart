import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'every currently emitted projection target has an owner detail route',
    () {
      final source = [
        'lib/shared/calendar/calendar_day_flow.dart',
        'lib/shared/calendar/calendar_active_workday_projection_route.dart',
      ].map(File.new).map((file) => file.readAsStringSync()).join('\n');
      for (final target in const [
        'expenseDetail',
        'activeWorkday',
        'vehicleProfileDetail',
        'jobDetail',
        'maintenanceDetail',
        'workTimeDetail',
        'invoiceDetail',
        'estimateDetail',
        'paymentDetail',
        'reminderDetail',
      ]) {
        expect(source, contains('CalendarDeepLinkTarget.$target'));
      }
      expect(source, contains('ExpenseReminderScreen(initialReminderId:'));
      expect(source, contains('deepLink!.sourceRecordId'));
    },
  );

  test(
    'an unsupported projection target cannot open generic calendar editing',
    () {
      final source = File(
        'lib/shared/calendar/calendar_day_flow.dart',
      ).readAsStringSync();

      final projectionGuard = source.indexOf('if (entry.projection != null)');
      final genericDetail = source.indexOf('CalendarEntryDetailScreen(');
      expect(projectionGuard, greaterThanOrEqualTo(0));
      expect(genericDetail, greaterThan(projectionGuard));
      expect(source, contains('Source record unavailable'));
      expect(source, contains('not open a duplicate editor'));
    },
  );
}
