import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ExpenseJobRecord {
  const ExpenseJobRecord({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.workProfileId = '',
    this.vehicleId = '',
    this.customerReference = '',
    this.archived = false,
  });

  factory ExpenseJobRecord.fromMap(Map<dynamic, dynamic> map) {
    final now = DateTime.now();
    return ExpenseJobRecord(
      id: map['id']?.toString().trim() ?? '',
      name: map['name']?.toString().trim() ?? '',
      workProfileId: map['workProfileId']?.toString().trim() ?? '',
      vehicleId: map['vehicleId']?.toString().trim() ?? '',
      customerReference: map['customerReference']?.toString().trim() ?? '',
      archived: map['archived'] == true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? now,
    );
  }

  final String id;
  final String name;
  final String workProfileId;
  final String vehicleId;
  final String customerReference;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'workProfileId': workProfileId,
    'vehicleId': vehicleId,
    'customerReference': customerReference,
    'archived': archived,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class ExpenseJobController extends ChangeNotifier {
  ExpenseJobController._(this._box);
  ExpenseJobController.memory() : _box = null;

  static const boxName = 'expense_jobs';
  final Box<dynamic>? _box;
  final Map<String, ExpenseJobRecord> _memory = {};

  static Future<ExpenseJobController> create() async =>
      ExpenseJobController._(await Hive.openBox<dynamic>(boxName));

  List<ExpenseJobRecord> get jobs {
    final values = _box == null
        ? _memory.values.toList(growable: false)
        : _box.values.toList(growable: false);
    return values
        .map(
          (value) => value is ExpenseJobRecord
              ? value
              : value is Map
              ? ExpenseJobRecord.fromMap(value)
              : null,
        )
        .whereType<ExpenseJobRecord>()
        .where((job) => job.id.isNotEmpty && job.name.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<ExpenseJobRecord> get activeJobs =>
      jobs.where((job) => !job.archived).toList(growable: false);

  Future<ExpenseJobRecord> save(ExpenseJobRecord job) async {
    final now = DateTime.now();
    final existing = _jobById(job.id);
    final saved = ExpenseJobRecord(
      id: job.id.trim().isEmpty ? 'JOB-${now.microsecondsSinceEpoch}' : job.id,
      name: job.name.trim(),
      workProfileId: job.workProfileId.trim(),
      vehicleId: job.vehicleId.trim(),
      customerReference: job.customerReference.trim(),
      archived: job.archived,
      createdAt: existing?.createdAt ?? job.createdAt,
      updatedAt: now,
    );
    if (saved.name.isEmpty) throw ArgumentError('A job needs a name.');
    if (_box == null) {
      _memory[saved.id] = saved;
    } else {
      await _box.put(saved.id, saved.toMap());
    }
    notifyListeners();
    return saved;
  }

  Future<ExpenseJobRecord?> archive(String id) async {
    final job = _jobById(id);
    if (job == null) return null;
    return save(
      ExpenseJobRecord(
        id: job.id,
        name: job.name,
        workProfileId: job.workProfileId,
        vehicleId: job.vehicleId,
        customerReference: job.customerReference,
        archived: true,
        createdAt: job.createdAt,
        updatedAt: job.updatedAt,
      ),
    );
  }

  ExpenseJobRecord? _jobById(String id) {
    for (final job in jobs) {
      if (job.id == id) return job;
    }
    return null;
  }
}

class ExpenseJobScope extends InheritedNotifier<ExpenseJobController> {
  const ExpenseJobScope({
    super.key,
    required ExpenseJobController controller,
    required super.child,
  }) : super(notifier: controller);

  static ExpenseJobController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ExpenseJobScope>();
    assert(scope != null, 'ExpenseJobScope was not found.');
    return scope!.notifier!;
  }

  static ExpenseJobController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExpenseJobScope>()?.notifier;
}
