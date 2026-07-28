import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../storage/app_storage_guard.dart';

typedef MaintainiacJobStorageCheck = Future<AppStorageCheck> Function();

class MaintainiacJobRecord {
  const MaintainiacJobRecord({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.number = '',
    this.customerId = '',
    this.customerReference = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.address = '',
    this.notes = '',
    this.workProfileId = '',
    this.vehicleIds = const [],
    this.assignedMemberIds = const [],
    this.estimateId = '',
    this.invoiceId = '',
    this.scheduledStart,
    this.scheduledEnd,
    this.repeatRule = 'none',
    this.inAppReminder = false,
    this.pushReminder = false,
    this.soundReminder = false,
    this.reminderLeadMinutes = 60,
    this.archived = false,
  });

  factory MaintainiacJobRecord.fromMap(Map<dynamic, dynamic> map) {
    final id = _jobString(map['id']);
    final legacyVehicleId = _jobString(map['vehicleId']);
    final vehicleIds = _jobStringList(map['vehicleIds']);
    return MaintainiacJobRecord(
      id: id,
      number: _jobString(map['number']).isEmpty
          ? id
          : _jobString(map['number']),
      name: _jobString(map['name']),
      customerId: _jobString(map['customerId']),
      customerReference: _jobString(map['customerReference']),
      customerPhone: _jobString(map['customerPhone']),
      customerEmail: _jobString(map['customerEmail']),
      address: _jobString(map['address']),
      notes: _jobString(map['notes']),
      workProfileId: _jobString(map['workProfileId']),
      vehicleIds: vehicleIds.isEmpty && legacyVehicleId.isNotEmpty
          ? [legacyVehicleId]
          : vehicleIds,
      assignedMemberIds: _jobStringList(map['assignedMemberIds']),
      estimateId: _jobString(map['estimateId']),
      invoiceId: _jobString(map['invoiceId']),
      scheduledStart: _jobDate(map['scheduledStart']),
      scheduledEnd: _jobDate(map['scheduledEnd']),
      repeatRule: _jobString(map['repeatRule']).isEmpty
          ? 'none'
          : _jobString(map['repeatRule']),
      inAppReminder: map['inAppReminder'] == true,
      pushReminder: map['pushReminder'] == true,
      soundReminder: map['soundReminder'] == true,
      reminderLeadMinutes: _jobInt(map['reminderLeadMinutes'], fallback: 60),
      archived: map['archived'] == true,
      createdAt:
          _jobDate(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _jobDate(map['updatedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String number;
  final String name;
  final String customerId;
  final String customerReference;
  final String customerPhone;
  final String customerEmail;
  final String address;
  final String notes;
  final String workProfileId;
  final List<String> vehicleIds;
  final List<String> assignedMemberIds;
  final String estimateId;
  final String invoiceId;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final String repeatRule;
  final bool inAppReminder;
  final bool pushReminder;
  final bool soundReminder;
  final int reminderLeadMinutes;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'number': number,
    'name': name,
    'customerId': customerId,
    'customerReference': customerReference,
    'customerPhone': customerPhone,
    'customerEmail': customerEmail,
    'address': address,
    'notes': notes,
    'workProfileId': workProfileId,
    'vehicleIds': vehicleIds,
    'assignedMemberIds': assignedMemberIds,
    'estimateId': estimateId,
    'invoiceId': invoiceId,
    'scheduledStart': scheduledStart?.toIso8601String(),
    'scheduledEnd': scheduledEnd?.toIso8601String(),
    'repeatRule': repeatRule,
    'inAppReminder': inAppReminder,
    'pushReminder': pushReminder,
    'soundReminder': soundReminder,
    'reminderLeadMinutes': reminderLeadMinutes,
    'archived': archived,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  MaintainiacJobRecord copyWith({
    String? id,
    String? number,
    String? name,
    String? customerId,
    String? customerReference,
    String? customerPhone,
    String? customerEmail,
    String? address,
    String? notes,
    String? workProfileId,
    List<String>? vehicleIds,
    List<String>? assignedMemberIds,
    String? estimateId,
    String? invoiceId,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    String? repeatRule,
    bool? inAppReminder,
    bool? pushReminder,
    bool? soundReminder,
    int? reminderLeadMinutes,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintainiacJobRecord(
      id: id ?? this.id,
      number: number ?? this.number,
      name: name ?? this.name,
      customerId: customerId ?? this.customerId,
      customerReference: customerReference ?? this.customerReference,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      workProfileId: workProfileId ?? this.workProfileId,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      assignedMemberIds: assignedMemberIds ?? this.assignedMemberIds,
      estimateId: estimateId ?? this.estimateId,
      invoiceId: invoiceId ?? this.invoiceId,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      repeatRule: repeatRule ?? this.repeatRule,
      inAppReminder: inAppReminder ?? this.inAppReminder,
      pushReminder: pushReminder ?? this.pushReminder,
      soundReminder: soundReminder ?? this.soundReminder,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MaintainiacJobController extends ChangeNotifier {
  MaintainiacJobController._({
    required Box<dynamic>? box,
    required Box<dynamic>? legacyBox,
    required MaintainiacJobStorageCheck? storageCheck,
    Map<String, MaintainiacJobRecord>? memory,
  }) : _box = box,
       _legacyBox = legacyBox,
       _storageCheck = storageCheck,
       _memory = memory ?? {};

  static const boxName = 'maintainiac_jobs_v1';
  static const legacyExpenseBoxName = 'expense_jobs';

  final Box<dynamic>? _box;
  final Box<dynamic>? _legacyBox;
  final MaintainiacJobStorageCheck? _storageCheck;
  final Map<String, MaintainiacJobRecord> _memory;
  Future<void> _writeTail = Future<void>.value();

  static Future<MaintainiacJobController> create({
    MaintainiacJobStorageCheck? storageCheck,
  }) async {
    final controller = MaintainiacJobController._(
      box: await Hive.openBox<dynamic>(boxName),
      legacyBox: await Hive.openBox<dynamic>(legacyExpenseBoxName),
      storageCheck: storageCheck ?? _defaultStorageCheck,
    );
    await controller._migrateLegacyRecordsWithoutDeletion();
    return controller;
  }

  factory MaintainiacJobController.memory({
    Iterable<MaintainiacJobRecord> initialJobs = const [],
  }) {
    return MaintainiacJobController._(
      box: null,
      legacyBox: null,
      storageCheck: null,
      memory: {for (final job in initialJobs) job.id: job},
    );
  }

  List<MaintainiacJobRecord> get jobs {
    final byId = <String, MaintainiacJobRecord>{};
    void addStored(Iterable<dynamic> values) {
      for (final value in values) {
        final job = _jobFromStored(value);
        if (job == null || job.id.isEmpty || job.name.isEmpty) continue;
        byId[job.id] = job;
      }
    }

    final legacyBox = _legacyBox;
    if (legacyBox != null) addStored(legacyBox.values);
    addStored(_memory.values);
    final box = _box;
    if (box != null) addStored(box.values);
    final result = byId.values.toList(growable: false);
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  List<MaintainiacJobRecord> get activeJobs =>
      jobs.where((job) => !job.archived).toList(growable: false);

  MaintainiacJobRecord? jobById(String id) {
    final cleanId = id.trim();
    for (final job in jobs) {
      if (job.id == cleanId) return job;
    }
    return null;
  }

  List<Map<String, Object?>> backupPayloads() =>
      jobs.map((job) => job.toMap()).toList(growable: false);

  Future<MaintainiacJobRecord> save(MaintainiacJobRecord job) {
    return _enqueue(() async {
      final now = DateTime.now().toUtc();
      final existing = job.id.trim().isEmpty ? null : jobById(job.id);
      final id = job.id.trim().isEmpty
          ? 'JOB-${now.microsecondsSinceEpoch}'
          : job.id.trim();
      final number = job.number.trim().isEmpty ? id : job.number.trim();
      final saved = MaintainiacJobRecord(
        id: id,
        number: number,
        name: job.name.trim(),
        customerId: job.customerId.trim(),
        customerReference: job.customerReference.trim(),
        customerPhone: job.customerPhone.trim(),
        customerEmail: job.customerEmail.trim(),
        address: job.address.trim(),
        notes: job.notes.trim(),
        workProfileId: job.workProfileId.trim(),
        vehicleIds: _normalizedIds(job.vehicleIds),
        assignedMemberIds: _normalizedIds(job.assignedMemberIds),
        estimateId: job.estimateId.trim(),
        invoiceId: job.invoiceId.trim(),
        scheduledStart: job.scheduledStart,
        scheduledEnd: job.scheduledEnd,
        repeatRule: job.repeatRule.trim(),
        inAppReminder: job.inAppReminder,
        pushReminder: job.pushReminder,
        soundReminder: job.soundReminder,
        reminderLeadMinutes: job.reminderLeadMinutes,
        archived: job.archived,
        createdAt: existing?.createdAt ?? job.createdAt.toUtc(),
        updatedAt: now,
      );
      _validate(saved);
      final box = _box;
      if (box == null) {
        _memory[saved.id] = saved;
      } else {
        await _ensureStorageForWrite();
        await box.put(saved.id, saved.toMap());
      }
      notifyListeners();
      return saved;
    });
  }

  Future<MaintainiacJobRecord?> archive(String id) async {
    final job = jobById(id);
    if (job == null) return null;
    return save(job.copyWith(archived: true));
  }

  Future<void> _migrateLegacyRecordsWithoutDeletion() async {
    final box = _box;
    final legacyBox = _legacyBox;
    if (box == null || legacyBox == null || legacyBox.isEmpty) return;
    final pending = <MaintainiacJobRecord>[];
    for (final value in legacyBox.values) {
      final job = _jobFromStored(value);
      if (job == null || job.id.isEmpty || job.name.isEmpty) continue;
      if (!box.containsKey(job.id)) pending.add(job);
    }
    if (pending.isEmpty) return;
    final check = _storageCheck;
    if (check != null && !(await check()).hasEnoughSpace) return;
    for (final job in pending) {
      await box.put(job.id, job.toMap());
    }
  }

  Future<void> _ensureStorageForWrite() async {
    final check = _storageCheck;
    if (check == null) return;
    final result = await check();
    if (!result.hasEnoughSpace) throw StateError(result.blockingMessage());
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _writeTail.then((_) => operation());
    _writeTail = result.then<void>((_) {}, onError: (error, stackTrace) {});
    return result;
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);
}

class MaintainiacJobScope extends InheritedNotifier<MaintainiacJobController> {
  const MaintainiacJobScope({
    super.key,
    required MaintainiacJobController controller,
    required super.child,
  }) : super(notifier: controller);

  static MaintainiacJobController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<MaintainiacJobScope>();
    assert(scope != null, 'MaintainiacJobScope was not found.');
    return scope!.notifier!;
  }

  static MaintainiacJobController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MaintainiacJobScope>()
      ?.notifier;
}

MaintainiacJobRecord? _jobFromStored(dynamic value) {
  if (value is MaintainiacJobRecord) return value;
  if (value is Map) return MaintainiacJobRecord.fromMap(value);
  return null;
}

String _jobString(dynamic value) => value?.toString().trim() ?? '';

DateTime? _jobDate(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(_jobString(value));
}

int _jobInt(dynamic value, {required int fallback}) {
  if (value is int) return value;
  return int.tryParse(_jobString(value)) ?? fallback;
}

List<String> _jobStringList(dynamic value) {
  if (value is! Iterable) return const [];
  return _normalizedIds(value.map(_jobString));
}

List<String> _normalizedIds(Iterable<String> values) {
  final seen = <String>{};
  return [
    for (final value in values)
      if (value.trim().isNotEmpty && seen.add(value.trim())) value.trim(),
  ];
}

void _validate(MaintainiacJobRecord job) {
  if (job.name.isEmpty) throw ArgumentError('A job needs a name.');
  for (final entry in <String, String>{
    'id': job.id,
    'number': job.number,
    if (job.customerId.isNotEmpty) 'customerId': job.customerId,
    if (job.workProfileId.isNotEmpty) 'workProfileId': job.workProfileId,
    if (job.estimateId.isNotEmpty) 'estimateId': job.estimateId,
    if (job.invoiceId.isNotEmpty) 'invoiceId': job.invoiceId,
    for (var index = 0; index < job.vehicleIds.length; index++)
      'vehicleIds[$index]': job.vehicleIds[index],
    for (var index = 0; index < job.assignedMemberIds.length; index++)
      'assignedMemberIds[$index]': job.assignedMemberIds[index],
  }.entries) {
    if (!_isSafeJobId(entry.value)) {
      throw ArgumentError.value(
        entry.value,
        entry.key,
        'Job reference ids must be safe tokens.',
      );
    }
  }
  final end = job.scheduledEnd;
  final start = job.scheduledStart;
  if (start != null && end != null && end.isBefore(start)) {
    throw ArgumentError('A job cannot end before it starts.');
  }
  if (job.soundReminder && !job.pushReminder) {
    throw ArgumentError('A sound reminder requires a push reminder.');
  }
  if (job.reminderLeadMinutes < 0) {
    throw ArgumentError('Reminder lead time cannot be negative.');
  }
}

bool _isSafeJobId(String value) =>
    value.isNotEmpty &&
    value.length <= 160 &&
    RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(value);
