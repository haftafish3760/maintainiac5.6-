import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_recap_period_contract.dart';
import 'package:maintaniac/shared/calendar/calendar_recap_reporting_window.dart';

void main() {
  final anchor = DateTime(2026, 7, 29, 23, 59);

  test('default current week is Monday through Sunday', () {
    final range = CalendarRecapPeriod.currentWeek.rangeFor(anchor);

    expect(range.start, DateTime(2026, 7, 27));
    expect(range.end, DateTime(2026, 8, 2));
    expect(range.inclusiveDayCount, 7);
  });

  test('custom week start changes the payroll reporting window', () {
    final range = CalendarRecapPeriod.currentWeek.rangeFor(
      anchor,
      weekStart: CalendarWeekStart.sunday,
    );

    expect(range.start, DateTime(2026, 7, 26));
    expect(range.end, DateTime(2026, 8, 1));
  });

  test('historical windows exclude the anchor day without an overlap', () {
    final seven = CalendarRecapPeriod.previousSevenDays.rangeFor(anchor);
    final thirty = CalendarRecapPeriod.previousThirtyDays.rangeFor(anchor);
    final ninety = CalendarRecapPeriod.previousNinetyDays.rangeFor(anchor);

    expect(seven.start, DateTime(2026, 7, 22));
    expect(seven.end, DateTime(2026, 7, 28));
    expect(thirty.inclusiveDayCount, 30);
    expect(ninety.inclusiveDayCount, 90);
    expect(seven.contains(anchor), isFalse);
    expect(seven.contains(DateTime(2026, 7, 28, 23, 59)), isTrue);
  });

  test('month, year-to-date, and lifetime preserve local date boundaries', () {
    final month = CalendarRecapPeriod.currentMonth.rangeFor(anchor);
    final ytd = CalendarRecapPeriod.yearToDate.rangeFor(anchor);
    final lifetime = CalendarRecapPeriod.lifetime.rangeFor(anchor);

    expect(month.start, DateTime(2026, 7));
    expect(month.end, DateTime(2026, 7, 31));
    expect(ytd.start, DateTime(2026));
    expect(ytd.end, DateTime(2026, 7, 29));
    expect(lifetime.start, isNull);
    expect(lifetime.contains(DateTime(1999, 12, 31, 23, 59)), isTrue);
  });

  test('current reporting windows never include future completed activity', () {
    final today = DateTime(2026, 7, 29, 12);
    final currentWeek = CalendarRecapPeriod.currentWeek.rangeFor(today);
    final currentMonth = CalendarRecapPeriod.currentMonth.rangeFor(today);

    final weekThroughToday = calendarRecapRangeThroughToday(
      currentWeek,
      now: today,
    );
    final monthThroughToday = calendarRecapRangeThroughToday(
      currentMonth,
      now: today,
    );

    expect(weekThroughToday.end, DateTime(2026, 7, 29));
    expect(monthThroughToday.end, DateTime(2026, 7, 29));
  });

  test('rolling recap windows keep local calendar boundaries across DST', () {
    final range = CalendarRecapPeriod.previousSevenDays.rangeFor(
      DateTime(2026, 3, 9),
    );
    final currentWeek = CalendarRecapPeriod.currentWeek.rangeFor(
      DateTime(2026, 3, 9),
    );

    expect(range.start, DateTime(2026, 3, 2));
    expect(range.end, DateTime(2026, 3, 8));
    expect(currentWeek.start, DateTime(2026, 3, 9));
    expect(currentWeek.end, DateTime(2026, 3, 15));
  });

  test(
    'historical full periods remain complete instead of being shortened',
    () {
      final historical = CalendarRecapPeriod.currentWeek.rangeFor(
        DateTime(2026, 7, 8),
      );

      final result = calendarRecapRangeThroughToday(
        historical,
        now: DateTime(2026, 7, 29),
      );

      expect(result.start, DateTime(2026, 7, 6));
      expect(result.end, DateTime(2026, 7, 12));
    },
  );
}
