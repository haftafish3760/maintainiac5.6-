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
      lifecycle: map['lifecycle'] is Map
          ? MaintainiacRecordLifecycle.fromMap(
              map['lifecycle'] as Map,
              fallbackTime: now,
            )
          : null,
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
    var next = dueAt;
    while (!next.isAfter(reference)) {
      next = switch (cadence) {
        ExpenseReminderCadence.once => next,
        ExpenseReminderCadence.monthly => DateTime(
          next.year,
          next.month + 1,
          next.day,
          next.hour,
          next.minute,
        ),
        ExpenseReminderCadence.quarterly => DateTime(
          next.year,
          next.month + 3,
          next.day,
          next.hour,
          next.minute,
        ),
        ExpenseReminderCadence.yearly => DateTime(
          next.year + 1,
          next.month,
          next.day,
          next.hour,
          next.minute,
        ),
      };
    }
    return next;
  }
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
        reminders.add(ExpenseReminderRecord.fromMap(value));
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

  Future<ExpenseReminderRecord> save(ExpenseReminderRecord reminder) async {
    final title = reminder.title.trim();
    if (title.isEmpty) throw ArgumentError.value(title, 'title', 'Required');
    await ensureStorageForLocalSave();
    final now = DateTime.now();
    final id = reminder.id.trim().isEmpty
        ? 'EXP-REM-${now.microsecondsSinceEpoch}'
        : reminder.id;
    final existing = recordById(id);
    if (existing?.isDeleted ?? false) {
      throw StateError('Restore a removed reminder before changing it.');
    }
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
      createdAt: existing?.createdAt ?? reminder.createdAt,
      updatedAt: now,
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

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);

  Future<void> ensureStorageForLocalSave() async {
    final check = _storageCheck;
    if (check == null) return;
    final storage = await check();
    if (!storage.hasEnoughSpace) throw StateError(storage.blockingMessage());
  }

  Future<void> setActive(ExpenseReminderRecord reminder, bool active) {
    return save(reminder.copyWith(active: active));
  }

  Future<void> delete(String id) async {
    final existing = recordById(id);
    if (existing == null || existing.isDeleted) return;
    final now = DateTime.now();
    final lifecycle =
        (existing.lifecycle ??
                MaintainiacRecordLifecycle(
                  createdAt: existing.createdAt,
                  updatedAt: existing.updatedAt,
                ))
            .deleted(now, event: 'deleted reminder');
    final deleted = existing.copyWith(updatedAt: now, lifecycle: lifecycle);
    if (_box == null) {
      _memory[id] = deleted;
    } else {
      await _box.put(id, deleted.toMap());
    }
    notifyListeners();
  }

  Future<void> restore(String id) async {
    final existing = recordById(id);
    if (existing == null || !existing.isDeleted) return;
    final now = DateTime.now();
    final lifecycle = existing.lifecycle!.restored(
      now,
      event: 'restored reminder',
    );
    final restored = existing.copyWith(updatedAt: now, lifecycle: lifecycle);
    if (_box == null) {
      _memory[id] = restored;
    } else {
      await _box.put(id, restored.toMap());
    }
    notifyListeners();
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
