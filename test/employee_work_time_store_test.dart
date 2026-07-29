import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/profiles/employee_work_time_contract.dart';
import 'package:maintaniac/shared/profiles/employee_work_time_store.dart';

void main() {
  test(
    'time store assigns increasing revisions and preserves original recorded time',
    () async {
      final store = EmployeeWorkTimeController.memory();
      final first = await store.save(
        _record(
          recordedAt: DateTime(2026, 7, 22, 9),
          status: EmployeeWorkTimeStatus.submitted,
        ),
      );
      final corrected = await store.save(
        _record(
          recordedAt: DateTime(2026, 7, 28, 9),
          status: EmployeeWorkTimeStatus.corrected,
          reason: 'Employee corrected missed break.',
        ),
      );

      expect(first.revision, 0);
      expect(corrected.revision, 1);
      expect(corrected.recordedAt, DateTime(2026, 7, 22, 9));
    },
  );

  test('locked time cannot be silently replaced', () async {
    final store = EmployeeWorkTimeController.memory();
    await store.save(_record(status: EmployeeWorkTimeStatus.locked));

    expect(
      () => store.save(_record(status: EmployeeWorkTimeStatus.approved)),
      throwsA(isA<StateError>()),
    );
  });
}

EmployeeWorkTimeRecord _record({
  DateTime? recordedAt,
  EmployeeWorkTimeStatus status = EmployeeWorkTimeStatus.draft,
  String? reason,
}) => EmployeeWorkTimeRecord(
  id: 'time-1',
  employeeId: 'employee-1',
  workDate: DateTime(2026, 7, 22),
  recordedAt: recordedAt ?? DateTime(2026, 7, 22, 9),
  status: status,
  revision: 0,
  manualPaidMinutes: 480,
  correctionReason: reason,
);
