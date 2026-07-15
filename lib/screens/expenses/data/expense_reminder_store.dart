import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum ExpenseReminderChannel {
  inApp('In-app'),
  push('Push'),
  sound('Sound'),
  all('All');

  const ExpenseReminderChannel(this.label);
  final String label;

  static ExpenseReminderChannel fromName(String? value) {
    return ExpenseReminderChannel.values.firstWhere(
      (channel) => channel.name == value?.trim(),
      orElse: () => ExpenseReminderChannel.inApp,
    );
  }
}

enum ExpenseReminderFrequency {
  once('One time'),
  monthly('Monthly'),
  quarterly('Every 3 months'),
  yearly('Yearly');

  const ExpenseReminderFrequency(this.label);
  final String label;

  static ExpenseReminderFrequency fromName(String? value) {
    return ExpenseReminderFrequency.values.firstWhere(
      (frequency) => frequency.name == value?.trim(),
      orElse: () => ExpenseReminderFrequency.once,
    );
  }
}

class ExpenseReminderRecord {
  const ExpenseReminderRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.dueAt,
    required this.frequency,
    required this.channel,
    required this.createdAt,
    required this.updatedAt,
    this.details = '',
    this.workProfileId = '',
    this.vehicleId = '',
    this.enabled = true,
  });

  factory ExpenseReminderRecord.fromMap(Map<dynamic, dynamic> map) {
    final now = DateTime.now();
    return ExpenseReminderRecord(
      id: map['id']?.toString().trim() ?? '',
      title: map['title']?.toString().trim() ?? '',
      category: map['category']?.toString().trim() ?? 'Uncategorized',
      details: map['details']?.toString().trim() ?? '',
      workProfileId: map['workProfileId']?.toString().trim() ?? '',
      vehicleId: map['vehicleId']?.toString().trim() ?? '',
      dueAt: DateTime.tryParse(map['dueAt']?.toString() ?? '') ?? now,
      frequency: ExpenseReminderFrequency.fromName(map['frequency']?.toString()),
      channel: ExpenseReminderChannel.fromName(map['channel']?.toString()),
      enabled: map['enabled'] != false,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? now,
    );
  }

  final String id;
  final String title;
  final String category;
  final String details;
  final String workProfileId;
  final String vehicleId;
  final DateTime dueAt;
  final ExpenseReminderFrequency frequency;
  final ExpenseReminderChannel channel;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'details': details,
    'workProfileId': workProfileId,
    'vehicleId': vehicleId,
    'dueAt': dueAt.toIso8601String(),
    'frequency': frequency.name,
    'channel': channel.name,
    'enabled': enabled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  bool isOverdueOn(DateTime day) =>
      frequency == ExpenseReminderFrequency.once &&
      dueAt.isBefore(_dateOnly(day));

  String dueLabel(DateTime day) {
    if (isOverdueOn(day)) return 'Overdue';
    if (_dateOnly(dueAt) == _dateOnly(day)) return 'Due today';
    return 'Due ${dueAt.month}/${dueAt.day}/${dueAt.year}';
  }
}

class ExpenseReminderController extends ChangeNotifier {
  ExpenseReminderController._(this._box);
  ExpenseReminderController.memory() : _box = null;

  static const boxName = 'expense_reminders';
  final Box<dynamic>? _box;
  final Map<String, ExpenseReminderRecord> _memory = {};

  static Future<ExpenseReminderController> create() async =>
      ExpenseReminderController._(await Hive.openBox<dynamic>(boxName));

  List<ExpenseReminderRecord> get reminders {
    final values = _box == null
        ? _memory.values.toList(growable: false)
        : _box.values.toList(growable: false);
    return values
        .map(
          (value) => value is ExpenseReminderRecord
              ? value
              : value is Map
              ? ExpenseReminderRecord.fromMap(value)
              : null,
        )
        .whereType<ExpenseReminderRecord>()
        .where((reminder) => reminder.id.isNotEmpty && reminder.title.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  }

  Map<String, Object?> toBackupMap({
    required String ownerUid,
    required DateTime exportedAtUtc,
  }) => {
    'schema': 'expense_reminders_v1',
    'ownerUid': ownerUid.trim(),
    'exportedAtUtc': exportedAtUtc.toUtc().toIso8601String(),
    'reminders': [for (final reminder in reminders) reminder.toMap()],
  };

  List<ExpenseReminderRecord> upcoming({DateTime? from}) {
    final anchor = from ?? DateTime.now();
    return reminders
        .where((reminder) => reminder.enabled)
        .map((reminder) => _advancedPastDueReminder(reminder, anchor))
        .toList(growable: false)
      ..sort((a, b) {
        final aOverdue = a.isOverdueOn(anchor);
        final bOverdue = b.isOverdueOn(anchor);
        if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
        return a.dueAt.compareTo(b.dueAt);
      });
  }

  List<ExpenseReminderRecord> upcomingForScope({
    required String workProfileId,
    required String vehicleId,
    DateTime? from,
  }) => upcoming(from: from)
      .where(
        (reminder) =>
            (reminder.workProfileId.isEmpty ||
                reminder.workProfileId == workProfileId.trim()) &&
            (reminder.vehicleId.isEmpty ||
                reminder.vehicleId == vehicleId.trim()),
      )
      .toList(growable: false);

  Future<ExpenseReminderRecord> save(ExpenseReminderRecord reminder) async {
    final now = DateTime.now();
    final id = reminder.id.trim().isEmpty
        ? 'REM-${now.microsecondsSinceEpoch}'
        : reminder.id.trim();
    final existing = _byId(id);
    final saved = ExpenseReminderRecord(
      id: id,
      title: reminder.title.trim(),
      category: reminder.category.trim().isEmpty
          ? 'Uncategorized'
          : reminder.category.trim(),
      details: reminder.details.trim(),
      workProfileId: reminder.workProfileId.trim(),
      vehicleId: reminder.vehicleId.trim(),
      dueAt: _dateOnly(reminder.dueAt),
      frequency: reminder.frequency,
      channel: reminder.channel,
      enabled: reminder.enabled,
      createdAt: existing?.createdAt ?? reminder.createdAt,
      updatedAt: now,
    );
    if (saved.title.isEmpty) throw ArgumentError('A reminder needs a title.');
    if (_box == null) {
      _memory[id] = saved;
    } else {
      await _box.put(id, saved.toMap());
    }
    notifyListeners();
    return saved;
  }

  Future<void> remove(String id) async {
    if (_box == null) {
      _memory.remove(id);
    } else {
      await _box.delete(id);
    }
    notifyListeners();
  }

  ExpenseReminderRecord? _byId(String id) {
    for (final reminder in reminders) {
      if (reminder.id == id) return reminder;
    }
    return null;
  }
}

class ExpenseReminderScope extends InheritedNotifier<ExpenseReminderController> {
  const ExpenseReminderScope({
    super.key,
    required ExpenseReminderController controller,
    required super.child,
  }) : super(notifier: controller);

  static ExpenseReminderController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ExpenseReminderScope>();
    assert(scope != null, 'ExpenseReminderScope was not found.');
    return scope!.notifier!;
  }
}

ExpenseReminderRecord _advancedPastDueReminder(
  ExpenseReminderRecord reminder,
  DateTime anchor,
) {
  if (reminder.frequency == ExpenseReminderFrequency.once ||
      !reminder.dueAt.isBefore(_dateOnly(anchor))) {
    return reminder;
  }
  var dueAt = reminder.dueAt;
  while (dueAt.isBefore(_dateOnly(anchor))) {
    dueAt = switch (reminder.frequency) {
      ExpenseReminderFrequency.once => dueAt,
      ExpenseReminderFrequency.monthly => _advanceReminderDate(dueAt, months: 1),
      ExpenseReminderFrequency.quarterly => _advanceReminderDate(dueAt, months: 3),
      ExpenseReminderFrequency.yearly => _advanceReminderDate(dueAt, years: 1),
    };
  }
  return ExpenseReminderRecord(
    id: reminder.id,
    title: reminder.title,
    category: reminder.category,
    details: reminder.details,
    workProfileId: reminder.workProfileId,
    vehicleId: reminder.vehicleId,
    dueAt: dueAt,
    frequency: reminder.frequency,
    channel: reminder.channel,
    enabled: reminder.enabled,
    createdAt: reminder.createdAt,
    updatedAt: reminder.updatedAt,
  );
}

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime _advanceReminderDate(
  DateTime date, {
  int months = 0,
  int years = 0,
}) {
  final targetMonth = date.month + months;
  final targetYear = date.year + years + ((targetMonth - 1) ~/ 12);
  final normalizedMonth = ((targetMonth - 1) % 12) + 1;
  final lastDay = DateTime(targetYear, normalizedMonth + 1, 0).day;
  return DateTime(targetYear, normalizedMonth, date.day.clamp(1, lastDay));
}
