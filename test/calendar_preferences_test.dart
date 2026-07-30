import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/app_month_calendar.dart';
import 'package:maintaniac/shared/calendar/calendar_preferences_store.dart';
import 'package:maintaniac/shared/calendar/calendar_settings_screen.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  test('Calendar defaults to the Monday through Sunday reporting week', () {
    expect(
      const CalendarPresentationPreferences().firstDayOfWeek,
      CalendarFirstDayOfWeek.monday,
    );
  });

  test(
    'Calendar preferences save through the Calendar durable record boundary',
    () async {
      final controller = CalendarPreferencesController.memory();

      await controller.update(
        firstDayOfWeek: CalendarFirstDayOfWeek.monday,
        showReviewShortcuts: false,
      );

      expect(
        controller.preferences.firstDayOfWeek,
        CalendarFirstDayOfWeek.monday,
      );
      expect(controller.preferences.showReviewShortcuts, isFalse);
    },
  );

  testWidgets('Calendar settings update the durable presentation choices', (
    tester,
  ) async {
    final controller = CalendarPreferencesController.memory();
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPreferencesScope(
          controller: controller,
          child: const CalendarSettingsScreen(),
        ),
      ),
    );

    expect(find.text('Calendar settings'), findsOneWidget);
    await tester.tap(find.text('Monday'));
    await tester.pump();
    expect(
      controller.preferences.firstDayOfWeek,
      CalendarFirstDayOfWeek.monday,
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(controller.preferences.showReviewShortcuts, isFalse);
  });

  testWidgets('shared Calendar tiles honor the saved first day of week', (
    tester,
  ) async {
    final controller = CalendarPreferencesController.memory();
    await controller.update(firstDayOfWeek: CalendarFirstDayOfWeek.monday);

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: CalendarPreferencesScope(
            controller: controller,
            child: const Scaffold(
              body: AppMonthCalendar(openCalendarDay: false),
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<TableCalendar<void>>(find.byType(TableCalendar<void>))
          .startingDayOfWeek,
      StartingDayOfWeek.monday,
    );
  });

  testWidgets('Calendar settings remain readable on a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: CalendarPreferencesScope(
            controller: CalendarPreferencesController.memory(),
            child: const CalendarSettingsScreen(),
          ),
        ),
      ),
    );

    expect(find.text('Calendar presentation'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
}
