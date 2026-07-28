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
  const _JobFormLauncher({this.result});

  final ValueNotifier<WorkSupplyJobDraft?>? result;

  @override
  State<_JobFormLauncher> createState() => _JobFormLauncherState();
}

class _JobFormLauncherState extends State<_JobFormLauncher> {
  void _open() {
    unawaited(
      Navigator.of(context)
          .push<WorkSupplyJobDraft>(
            MaterialPageRoute(
              builder: (_) =>
                  WorkSupplyJobFormScreen(initialDay: DateTime(2026, 7, 25)),
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
