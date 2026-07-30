// Calendar ownership: durable appointments and reminders that do not belong to
// another source module. Source records remain source-owned and are projected.

import 'package:flutter/widgets.dart';

import '../durable_storage/maintainiac_durable_storage.dart';
import '../scheduling/schedule_recurrence_contract.dart';

class CalendarScheduleRecord {
  const CalendarScheduleRecord({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.recordedAt,
    required this.rule,
    this.endsAt,
    this.details = '',
    this.vehicleId = '',
    this.workProfileId = '',
    this.timezoneId,
    this.active = true,
    this.exceptions = const [],
  });

  final String id;
  final String title;
  final String details;
  final DateTime startsAt;
  final DateTime? endsAt;
  final DateTime recordedAt;
  final CalendarScheduleRule rule;
  final List<CalendarScheduleException> exceptions;
  final String vehicleId;
  final String workProfileId;
  final String? timezoneId;
  final bool active;

  factory CalendarScheduleRecord.fromMap(Map<dynamic, dynamic> map) {
    final start = DateTime.parse('${map['startsAt']}').toLocal();
    return CalendarScheduleRecord(
      id: '${map['id'] ?? ''}',
      title: '${map['title'] ?? ''}',
      details: '${map['details'] ?? ''}',
      startsAt: start,
      endsAt: _date(map['endsAt']),
      recordedAt: _date(map['recordedAt']) ?? start,
      vehicleId: '${map['vehicleId'] ?? ''}',
      workProfileId: '${map['workProfileId'] ?? ''}',
      timezoneId: _blankToNull('${map['timezoneId'] ?? ''}'),
      active: map['active'] != false,
      rule: CalendarScheduleRule(
        frequency: CalendarScheduleFrequency.values.byName(
          '${map['frequency'] ?? 'once'}',
        ),
        interval: (map['interval'] as num?)?.toInt() ?? 1,
        until: _date(map['until']),
        weekdays: (map['weekdays'] as List? ?? const [])
            .whereType<num>()
            .map((value) => value.toInt())
            .toSet(),
      ),
      exceptions: (map['exceptions'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) => CalendarScheduleException(
              day: DateTime.parse('${value['day']}').toLocal(),
              cancelled: value['cancelled'] == true,
              startOverride: _date(value['startOverride']),
              endOverride: _date(value['endOverride']),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'details': details,
    'startsAt': startsAt.toUtc().toIso8601String(),
    'endsAt': endsAt?.toUtc().toIso8601String(),
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'frequency': rule.frequency.name,
    'interval': rule.interval,
    'until': rule.until?.toUtc().toIso8601String(),
    'weekdays': rule.weekdays.toList()..sort(),
    'exceptions': [
      for (final exception in exceptions)
        {
          'day': exception.day.toUtc().toIso8601String(),
          'cancelled': exception.cancelled,
          'startOverride': exception.startOverride?.toUtc().toIso8601String(),
          'endOverride': exception.endOverride?.toUtc().toIso8601String(),
        },
    ],
    'vehicleId': vehicleId,
    'workProfileId': workProfileId,
    'timezoneId': timezoneId,
    'active': active,
  };
}

class CalendarScheduleController extends ChangeNotifier {
  CalendarScheduleController._(this._records);
  static const _module = 'calendar_schedule';
  final MaintainiacDurableRecordStore _records;

  static Future<CalendarScheduleController> create() async =>
      CalendarScheduleController._(
        await MaintainiacDurableRecordStore.create('calendar_schedule_records'),
      );
  CalendarScheduleController.memory()
    : _records = MaintainiacDurableRecordStore.memory();

  List<CalendarScheduleRecord> get records => _records
      .recordsFor(_module)
      .map((record) => CalendarScheduleRecord.fromMap(record.payload))
      .where((record) => record.active)
      .toList(growable: false);

  Future<CalendarScheduleRecord> save(CalendarScheduleRecord value) async {
    if (value.id.trim().isEmpty || value.title.trim().isEmpty) {
      throw ArgumentError('A schedule requires a stable ID and title.');
    }
    if (value.endsAt != null && !value.endsAt!.isAfter(value.startsAt)) {
      throw ArgumentError('A schedule end must be after its start.');
    }
    await _records.save(module: _module, id: value.id, payload: value.toMap());
    notifyListeners();
    return value;
  }
}

class CalendarScheduleScope
    extends InheritedNotifier<CalendarScheduleController> {
  const CalendarScheduleScope({
    super.key,
    required CalendarScheduleController controller,
    required super.child,
  }) : super(notifier: controller);
  static CalendarScheduleController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<CalendarScheduleScope>()
      ?.notifier;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();
String? _blankToNull(String value) =>
    value.trim().isEmpty ? null : value.trim();
