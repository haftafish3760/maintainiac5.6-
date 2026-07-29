// Employee work-time records are source-owned by Profiles and persist only
// through Maintainiac's shared durable-record lifecycle.

import 'package:flutter/widgets.dart';

import '../durable_storage/maintainiac_durable_storage.dart';
import 'employee_work_time_contract.dart';

class EmployeeWorkTimeController extends ChangeNotifier {
  EmployeeWorkTimeController._(this._records);

  static const _module = 'employee_work_time';
  final MaintainiacDurableRecordStore _records;

  static Future<EmployeeWorkTimeController> create() async =>
      EmployeeWorkTimeController._(
        await MaintainiacDurableRecordStore.create(
          'employee_work_time_records',
        ),
      );

  EmployeeWorkTimeController.memory()
    : _records = MaintainiacDurableRecordStore.memory();

  static Future<EmployeeWorkTimeController> createOrMemory() async {
    try {
      return await create();
    } catch (_) {
      return EmployeeWorkTimeController.memory();
    }
  }

  List<EmployeeWorkTimeRecord> get records {
    final result = <EmployeeWorkTimeRecord>[];
    for (final durable in _records.recordsFor(_module)) {
      try {
        result.add(EmployeeWorkTimeRecord.fromMap(durable.payload));
      } catch (_) {
        // Preserve unreadable source payload in Durable Storage for recovery.
      }
    }
    result.sort((left, right) {
      final day = right.workDate.compareTo(left.workDate);
      return day != 0 ? day : right.recordedAt.compareTo(left.recordedAt);
    });
    return List.unmodifiable(result);
  }

  List<EmployeeWorkTimeRecord> recordsForEmployee(String employeeId) => records
      .where((record) => record.employeeId == employeeId.trim())
      .toList(growable: false);

  EmployeeWorkTimeRecord? recordById(String id) {
    final durable = _records.recordFor(_module, id.trim());
    if (durable == null) return null;
    try {
      return EmployeeWorkTimeRecord.fromMap(durable.payload);
    } catch (_) {
      return null;
    }
  }

  Future<EmployeeWorkTimeRecord> save(EmployeeWorkTimeRecord proposed) async {
    final id = proposed.id.trim();
    if (id.isEmpty || id.contains(':')) {
      throw ArgumentError.value(proposed.id, 'id', 'requires a stable ID');
    }
    final existing = recordById(id);
    if (existing?.status == EmployeeWorkTimeStatus.locked &&
        proposed.status != EmployeeWorkTimeStatus.corrected) {
      throw StateError('A locked time entry requires a corrected revision.');
    }
    final now = DateTime.now();
    final saved = EmployeeWorkTimeRecord(
      id: id,
      employeeId: proposed.employeeId.trim(),
      workDate: proposed.workDate,
      recordedAt: existing?.recordedAt ?? proposed.recordedAt,
      status: proposed.status,
      revision: (existing?.revision ?? -1) + 1,
      clockInAt: proposed.clockInAt,
      clockOutAt: proposed.clockOutAt,
      manualPaidMinutes: proposed.manualPaidMinutes,
      unpaidBreakMinutes: proposed.unpaidBreakMinutes,
      jobAllocations: proposed.jobAllocations,
      vehicleIds: proposed.vehicleIds,
      workProfileId: proposed.workProfileId,
      timezoneId: proposed.timezoneId,
      enteredByEmployeeId: proposed.enteredByEmployeeId,
      approvedByEmployeeId: proposed.approvedByEmployeeId,
      correctionReason: proposed.correctionReason,
      auditReference:
          proposed.auditReference ?? 'saved:${now.toIso8601String()}',
    );
    await _records.save(
      module: _module,
      id: id,
      payload: saved.toMap(),
      now: now,
    );
    notifyListeners();
    return saved;
  }
}

class EmployeeWorkTimeScope
    extends InheritedNotifier<EmployeeWorkTimeController> {
  const EmployeeWorkTimeScope({
    super.key,
    required EmployeeWorkTimeController controller,
    required super.child,
  }) : super(notifier: controller);

  static EmployeeWorkTimeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<EmployeeWorkTimeScope>();
    assert(scope != null, 'EmployeeWorkTimeScope was not found.');
    return scope!.notifier!;
  }

  static EmployeeWorkTimeController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<EmployeeWorkTimeScope>()
      ?.notifier;
}
