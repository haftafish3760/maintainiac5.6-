// Dashboard-root routing regression coverage.
//
// Owns the contract that an active workday uses the primary active-day screen.
// Does not create, end, or mutate a workday. Consumed by dashboard QA.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard root selects ActiveWorkdayScreen when a session exists', () {
    final source = File(
      'lib/screens/dashboard/dashboard.dart',
    ).readAsStringSync();

    final activeSession = source.indexOf(
      'final activeSession = ActiveWorkdayScope.maybeOf(context)?.activeSession;',
    );
    final preDay = source.indexOf(
      'if (activeSession == null) {\n      return const AppScreenShell(body: _PreDayDashboardBody());',
    );
    final activeDay = source.indexOf('return ActiveWorkdayScreen(', preDay);

    expect(activeSession, greaterThanOrEqualTo(0));
    expect(preDay, greaterThan(activeSession));
    expect(activeDay, greaterThan(preDay));
  });

  test('active-day root does not re-request Start Day GPS startup', () {
    final source = File(
      'lib/screens/dashboard/dashboard.dart',
    ).readAsStringSync();
    final activeDay = source.indexOf('return ActiveWorkdayScreen(');
    final closing = source.indexOf('\n    );', activeDay);

    expect(activeDay, greaterThanOrEqualTo(0));
    expect(
      source.substring(activeDay, closing),
      isNot(contains('startGpsWhenOpened')),
    );
  });
}
