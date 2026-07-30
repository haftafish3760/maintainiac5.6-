// Calendar ownership: durable presentation preferences for Calendar only.
// Source records, notification delivery, and source-specific settings stay owned elsewhere.

import 'package:flutter/widgets.dart';

import '../durable_storage/maintainiac_durable_storage.dart';

enum CalendarFirstDayOfWeek { sunday, monday }

class CalendarPresentationPreferences {
  const CalendarPresentationPreferences({
    this.firstDayOfWeek = CalendarFirstDayOfWeek.monday,
    this.showReviewShortcuts = true,
  });

  final CalendarFirstDayOfWeek firstDayOfWeek;
  final bool showReviewShortcuts;

  CalendarPresentationPreferences copyWith({
    CalendarFirstDayOfWeek? firstDayOfWeek,
    bool? showReviewShortcuts,
  }) => CalendarPresentationPreferences(
    firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
    showReviewShortcuts: showReviewShortcuts ?? this.showReviewShortcuts,
  );

  factory CalendarPresentationPreferences.fromMap(Map<dynamic, dynamic> map) =>
      CalendarPresentationPreferences(
        firstDayOfWeek: switch ('${map['firstDayOfWeek'] ?? ''}') {
          'sunday' => CalendarFirstDayOfWeek.sunday,
          _ => CalendarFirstDayOfWeek.monday,
        },
        showReviewShortcuts: map['showReviewShortcuts'] != false,
      );

  Map<String, Object?> toMap() => {
    'firstDayOfWeek': firstDayOfWeek.name,
    'showReviewShortcuts': showReviewShortcuts,
  };
}

class CalendarPreferencesController extends ChangeNotifier {
  CalendarPreferencesController._(this._records);

  static const _module = 'calendar_preferences';
  static const _recordId = 'presentation';
  final MaintainiacDurableRecordStore _records;

  static Future<CalendarPreferencesController> create() async =>
      CalendarPreferencesController._(
        await MaintainiacDurableRecordStore.create('calendar_preferences'),
      );

  CalendarPreferencesController.memory()
    : _records = MaintainiacDurableRecordStore.memory();

  CalendarPresentationPreferences get preferences {
    for (final record in _records.recordsFor(_module)) {
      if (record.id == _recordId) {
        return CalendarPresentationPreferences.fromMap(record.payload);
      }
    }
    return const CalendarPresentationPreferences();
  }

  Future<void> save(CalendarPresentationPreferences value) async {
    await _records.save(module: _module, id: _recordId, payload: value.toMap());
    notifyListeners();
  }

  Future<void> update({
    CalendarFirstDayOfWeek? firstDayOfWeek,
    bool? showReviewShortcuts,
  }) => save(
    preferences.copyWith(
      firstDayOfWeek: firstDayOfWeek,
      showReviewShortcuts: showReviewShortcuts,
    ),
  );
}

class CalendarPreferencesScope
    extends InheritedNotifier<CalendarPreferencesController> {
  const CalendarPreferencesScope({
    super.key,
    required CalendarPreferencesController controller,
    required super.child,
  }) : super(notifier: controller);

  static CalendarPreferencesController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<CalendarPreferencesScope>()
      ?.notifier;
}
