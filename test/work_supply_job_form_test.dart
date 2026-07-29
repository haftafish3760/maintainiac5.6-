import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/jobs/work_supply_job_form_models.dart';
import 'package:maintaniac/screens/work_supplies/jobs/work_supply_job_form_screen.dart';

void main() {
  testWidgets('Create Job closes cleanly from Cancel and Android back', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _JobFormLauncher()));

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    expect(find.text('Create Job'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Cancel'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Open form'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Open form'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dirty Android back asks before discarding the job', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _JobFormLauncher()));
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Job name *'),
      'Replace service panel',
    );
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Discard this job?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Open form'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('job form returns client, schedule, and reminder preferences', (
    tester,
  ) async {
    final result = ValueNotifier<WorkSupplyJobDraft?>(null);
    addTearDown(result.dispose);
    await tester.pumpWidget(
      MaterialApp(home: _JobFormLauncher(result: result)),
    );
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Job name *'),
      'HVAC service call',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Client name'),
      'Jordan Smith',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Service address'),
      '12 Main Street',
    );
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.text('In-app reminder'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('In-app reminder'));
    await tester.scrollUntilVisible(
      find.text('Save Job'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Job'));
    await tester.pumpAndSettle();

    expect(result.value?.name, 'HVAC service call');
    expect(result.value?.clientName, 'Jordan Smith');
    expect(result.value?.serviceAddress, '12 Main Street');
    expect(result.value?.scheduledStart, isNotNull);
    expect(result.value?.inAppReminder, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('job form saves a bounded selected-weekday schedule', (
    tester,
  ) async {
    final result = ValueNotifier<WorkSupplyJobDraft?>(null);
    addTearDown(result.dispose);
    await tester.pumpWidget(
      MaterialApp(home: _JobFormLauncher(result: result)),
    );
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Job name *'),
      'Tuesday and Thursday route',
    );
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<JobRepeatRule>),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    final repeatControl = find.byType(DropdownButtonFormField<JobRepeatRule>);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -280));
    await tester.pumpAndSettle();
    await tester.tap(repeatControl);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selected weekdays').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tue'));
    await tester.tap(find.text('Thu'));
    await tester.scrollUntilVisible(
      find.text('Save Job'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Job'));
    await tester.pumpAndSettle();

    expect(result.value?.repeatRule, JobRepeatRule.selectedWeekdays);
    expect(result.value?.repeatWeekdays, [DateTime.tuesday, DateTime.thursday]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('job form saves an audible-only reminder preference', (
    tester,
  ) async {
    final result = ValueNotifier<WorkSupplyJobDraft?>(null);
    addTearDown(result.dispose);
    await tester.pumpWidget(
      MaterialApp(home: _JobFormLauncher(result: result)),
    );
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Job name *'),
      'Audible route reminder',
    );
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.text('Audible reminder'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Audible reminder'));
    await tester.scrollUntilVisible(
      find.text('Save Job'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Job'));
    await tester.pumpAndSettle();

    expect(result.value?.soundReminder, isTrue);
    expect(result.value?.pushReminder, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('job form saves an explicit overnight schedule', (tester) async {
    final result = ValueNotifier<WorkSupplyJobDraft?>(null);
    addTearDown(result.dispose);
    await tester.pumpWidget(
      MaterialApp(home: _JobFormLauncher(result: result)),
    );
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Job name *'),
      'Overnight emergency repair',
    );
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.text('Ends the next day'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ends the next day'));
    await tester.scrollUntilVisible(
      find.text('Save Job'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Job'));
    await tester.pumpAndSettle();

    expect(
      result.value?.scheduledEnd,
      result.value?.scheduledStart?.add(const Duration(hours: 25)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('job form hydrates a source-owned schedule for editing', (
    tester,
  ) async {
    final result = ValueNotifier<WorkSupplyJobDraft?>(null);
    addTearDown(result.dispose);
    final initial = WorkSupplyJobDraft(
      name: 'Existing route',
      clientName: 'Jones',
      clientPhone: '',
      clientEmail: '',
      serviceAddress: '1 Main Street',
      notes: '',
      scheduledStart: DateTime(2026, 7, 27, 8),
      scheduledEnd: DateTime(2026, 7, 27, 10),
      scheduleEnabled: true,
      repeatRule: JobRepeatRule.selectedWeekdays,
      repeatWeekdays: const [DateTime.monday, DateTime.wednesday],
      repeatUntil: DateTime(2026, 8, 31),
      inAppReminder: true,
      pushReminder: false,
      soundReminder: false,
      reminderLeadMinutes: 30,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: _JobFormLauncher(result: result, initialDraft: initial),
      ),
    );
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Job'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Job name *'),
          )
          .controller
          ?.text,
      'Existing route',
    );
    await tester.scrollUntilVisible(
      find.text('Save Job'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Job'));
    await tester.pumpAndSettle();

    expect(result.value?.repeatWeekdays, [DateTime.monday, DateTime.wednesday]);
    expect(result.value?.repeatUntil, DateTime(2026, 8, 31));
    expect(result.value?.reminderLeadMinutes, 30);
  });

  testWidgets('editing preserves an existing overnight schedule', (
    tester,
  ) async {
    final result = ValueNotifier<WorkSupplyJobDraft?>(null);
    addTearDown(result.dispose);
    final initial = WorkSupplyJobDraft(
      name: 'After-hours route',
      clientName: '',
      clientPhone: '',
      clientEmail: '',
      serviceAddress: '',
      notes: '',
      scheduledStart: DateTime(2026, 7, 27, 22),
      scheduledEnd: DateTime(2026, 7, 28, 2),
      scheduleEnabled: true,
      repeatRule: JobRepeatRule.weekly,
      repeatWeekdays: const [],
      repeatUntil: null,
      inAppReminder: false,
      pushReminder: false,
      soundReminder: false,
      reminderLeadMinutes: 60,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: _JobFormLauncher(result: result, initialDraft: initial),
      ),
    );
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Ends the next day'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    final overnightToggle = find.ancestor(
      of: find.text('Ends the next day'),
      matching: find.byType(SwitchListTile),
    );
    expect(tester.widget<SwitchListTile>(overnightToggle).value, isTrue);
    await tester.scrollUntilVisible(
      find.text('Save Job'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Job'));
    await tester.pumpAndSettle();

    expect(result.value?.scheduledStart, DateTime(2026, 7, 27, 22));
    expect(result.value?.scheduledEnd, DateTime(2026, 7, 28, 2));
  });

  test('Jobs source files stay within the 500-line rule', () {
    final files = <File>[
      ...Directory('lib/screens/work_supplies/jobs')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      File('lib/shared/jobs/maintainiac_job_store.dart'),
    ];

    for (final file in files) {
      final lines = file.readAsLinesSync().length;
      expect(
        lines,
        lessThanOrEqualTo(500),
        reason: '${file.path} has $lines lines.',
      );
    }
  });
}

class _JobFormLauncher extends StatefulWidget {
  const _JobFormLauncher({this.result, this.initialDraft});

  final ValueNotifier<WorkSupplyJobDraft?>? result;
  final WorkSupplyJobDraft? initialDraft;

  @override
  State<_JobFormLauncher> createState() => _JobFormLauncherState();
}

class _JobFormLauncherState extends State<_JobFormLauncher> {
  void _open() {
    unawaited(
      Navigator.of(context)
          .push<WorkSupplyJobDraft>(
            MaterialPageRoute(
              builder: (_) => WorkSupplyJobFormScreen(
                initialDay: DateTime(2026, 7, 25),
                initialDraft: widget.initialDraft,
              ),
            ),
          )
          .then((value) => widget.result?.value = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(onPressed: _open, child: const Text('Open form')),
      ),
    );
  }
}
