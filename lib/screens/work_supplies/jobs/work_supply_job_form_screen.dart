import 'package:flutter/material.dart';

import '../../../shared/calendar/app_date_picker.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_button.dart';
import 'work_supply_job_form_models.dart';

part 'work_supply_job_form_actions.dart';
part 'work_supply_job_form_sections.dart';

class WorkSupplyJobFormScreen extends StatefulWidget {
  const WorkSupplyJobFormScreen({
    super.key,
    required this.initialDay,
    this.initialDraft,
  });

  final DateTime initialDay;
  final WorkSupplyJobDraft? initialDraft;

  @override
  State<WorkSupplyJobFormScreen> createState() =>
      _WorkSupplyJobFormScreenState();
}

class _WorkSupplyJobFormScreenState extends State<WorkSupplyJobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _clientName = TextEditingController();
  final _clientPhone = TextEditingController();
  final _clientEmail = TextEditingController();
  final _serviceAddress = TextEditingController();
  final _notes = TextEditingController();

  late DateTime _scheduledDay;
  var _startTime = const TimeOfDay(hour: 8, minute: 0);
  var _endTime = const TimeOfDay(hour: 9, minute: 0);
  var _scheduleJob = true;
  var _repeatRule = JobRepeatRule.none;
  var _inAppReminder = false;
  var _pushReminder = false;
  var _soundReminder = false;
  var _reminderLeadMinutes = 60;
  var _dirty = false;

  List<TextEditingController> get _controllers => [
    _name,
    _clientName,
    _clientPhone,
    _clientEmail,
    _serviceAddress,
    _notes,
  ];

  @override
  void initState() {
    super.initState();
    _scheduledDay = DateTime(
      widget.initialDay.year,
      widget.initialDay.month,
      widget.initialDay.day,
    );
    final initial = widget.initialDraft;
    if (initial != null) {
      _name.text = initial.name;
      _clientName.text = initial.clientName;
      _clientPhone.text = initial.clientPhone;
      _clientEmail.text = initial.clientEmail;
      _serviceAddress.text = initial.serviceAddress;
      _notes.text = initial.notes;
    }
    for (final controller in _controllers) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..removeListener(_markDirty)
        ..dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  void _change(VoidCallback update) {
    setState(() {
      update();
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _requestClose();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundBottom,
        body: SafeArea(
          child: Column(
            children: [
              AppScreenHeader(title: 'Create Job', onBack: _requestClose),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _intro(),
                      const SizedBox(height: 10),
                      _section(
                        title: 'Job',
                        children: [
                          _field(
                            controller: _name,
                            label: 'Job name *',
                            hint: 'Water heater replacement',
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter a job name.'
                                : null,
                          ),
                          _field(
                            controller: _notes,
                            label: 'Scope and notes',
                            hint:
                                'Work requested, access notes, quoted scope, and special instructions',
                            maxLines: 4,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _section(
                        title: 'Client and service location',
                        children: [
                          _field(controller: _clientName, label: 'Client name'),
                          _field(
                            controller: _clientPhone,
                            label: 'Phone',
                            keyboardType: TextInputType.phone,
                          ),
                          _field(
                            controller: _clientEmail,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: _optionalEmailValidator,
                          ),
                          _field(
                            controller: _serviceAddress,
                            label: 'Service address',
                            hint: 'Street, unit, city, state, postal code',
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _scheduleSection(),
                      const SizedBox(height: 10),
                      _reminderSection(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Cancel',
                              tone: AppButtonTone.destructive,
                              onPressed: _requestClose,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              label: 'Save Job',
                              tone: AppButtonTone.commit,
                              onPressed: _save,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
