import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_actions.dart';

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
      'Add Fuel',
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
}
