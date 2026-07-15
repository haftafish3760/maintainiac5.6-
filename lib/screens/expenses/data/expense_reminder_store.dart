import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

class ExpenseReminderController extends ChangeNotifier {
  ExpenseReminderController._(this._box);
  ExpenseReminderController.memory() : _box = null;

  static const boxName = 'expense_reminders_v1';
  final Box<dynamic>? _box;
  final _memory = <String, ExpenseReminderRecord>{};

  static Future<ExpenseReminderController> create() async {
    return ExpenseReminderController._(await Hive.openBox<dynamic>(boxName));
  }

  List<ExpenseReminderRecord> get records {
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

  Future<ExpenseReminderRecord> save(ExpenseReminderRecord reminder) async {
    final title = reminder.title.trim();
    if (title.isEmpty) throw ArgumentError.value(title, 'title', 'Required');
    final now = DateTime.now();
    final id = reminder.id.trim().isEmpty
        ? 'EXP-REM-${now.microsecondsSinceEpoch}'
        : reminder.id;
    final saved = ExpenseReminderRecord(
      id: id,
      title: title,
      category: reminder.category.trim().isEmpty ? 'Other' : reminder.category,
      channel: reminder.channel.trim().isEmpty ? 'In-app' : reminder.channel,
      dueAt: reminder.dueAt,
      cadence: reminder.cadence,
      details: reminder.details.trim(),
      active: reminder.active,
      createdAt: reminder.createdAt,
      updatedAt: now,
    );
    if (_box == null) {
      _memory[id] = saved;
    } else {
      await _box.put(id, saved.toMap());
    }
    notifyListeners();
    return saved;
  }

  Future<void> setActive(ExpenseReminderRecord reminder, bool active) {
    return save(reminder.copyWith(active: active));
  }

  Future<void> delete(String id) async {
    if (_box == null) {
      _memory.remove(id);
    } else {
      await _box.delete(id);
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
