part of 'expense_settings_store.dart';

class ExpenseSettingsScope
    extends InheritedNotifier<ExpenseSettingsController> {
  const ExpenseSettingsScope({
    super.key,
    required ExpenseSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static ExpenseSettingsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExpenseSettingsScope>();
    assert(
      scope != null,
      'ExpenseSettingsScope is missing above this context.',
    );
    return scope!.notifier!;
  }

  static ExpenseSettingsController? maybeOf(BuildContext context) {
    try {
      final widget = context
          .getElementForInheritedWidgetOfExactType<ExpenseSettingsScope>()
          ?.widget;
      return widget is ExpenseSettingsScope ? widget.notifier : null;
    } on FlutterError {
      return null;
    }
  }
}
