import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/records/maintainiac_record_lifecycle.dart';
import '../../../shared/storage/app_storage_guard.dart';

enum ExpenseReminderCadence {
  once('One time'),
  monthly('Monthly'),
  quarterly('Every 3 months'),
  yearly('Yearly');

  const ExpenseReminderCadence(this.label);

  final String label;

  static ExpenseReminderCadence fromName(String? value) {
    return ExpenseReminderCadence.values.firstWhere(
      (cadence) => cadence.name == value,
      orElse: () => ExpenseReminderCadence.once,
    );
  }
}

class ExpenseReminderRecord {
  const ExpenseReminderRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.channel,
    required this.dueAt,
    required this.cadence,
    required this.createdAt,
    required this.updatedAt,
    this.details = '',
    this.active = true,
    this.lifecycle,
  });

  factory ExpenseReminderRecord.fromMap(Map<dynamic, dynamic> map) {
    final now = DateTime.now();
    return ExpenseReminderRecord(
      id: '${map['id'] ?? ''}',
      title: '${map['title'] ?? ''}',
      category: '${map['category'] ?? 'Other'}',
      channel: '${map['channel'] ?? 'In-app'}',
      dueAt: DateTime.tryParse('${map['dueAt'] ?? ''}') ?? now,
      cadence: ExpenseReminderCadence.fromName('${map['cadence'] ?? ''}'),
      details: '${map['details'] ?? ''}',
      active: map['active'] != false,
      createdAt: DateTime.tryParse('${map['createdAt'] ?? ''}') ?? now,
      updatedAt: DateTime.tryParse('${map['updatedAt'] ?? ''}') ?? now,
      lifecycle: _decodeReminderLifecycle(map['lifecycle']),
    );
  }

  final String id;
  final String title;
  final String category;
  final String channel;
  final DateTime dueAt;
  final ExpenseReminderCadence cadence;
  final String details;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MaintainiacRecordLifecycle? lifecycle;

  bool get isDeleted => lifecycle?.isDeleted ?? false;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'channel': channel,
    'dueAt': dueAt.toUtc().toIso8601String(),
    'cadence': cadence.name,
    'details': details,
    'active': active,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'lifecycle': lifecycle?.toMap(),
  };

  ExpenseReminderRecord copyWith({
    String? title,
    String? category,
    String? channel,
    DateTime? dueAt,
    ExpenseReminderCadence? cadence,
    String? details,
    bool? active,
    DateTime? updatedAt,
    MaintainiacRecordLifecycle? lifecycle,
  }) {
    return ExpenseReminderRecord(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      channel: channel ?? this.channel,
      dueAt: dueAt ?? this.dueAt,
      cadence: cadence ?? this.cadence,
      details: details ?? this.details,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lifecycle: lifecycle ?? this.lifecycle,
    );
  }

  DateTime nextOccurrenceAfter(DateTime reference) {
    if (cadence == ExpenseReminderCadence.once || dueAt.isAfter(reference)) {
      return dueAt;
    }
    var occurrence = _firstOccurrenceOnOrBefore(reference);
    var next = _recurringOccurrence(dueAt, cadence, occurrence);
    while (!next.isAfter(reference)) {
      occurrence += 1;
      next = _recurringOccurrence(dueAt, cadence, occurrence);
    }
    return next;
  }

  int _firstOccurrenceOnOrBefore(DateTime reference) {
    final monthsBetween =
        (reference.year - dueAt.year) * 12 + reference.month - dueAt.month;
    return switch (cadence) {
      ExpenseReminderCadence.once => 1,
      ExpenseReminderCadence.monthly => monthsBetween < 1 ? 1 : monthsBetween,
      ExpenseReminderCadence.quarterly =>
        monthsBetween < 3 ? 1 : monthsBetween ~/ 3,
      ExpenseReminderCadence.yearly =>
        reference.year - dueAt.year < 1 ? 1 : reference.year - dueAt.year,
    };
  }
}

DateTime _recurringOccurrence(
  DateTime dueAt,
  ExpenseReminderCadence cadence,
  int occurrence,
) {
  final targetMonth = switch (cadence) {
    ExpenseReminderCadence.once => dueAt.month,
    ExpenseReminderCadence.monthly => dueAt.month + occurrence,
    ExpenseReminderCadence.quarterly => dueAt.month + (occurrence * 3),
    ExpenseReminderCadence.yearly => dueAt.month,
  };
  final targetYear = switch (cadence) {
    ExpenseReminderCadence.yearly => dueAt.year + occurrence,
    _ => dueAt.year,
  };
  final monthStart = DateTime(targetYear, targetMonth);
  final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
  return DateTime(
    monthStart.year,
    monthStart.month,
    dueAt.day.clamp(1, lastDay),
    dueAt.hour,
    dueAt.minute,
    dueAt.second,
    dueAt.millisecond,
    dueAt.microsecond,
  );
}

MaintainiacRecordLifecycle? _decodeReminderLifecycle(Object? value) {
  if (value == null) return null;
  if (value is! Map) {
    throw const FormatException('Reminder lifecycle is corrupt.');
  }
  final createdAt = DateTime.tryParse('${value['createdAt'] ?? ''}');
  final updatedAt = DateTime.tryParse('${value['updatedAt'] ?? ''}');
  final deletedAt = value['deletedAt'] == null
      ? null
      : DateTime.tryParse('${value['deletedAt']}');
  final revision = value['revision'];
  final stateName = '${value['state'] ?? ''}';
  final states = MaintainiacRecordState.values.where(
    (state) => state.name == stateName,
  );
  if (createdAt == null ||
      updatedAt == null ||
      updatedAt.isBefore(createdAt) ||
      revision is! int ||
      revision < 1 ||
      states.length != 1 ||
      (stateName == MaintainiacRecordState.deleted.name && deletedAt == null) ||
      (stateName == MaintainiacRecordState.active.name && deletedAt != null) ||
      (deletedAt != null &&
          (deletedAt.isBefore(createdAt) || deletedAt.isAfter(updatedAt)))) {
    throw const FormatException('Reminder lifecycle is corrupt.');
  }
  return MaintainiacRecordLifecycle(
    createdAt: createdAt,
    updatedAt: updatedAt,
    revision: revision,
    state: states.single,
    deletedAt: deletedAt,
    auditEvents:
        (value['auditEvents'] as List?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const [],
  );
}

typedef ExpenseReminderStorageCheck = Future<AppStorageCheck> Function();

class ExpenseReminderController extends ChangeNotifier {
  ExpenseReminderController._(
    this._box, {
    ExpenseReminderStorageCheck? storageCheck,
  }) : _storageCheck = storageCheck ?? _defaultStorageCheck;
  ExpenseReminderController.memory({ExpenseReminderStorageCheck? storageCheck})
    : _box = null,
      _storageCheck = storageCheck;

  static const boxName = 'expense_reminders_v1';
  final Box<dynamic>? _box;
  final ExpenseReminderStorageCheck? _storageCheck;
  final _memory = <String, ExpenseReminderRecord>{};
  Future<void> _writeTail = Future<void>.value();

  static Future<ExpenseReminderController> create({
    ExpenseReminderStorageCheck? storageCheck,
  }) async {
    return ExpenseReminderController._(
      await Hive.openBox<dynamic>(boxName),
      storageCheck: storageCheck,
    );
  }

  List<ExpenseReminderRecord> get records {
    return storedRecords
        .where((record) => !record.isDeleted)
        .toList(growable: false);
  }

  List<ExpenseReminderRecord> get storedRecords {
    final box = _box;
    final source = box == null ? _memory.values : box.values;
    final reminders = <ExpenseReminderRecord>[];
    for (final value in source) {
      if (value is ExpenseReminderRecord) {
        reminders.add(value);
      } else if (value is Map) {
        try {
          reminders.add(ExpenseReminderRecord.fromMap(value));
        } on FormatException {
          continue;
        }
      }
    }
    reminders.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return List.unmodifiable(reminders);
  }

  ExpenseReminderRecord? recordById(String id) {
    for (final record in storedRecords) {
      if (record.id == id) return record;
    }
    return null;
  }

  Future<ExpenseReminderRecord> save(ExpenseReminderRecord reminder) =>
      _enqueue(() => _save(reminder));

  Future<ExpenseReminderRecord> _save(ExpenseReminderRecord reminder) async {
    final title = reminder.title.trim();
    if (title.isEmpty) throw ArgumentError.value(title, 'title', 'Required');
    await ensureStorageForLocalSave();
    final requestedNow = DateTime.now();
    final id = reminder.id.trim().isEmpty
        ? 'EXP-REM-${requestedNow.microsecondsSinceEpoch}'
        : reminder.id;
    final existing = recordById(id);
    if (existing?.isDeleted ?? false) {
      throw StateError('Restore a removed reminder before changing it.');
    }
    if (existing != null && reminder.updatedAt.isBefore(existing.updatedAt)) {
      throw StateError('Reload the newer reminder before saving changes.');
    }
    final now = _nextLifecycleTime(
      requestedNow,
      createdAt: existing?.createdAt ?? reminder.createdAt,
      updatedAt: existing?.updatedAt,
      lifecycleUpdatedAt: existing?.lifecycle?.updatedAt,
    );
    final lifecycle = existing == null
        ? MaintainiacRecordLifecycle(
            createdAt: reminder.createdAt,
            updatedAt: now,
            auditEvents: ['${now.toIso8601String()} created reminder'],
          )
        : (existing.lifecycle ??
                  MaintainiacRecordLifecycle(
                    createdAt: existing.createdAt,
                    updatedAt: existing.updatedAt,
                  ))
              .saved(now, event: 'updated reminder');
    final saved = ExpenseReminderRecord(
      id: id,
      title: title,
      category: reminder.category.trim().isEmpty ? 'Other' : reminder.category,
      channel: reminder.channel.trim().isEmpty ? 'In-app' : reminder.channel,
      dueAt: reminder.dueAt,
      cadence: reminder.cadence,
      details: reminder.details.trim(),
      active: reminder.active,
      createdAt: lifecycle.createdAt,
      updatedAt: lifecycle.updatedAt,
      lifecycle: lifecycle,
    );
    if (_box == null) {
      _memory[id] = saved;
    } else {
      await _box.put(id, saved.toMap());
    }
    notifyListeners();
    return saved;
  }

  /// Imports a user-authorized cloud record only when no local ID exists.
  ///
  /// This preserves a cloud tombstone's lifecycle metadata and never replaces
  /// a local reminder that may have been edited on this device.
  Future<ExpenseReminderRecord?> importIfMissing(
    ExpenseReminderRecord reminder,
  ) => _enqueue(() => _importIfMissing(reminder));

  Future<ExpenseReminderRecord?> _importIfMissing(
    ExpenseReminderRecord reminder,
  ) async {
    final id = reminder.id.trim();
    if (id.isEmpty || recordById(id) != null) return null;
    await ensureStorageForLocalSave();
    if (_box == null) {
      _memory[id] = reminder;
    } else {
      await _box.put(id, reminder.toMap());
    }
    notifyListeners();
    return reminder;
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);

  static DateTime _nextLifecycleTime(
    DateTime requested, {
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lifecycleUpdatedAt,
  }) {
    final floors = <DateTime>[?createdAt, ?updatedAt, ?lifecycleUpdatedAt];
    if (floors.isEmpty) return requested;
    final floor = floors.reduce((latest, value) {
      return value.isAfter(latest) ? value : latest;
    });
    if (updatedAt == null && lifecycleUpdatedAt == null) {
      return requested.isBefore(floor) ? floor : requested;
    }
    return requested.isAfter(floor)
        ? requested
        : floor.add(const Duration(microseconds: 1));
  }

  Future<void> ensureStorageForLocalSave() async {
    final check = _storageCheck;
    if (check == null) return;
    final storage = await check();
    if (!storage.hasEnoughSpace) throw StateError(storage.blockingMessage());
  }

  Future<void> setActive(ExpenseReminderRecord reminder, bool active) {
    return save(reminder.copyWith(active: active));
  }

  Future<void> delete(String id) => _enqueue(() => _delete(id));

  Future<void> _delete(String id) async {
    final existing = recordById(id);
    if (existing == null || existing.isDeleted) return;
    await ensureStorageForLocalSave();
    final now = _nextLifecycleTime(
      DateTime.now(),
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
      lifecycleUpdatedAt: existing.lifecycle?.updatedAt,
    );
    final lifecycle =
        (existing.lifecycle ??
                MaintainiacRecordLifecycle(
                  createdAt: existing.createdAt,
                  updatedAt: existing.updatedAt,
                ))
            .deleted(now, event: 'deleted reminder');
    final deleted = existing.copyWith(
      updatedAt: lifecycle.updatedAt,
      lifecycle: lifecycle,
    );
    if (_box == null) {
      _memory[id] = deleted;
    } else {
      await _box.put(id, deleted.toMap());
    }
    notifyListeners();
  }

  Future<void> restore(String id) => _enqueue(() => _restore(id));

  Future<void> _restore(String id) async {
    final existing = recordById(id);
    if (existing == null || !existing.isDeleted) return;
    await ensureStorageForLocalSave();
    final now = _nextLifecycleTime(
      DateTime.now(),
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
      lifecycleUpdatedAt: existing.lifecycle?.updatedAt,
    );
    final lifecycle = existing.lifecycle!.restored(
      now,
      event: 'restored reminder',
    );
    final restored = existing.copyWith(
      updatedAt: lifecycle.updatedAt,
      lifecycle: lifecycle,
    );
    if (_box == null) {
      _memory[id] = restored;
    } else {
      await _box.put(id, restored.toMap());
    }
    notifyListeners();
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}

class ExpenseReminderScope
    extends InheritedNotifier<ExpenseReminderController> {
  const ExpenseReminderScope({
    super.key,
    required ExpenseReminderController controller,
    required super.child,
  }) : super(notifier: controller);

  static ExpenseReminderController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExpenseReminderScope>();
    assert(scope != null, 'ExpenseReminderScope is missing above context.');
    return scope!.notifier!;
  }
}
