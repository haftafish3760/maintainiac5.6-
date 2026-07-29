import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/jobs/job_schedule_exceptions_screen.dart';
import 'package:maintaniac/shared/jobs/maintainiac_job_schedule_exception.dart';
import 'package:maintaniac/shared/jobs/maintainiac_job_store.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  testWidgets('Jobs owner exposes recurring visit exception controls', (
    tester,
  ) async {
    final jobs = MaintainiacJobController.memory(initialJobs: [_job()]);
    final appState = AppStateController();
    final odometer = GlobalOdometerController();
    addTearDown(jobs.dispose);
    addTearDown(appState.dispose);
    addTearDown(odometer.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: appState,
          child: GlobalOdometerScope(
            controller: odometer,
            child: MaintainiacJobScope(
              controller: jobs,
              child: const JobScheduleExceptionsScreen(jobId: 'JOB-1'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Manage recurring visits'), findsOneWidget);
    expect(find.text('Skip visit'), findsOneWidget);
    expect(find.text('Reschedule visit'), findsOneWidget);
    expect(find.text('8/3/2026'), findsOneWidget);
    expect(find.text('Visit skipped'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

MaintainiacJobRecord _job() => MaintainiacJobRecord(
  id: 'JOB-1',
  name: 'Jones lawn care',
  scheduledStart: DateTime(2026, 7, 27, 8),
  repeatRule: 'weekly',
  scheduleExceptions: [
    MaintainiacJobScheduleException(day: DateTime(2026, 8, 3), cancelled: true),
  ],
  createdAt: DateTime(2026, 7, 1),
  updatedAt: DateTime(2026, 7, 1),
);
