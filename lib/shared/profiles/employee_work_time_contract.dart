// Employee work-time and gross-pay contract. Profiles own time and pay
// records; Calendar projects them read-only. Amounts are integer cents only.

enum EmployeeWorkTimeStatus {
  draft,
  submitted,
  approved,
  corrected,
  rejected,
  locked,
}

enum EmployeePayFrequency { weekly, biweekly, semimonthly, monthly }

class EmployeeWorkTimeAllocation {
  const EmployeeWorkTimeAllocation({
    required this.jobId,
    required this.paidMinutes,
  }) : assert(jobId != ''),
       assert(paidMinutes >= 0);

  final String jobId;
  final int paidMinutes;
}

class EmployeeWorkTimeRecord {
  EmployeeWorkTimeRecord({
    required this.id,
    required this.employeeId,
    required DateTime workDate,
    required this.recordedAt,
    required this.status,
    required this.revision,
    this.clockInAt,
    this.clockOutAt,
    this.manualPaidMinutes,
    this.unpaidBreakMinutes = 0,
    this.jobAllocations = const [],
    this.vehicleIds = const [],
    this.workProfileId,
    this.timezoneId,
    this.enteredByEmployeeId,
    this.approvedByEmployeeId,
    this.correctionReason,
    this.auditReference,
  }) : workDate = _dateOnly(workDate) {
    if (id.trim().isEmpty || employeeId.trim().isEmpty) {
      throw ArgumentError('Work-time IDs must not be empty.');
    }
    if (revision < 0 || unpaidBreakMinutes < 0) {
      throw ArgumentError(
        'Revision and unpaid break minutes must not be negative.',
      );
    }
    if (manualPaidMinutes != null && manualPaidMinutes! < 0) {
      throw ArgumentError.value(manualPaidMinutes, 'manualPaidMinutes');
    }
    if ((clockInAt == null) != (clockOutAt == null) &&
        manualPaidMinutes == null) {
      throw ArgumentError(
        'Clock-in/out must both be present unless a manual duration is supplied.',
      );
    }
    if (clockInAt != null && clockOutAt!.isBefore(clockInAt!)) {
      throw ArgumentError('Clock-out cannot be before clock-in.');
    }
    final allocated = jobAllocations.fold<int>(
      0,
      (total, allocation) => total + allocation.paidMinutes,
    );
    if (allocated > paidMinutes) {
      throw ArgumentError('Job allocation cannot exceed paid work time.');
    }
    final jobIds = jobAllocations.map((allocation) => allocation.jobId).toSet();
    if (jobIds.length != jobAllocations.length) {
      throw ArgumentError(
        'A job may have only one allocation per time record.',
      );
    }
    if (status == EmployeeWorkTimeStatus.corrected &&
        (correctionReason?.trim().isEmpty ?? true)) {
      throw ArgumentError('Corrected time requires a correction reason.');
    }
  }

  final String id;
  final String employeeId;
  final DateTime workDate;
  final DateTime recordedAt;
  final EmployeeWorkTimeStatus status;
  final int revision;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final int? manualPaidMinutes;
  final int unpaidBreakMinutes;
  final List<EmployeeWorkTimeAllocation> jobAllocations;
  final List<String> vehicleIds;
  final String? workProfileId;
  final String? timezoneId;
  final String? enteredByEmployeeId;
  final String? approvedByEmployeeId;
  final String? correctionReason;
  final String? auditReference;

  int get paidMinutes {
    final manual = manualPaidMinutes;
    if (manual != null) return manual;
    final start = clockInAt;
    final end = clockOutAt;
    if (start == null || end == null) return 0;
    final elapsed = end.difference(start).inMinutes - unpaidBreakMinutes;
    return elapsed < 0 ? 0 : elapsed;
  }

  int get unallocatedPaidMinutes =>
      paidMinutes -
      jobAllocations.fold<int>(
        0,
        (total, allocation) => total + allocation.paidMinutes,
      );

  bool get countsTowardGrossPay => switch (status) {
    EmployeeWorkTimeStatus.approved || EmployeeWorkTimeStatus.locked => true,
    _ => false,
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'employeeId': employeeId,
    'workDate': workDate.toIso8601String(),
    'recordedAt': recordedAt.toIso8601String(),
    'status': status.name,
    'revision': revision,
    'clockInAt': clockInAt?.toIso8601String(),
    'clockOutAt': clockOutAt?.toIso8601String(),
    'manualPaidMinutes': manualPaidMinutes,
    'unpaidBreakMinutes': unpaidBreakMinutes,
    'jobAllocations': [
      for (final allocation in jobAllocations)
        {'jobId': allocation.jobId, 'paidMinutes': allocation.paidMinutes},
    ],
    'vehicleIds': vehicleIds,
    'workProfileId': workProfileId,
    'timezoneId': timezoneId,
    'enteredByEmployeeId': enteredByEmployeeId,
    'approvedByEmployeeId': approvedByEmployeeId,
    'correctionReason': correctionReason,
    'auditReference': auditReference,
  };

  factory EmployeeWorkTimeRecord.fromMap(Map<dynamic, dynamic> map) {
    final status = EmployeeWorkTimeStatus.values.byName(
      _string(map['status'], fallback: EmployeeWorkTimeStatus.draft.name),
    );
    return EmployeeWorkTimeRecord(
      id: _string(map['id']),
      employeeId: _string(map['employeeId']),
      workDate: _date(map['workDate']) ?? DateTime.now(),
      recordedAt: _date(map['recordedAt']) ?? DateTime.now(),
      status: status,
      revision: _integer(map['revision']),
      clockInAt: _date(map['clockInAt']),
      clockOutAt: _date(map['clockOutAt']),
      manualPaidMinutes: _nullableInteger(map['manualPaidMinutes']),
      unpaidBreakMinutes: _integer(map['unpaidBreakMinutes']),
      jobAllocations: _allocations(map['jobAllocations']),
      vehicleIds: _strings(map['vehicleIds']),
      workProfileId: _nullableString(map['workProfileId']),
      timezoneId: _nullableString(map['timezoneId']),
      enteredByEmployeeId: _nullableString(map['enteredByEmployeeId']),
      approvedByEmployeeId: _nullableString(map['approvedByEmployeeId']),
      correctionReason: _nullableString(map['correctionReason']),
      auditReference: _nullableString(map['auditReference']),
    );
  }
}

class EmployeePayPeriod {
  EmployeePayPeriod({required this.start, required this.end}) {
    if (end.isBefore(start)) {
      throw ArgumentError('Pay-period end cannot be before its start.');
    }
  }

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    final day = _dateOnly(date);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}

class EmployeePayPeriodSchedule {
  EmployeePayPeriodSchedule({
    required this.frequency,
    required DateTime anchorStartDate,
  }) : anchorStartDate = _dateOnly(anchorStartDate);

  final EmployeePayFrequency frequency;
  final DateTime anchorStartDate;

  /// Builds a schedule from the employee-facing week-start preference.
  /// Monday is the product default, yielding a Monday-Sunday weekly period.
  ///
  /// This legacy fallback has a fixed historical anchor. A reference-relative
  /// biweekly anchor would flip an employee between the two payroll cycles as
  /// the current week changes. New employee profiles should persist their
  /// actual payroll-cycle anchor date instead.
  factory EmployeePayPeriodSchedule.fromWeekStart({
    required EmployeePayFrequency frequency,
    required String weekStart,
    required DateTime referenceDate,
  }) {
    final weekday = _weekdayForName(weekStart);
    return EmployeePayPeriodSchedule(
      frequency: frequency,
      anchorStartDate: DateTime(1970, 1, 5 + weekday - DateTime.monday),
    );
  }

  EmployeePayPeriod periodContaining(DateTime date) {
    final day = _dateOnly(date);
    return switch (frequency) {
      EmployeePayFrequency.weekly => _anchoredPeriod(day, 7),
      EmployeePayFrequency.biweekly => _anchoredPeriod(day, 14),
      EmployeePayFrequency.semimonthly => _semimonthlyPeriod(day),
      EmployeePayFrequency.monthly => EmployeePayPeriod(
        start: DateTime(day.year, day.month),
        end: DateTime(day.year, day.month + 1, 0),
      ),
    };
  }

  EmployeePayPeriod _anchoredPeriod(DateTime day, int intervalDays) {
    final delta = day.difference(anchorStartDate).inDays;
    final periodOffset = _floorDivide(delta, intervalDays) * intervalDays;
    final start = _addCalendarDays(anchorStartDate, periodOffset);
    return EmployeePayPeriod(
      start: start,
      end: _addCalendarDays(start, intervalDays - 1),
    );
  }

  EmployeePayPeriod _semimonthlyPeriod(DateTime day) {
    if (day.day <= 15) {
      return EmployeePayPeriod(
        start: DateTime(day.year, day.month, 1),
        end: DateTime(day.year, day.month, 15),
      );
    }
    return EmployeePayPeriod(
      start: DateTime(day.year, day.month, 16),
      end: DateTime(day.year, day.month + 1, 0),
    );
  }
}

int _weekdayForName(String value) => switch (value.trim().toLowerCase()) {
  'monday' => DateTime.monday,
  'tuesday' => DateTime.tuesday,
  'wednesday' => DateTime.wednesday,
  'thursday' => DateTime.thursday,
  'friday' => DateTime.friday,
  'saturday' => DateTime.saturday,
  'sunday' => DateTime.sunday,
  _ => throw ArgumentError.value(value, 'weekStart', 'Must be a weekday name.'),
};

class EmployeeGrossPaySummary {
  const EmployeeGrossPaySummary({
    required this.period,
    required this.approvedMinutes,
    required this.pendingMinutes,
    required this.grossPayCents,
  });

  final EmployeePayPeriod period;
  final int approvedMinutes;
  final int pendingMinutes;
  final int grossPayCents;

  double get approvedHours => approvedMinutes / 60;
  double get pendingHours => pendingMinutes / 60;
  double get grossPay => grossPayCents / 100;
}

class EmployeeGrossPayCalculator {
  const EmployeeGrossPayCalculator._();

  static EmployeeGrossPaySummary hourly({
    required Iterable<EmployeeWorkTimeRecord> records,
    required EmployeePayPeriod period,
    required int hourlyRateCents,
  }) {
    if (hourlyRateCents < 0) {
      throw ArgumentError.value(hourlyRateCents, 'hourlyRateCents');
    }
    var approvedMinutes = 0;
    var pendingMinutes = 0;
    for (final record in records) {
      if (!period.contains(record.workDate)) continue;
      if (record.countsTowardGrossPay) {
        approvedMinutes += record.paidMinutes;
      } else if (record.status != EmployeeWorkTimeStatus.rejected) {
        pendingMinutes += record.paidMinutes;
      }
    }
    return EmployeeGrossPaySummary(
      period: period,
      approvedMinutes: approvedMinutes,
      pendingMinutes: pendingMinutes,
      grossPayCents: (approvedMinutes * hourlyRateCents / 60).round(),
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _addCalendarDays(DateTime value, int days) =>
    DateTime(value.year, value.month, value.day + days);

int _floorDivide(int dividend, int divisor) {
  final quotient = dividend ~/ divisor;
  final remainder = dividend % divisor;
  return dividend < 0 && remainder != 0 ? quotient - 1 : quotient;
}

String _string(Object? value, {String fallback = ''}) =>
    value?.toString().trim().isEmpty ?? true
    ? fallback
    : value.toString().trim();

String? _nullableString(Object? value) {
  final result = _string(value);
  return result.isEmpty ? null : result;
}

DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(_string(value));
}

int _integer(Object? value) {
  if (value is int) return value < 0 ? 0 : value;
  return int.tryParse(_string(value)) ?? 0;
}

int? _nullableInteger(Object? value) => value == null ? null : _integer(value);

List<String> _strings(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .map(_string)
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

List<EmployeeWorkTimeAllocation> _allocations(Object? value) {
  if (value is! Iterable) return const [];
  final result = <EmployeeWorkTimeAllocation>[];
  for (final item in value) {
    if (item is! Map) continue;
    final jobId = _string(item['jobId']);
    if (jobId.isEmpty) continue;
    result.add(
      EmployeeWorkTimeAllocation(
        jobId: jobId,
        paidMinutes: _integer(item['paidMinutes']),
      ),
    );
  }
  return result;
}
