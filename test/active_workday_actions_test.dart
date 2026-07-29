import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_actions.dart';
import 'package:maintaniac/screens/dashboard/active_workday_quick_action_editor.dart';

void main() {
  test('default quick action layout matches the active dashboard buttons', () {
    final layout = WorkdayQuickActionLayout.defaults();

    expect(layout.activeKinds, defaultWorkdayQuickActionKinds);
    expect(
      layout.activeActions.map((action) => action.kind),
      layout.activeKinds,
    );
    expect(layout.activeActions.map((action) => action.label), [
      'Pause Day',
      'End Day',
      'Fuel',
      'Add Stop',
      'Add Pickup',
      'Add Drop-Off',
      'Expense',
      'Payment',
      'Invoice',
    ]);
  });

  test('quick action layout removes duplicates and unknown saved values', () {
    final layout = WorkdayQuickActionLayout.fromMap({
      'activeKinds': [
        'addStop',
        'unknownKind',
        'addStop',
        'expense',
        'materials',
      ],
    });

    expect(layout.activeKinds, [
      WorkdayQuickActionKind.addStop,
      WorkdayQuickActionKind.expense,
      WorkdayQuickActionKind.materials,
    ]);
    expect(layout.toMap(), {
      'activeKinds': ['addStop', 'expense', 'materials'],
    });
  });

  test('quick action layout falls back when saved values are unusable', () {
    expect(
      WorkdayQuickActionLayout.fromMap(const {
        'activeKinds': ['unknownKind'],
      }).activeKinds,
      defaultWorkdayQuickActionKinds,
    );
    expect(
      WorkdayQuickActionLayout.fromMap(const {
        'activeKinds': 'addStop',
      }).activeKinds,
      defaultWorkdayQuickActionKinds,
    );
    expect(
      WorkdayQuickActionLayout.fromMap(const {'activeKinds': []}).activeKinds,
      isEmpty,
    );
  });

  test(
    'quick action layout controller normalizes updates and notifies once',
    () async {
      final controller = WorkdayQuickActionLayoutController.memory();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.update(
        WorkdayQuickActionLayout.fromMap(const {
          'activeKinds': ['addStop', 'addStop', 'expense', 'unknownKind'],
        }),
      );
      await controller.update(
        WorkdayQuickActionLayout.fromMap(const {
          'activeKinds': ['addStop', 'expense'],
        }),
      );

      expect(controller.layout.activeKinds, [
        WorkdayQuickActionKind.addStop,
        WorkdayQuickActionKind.expense,
      ]);
      expect(notifications, 1);
    },
  );

  testWidgets('quick action editor removes and adds actions through scope', (
    tester,
  ) async {
    final controller = WorkdayQuickActionLayoutController.memory(
      const WorkdayQuickActionLayout(
        activeKinds: [WorkdayQuickActionKind.addStop],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WorkdayQuickActionLayoutScope(
          controller: controller,
          child: const ActiveWorkdayQuickActionEditor(),
        ),
      ),
    );

    await tester.tap(find.text('Add Stop'));
    await tester.pump();
    expect(controller.layout.activeKinds, isEmpty);

    await tester.tap(find.text('Expense'));
    await tester.pump();
    expect(controller.layout.activeKinds, [WorkdayQuickActionKind.expense]);
  });
}
