// Source-owned manual work-time entry. GPS and Calendar may suggest review,
// but neither may silently create payable time through this screen.

import 'package:flutter/material.dart';

import '../../shared/calendar/app_date_picker.dart';
import '../../shared/profiles/employee_work_time_contract.dart';
import '../../shared/profiles/employee_work_time_store.dart';
import '../../shared/widgets/app_screen_shell.dart';

class EmployeeWorkTimeEntryScreen extends StatefulWidget {
  const EmployeeWorkTimeEntryScreen({
    super.key,
    required this.employeeId,
    this.initialDay,
  });

  final String employeeId;
  final DateTime? initialDay;

  @override
  State<EmployeeWorkTimeEntryScreen> createState() =>
      _EmployeeWorkTimeEntryScreenState();
}

class _EmployeeWorkTimeEntryScreenState
    extends State<EmployeeWorkTimeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hours = TextEditingController(text: '8');
  final _breakMinutes = TextEditingController(text: '0');
  final _vehicleIds = TextEditingController();
  final _workProfile = TextEditingController();
  final _jobId = TextEditingController();
  final _jobHours = TextEditingController();
  late DateTime _day;
  var _status = EmployeeWorkTimeStatus.draft;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDay ?? DateTime.now();
    _day = DateTime(initial.year, initial.month, initial.day);
  }

  @override
  void dispose() {
    _hours.dispose();
    _breakMinutes.dispose();
    _vehicleIds.dispose();
    _workProfile.dispose();
    _jobId.dispose();
    _jobHours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScreenShell(
    section: AppSection.dashboard,
    maxWidth: 640,
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
        children: [
          const GlobalOdometerHeader(section: AppSection.dashboard),
          const SizedBox(height: 8),
          const Text(
            'Record work time',
            style: TextStyle(
              color: Color(0xFFF0F4F5),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manual time is an employee record. It remains draft or submitted until the responsible reviewer approves it.',
            style: TextStyle(
              color: Color(0xFFB7C4CA),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Work date',
                  style: TextStyle(
                    color: Color(0xFFE2E8EA),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  _date(_day),
                  style: const TextStyle(color: Color(0xFFB7C4CA)),
                ),
                trailing: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF7CC7FF),
                ),
                onTap: _pickDay,
              ),
              _numberField(_hours, 'Paid hours', min: 0.01),
              _numberField(_breakMinutes, 'Unpaid break minutes', min: 0),
              DropdownButtonFormField<EmployeeWorkTimeStatus>(
                initialValue: _status,
                dropdownColor: const Color(0xFF263136),
                style: const TextStyle(color: Color(0xFFE2E8EA)),
                decoration: const InputDecoration(labelText: 'Save status'),
                items: const [
                  DropdownMenuItem(
                    value: EmployeeWorkTimeStatus.draft,
                    child: Text('Draft'),
                  ),
                  DropdownMenuItem(
                    value: EmployeeWorkTimeStatus.submitted,
                    child: Text('Submit for approval'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Panel(
            children: [
              _textField(
                _vehicleIds,
                'Vehicle IDs, comma-separated (optional)',
              ),
              _textField(_workProfile, 'Work profile ID (optional)'),
            ],
          ),
          const SizedBox(height: 10),
          _Panel(
            children: [
              const Text(
                'Optional job allocation',
                style: TextStyle(
                  color: Color(0xFFF0F4F5),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Use this only when the time belongs to one job. The full multi-job allocation editor follows this foundation.',
                style: TextStyle(
                  color: Color(0xFFB7C4CA),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _textField(_jobId, 'Job ID'),
              _numberField(_jobHours, 'Hours allocated to this job', min: 0),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Saving…' : 'Save time entry'),
          ),
        ],
      ),
    ),
  );

  Widget _textField(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      style: const TextStyle(color: Color(0xFFE2E8EA)),
      decoration: InputDecoration(labelText: label),
    ),
  );

  Widget _numberField(
    TextEditingController controller,
    String label, {
    required double min,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Color(0xFFE2E8EA)),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = double.tryParse(value?.trim() ?? '');
        if (parsed == null || !parsed.isFinite || parsed < min) {
          return 'Enter a value of at least $min.';
        }
        return null;
      },
    ),
  );

  Future<void> _pickDay() async {
    final picked = await showAppDatePicker(context: context, initialDate: _day);
    if (picked == null || !mounted) return;
    setState(() => _day = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final paidMinutes = (_number(_hours) * 60).round();
    final jobId = _jobId.text.trim();
    final jobMinutes = (_number(_jobHours) * 60).round();
    if (jobId.isEmpty != (jobMinutes == 0)) {
      _message('Enter both a Job ID and allocated hours, or leave both blank.');
      return;
    }
    if (jobMinutes > paidMinutes) {
      _message('Job allocation cannot exceed paid hours.');
      return;
    }
    setState(() => _saving = true);
    try {
      await EmployeeWorkTimeScope.of(context).save(
        EmployeeWorkTimeRecord(
          id: 'TIME-${DateTime.now().microsecondsSinceEpoch}',
          employeeId: widget.employeeId,
          workDate: _day,
          recordedAt: DateTime.now(),
          status: _status,
          revision: 0,
          manualPaidMinutes: paidMinutes,
          unpaidBreakMinutes: _number(_breakMinutes).round(),
          vehicleIds: _tokens(_vehicleIds.text),
          workProfileId: _emptyToNull(_workProfile.text),
          enteredByEmployeeId: widget.employeeId,
          jobAllocations: jobId.isEmpty
              ? const []
              : [
                  EmployeeWorkTimeAllocation(
                    jobId: jobId,
                    paidMinutes: jobMinutes,
                  ),
                ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      _message('Could not save time entry: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF1D282C),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF46565E)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

double _number(TextEditingController controller) =>
    double.tryParse(controller.text.trim()) ?? 0;
List<String> _tokens(String value) => value
    .split(',')
    .map((token) => token.trim())
    .where((token) => token.isNotEmpty)
    .toSet()
    .toList(growable: false);
String? _emptyToNull(String value) =>
    value.trim().isEmpty ? null : value.trim();
String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';
