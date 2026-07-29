// Source-owned work-time detail. Calendar links here instead of editing time
// through a generic calendar form.

import 'package:flutter/material.dart';

import '../../shared/profiles/employee_work_time_contract.dart';
import '../../shared/profiles/employee_work_time_store.dart';
import '../../shared/widgets/app_screen_shell.dart';

class EmployeeWorkTimeDetailScreen extends StatelessWidget {
  const EmployeeWorkTimeDetailScreen({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    final record = EmployeeWorkTimeScope.of(context).recordById(recordId);
    if (record == null) return const _MissingWorkTimeScreen();
    return AppScreenShell(
      section: AppSection.dashboard,
      maxWidth: 680,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
        children: [
          const GlobalOdometerHeader(section: AppSection.dashboard),
          const SizedBox(height: 8),
          const _Title('Work time record'),
          const SizedBox(height: 10),
          _Section('Time and review status', [
            _Row('Work date', _date(record.workDate)),
            _Row('Status', _status(record.status)),
            _Row('Paid time', _hours(record.paidMinutes)),
            _Row('Unpaid break', '${record.unpaidBreakMinutes} minutes'),
            _Row('Clock in', _dateTimeOr(record.clockInAt, 'Not clocked')),
            _Row('Clock out', _dateTimeOr(record.clockOutAt, 'Not clocked')),
          ]),
          _Section('People, work, and vehicles', [
            _Row('Employee', record.employeeId),
            _Row(
              'Work profile',
              _valueOr(record.workProfileId, 'Not assigned'),
            ),
            _Row(
              'Vehicles',
              _listOr(record.vehicleIds, 'No vehicles assigned'),
            ),
            _Row('Unallocated time', _hours(record.unallocatedPaidMinutes)),
          ]),
          _Section('Job allocations', [
            if (record.jobAllocations.isEmpty)
              const _Row('Allocations', 'No job allocation recorded')
            else
              for (final allocation in record.jobAllocations)
                _Row(allocation.jobId, _hours(allocation.paidMinutes)),
          ]),
          _Section('Audit and pay handling', [
            _Row('Recorded', _dateTimeOr(record.recordedAt, 'Unknown')),
            _Row('Revision', record.revision.toString()),
            _Row(
              'Entered by',
              _valueOr(record.enteredByEmployeeId, 'Not recorded'),
            ),
            _Row(
              'Approved by',
              _valueOr(record.approvedByEmployeeId, 'Not approved'),
            ),
            _Row(
              'Correction reason',
              _valueOr(record.correctionReason, 'None'),
            ),
            _Row('Audit reference', _valueOr(record.auditReference, 'None')),
          ]),
        ],
      ),
    );
  }
}

class _MissingWorkTimeScreen extends StatelessWidget {
  const _MissingWorkTimeScreen();

  @override
  Widget build(BuildContext context) => const AppScreenShell(
    section: AppSection.dashboard,
    body: Center(
      child: Text(
        'This work-time record is no longer available.',
        style: TextStyle(color: Color(0xFFE2E8EA), fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Text(
    value,
    style: const TextStyle(
      color: Color(0xFFF0F4F5),
      fontSize: 22,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.rows);
  final String title;
  final List<_Row> rows;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF1D282C),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF46565E)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFF0F4F5),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        for (final row in rows) row,
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF9DB0B8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE2E8EA),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

String _valueOr(String? value, String fallback) =>
    value?.trim().isEmpty ?? true ? fallback : value!.trim();
String _listOr(List<String> values, String fallback) =>
    values.isEmpty ? fallback : values.join(', ');
String _hours(int minutes) => '${(minutes / 60).toStringAsFixed(2)} hours';
String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';
String _dateTimeOr(DateTime? value, String fallback) => value == null
    ? fallback
    : '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _status(EmployeeWorkTimeStatus status) =>
    status.name[0].toUpperCase() + status.name.substring(1);
