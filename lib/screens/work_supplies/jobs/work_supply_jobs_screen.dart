import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/context/operational_context_store.dart';
import '../../../shared/calendar/calendar_job_projection_adapter.dart';
import '../../../shared/jobs/maintainiac_job_store.dart';
import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../invoices/data/invoice_ledger_store.dart';
import '../../invoices/data/invoice_record.dart';
import '../calendar/work_supply_calendar_panel.dart';
import '../data/work_supply_models.dart';
import 'work_supply_estimate_picker_screen.dart';
import 'work_supply_job_form_models.dart';
import 'work_supply_job_form_screen.dart';
import 'work_supply_job_draft_mapping.dart';

part 'work_supply_jobs_sections.dart';
part 'work_supply_jobs_day_sections.dart';
part 'work_supply_jobs_actions.dart';

class WorkSupplyJobsScreen extends StatefulWidget {
  const WorkSupplyJobsScreen({super.key, this.initialDay});

  /// Optional Calendar handoff. Jobs owns creation and persistence; Calendar
  /// supplies only the selected business date.
  final DateTime? initialDay;

  @override
  State<WorkSupplyJobsScreen> createState() => _WorkSupplyJobsScreenState();
}

class _WorkSupplyJobsScreenState extends State<WorkSupplyJobsScreen> {
  late DateTime _selectedDay = _dayKey(widget.initialDay ?? DateTime.now());
  var _openingCreateJob = false;

  @override
  Widget build(BuildContext context) {
    final jobStore = MaintainiacJobScope.of(context);
    final jobs = jobStore.activeJobs
        .map(_workSupplyJobFromRecord)
        .toList(growable: false);
    final selectedJobs = _jobsForDay(jobStore, _selectedDay);
    return AppScreenShell(
      section: AppSection.materials,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
        children: [
          const GlobalOdometerHeader(section: AppSection.materials),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _JobsHeader(
                  jobCount: jobs.length,
                  onCreateJob: _beginCreateJob,
                ),
                const SizedBox(height: 10),
                _JobQuickActions(
                  onCreateJob: _beginCreateJob,
                  onImportEstimate: _beginImportEstimate,
                  onAddExpense: () => _showPendingConnection('Job expenses'),
                  onUseInventory: () =>
                      _showPendingConnection('Job inventory usage'),
                ),
                const SizedBox(height: 10),
                _JobsCommandSummary(jobs: jobs),
                const SizedBox(height: 10),
                for (final job in jobs) _JobCard(job: job),
                const SizedBox(height: 3),
                _JobScheduleSection(
                  selectedDay: _selectedDay,
                  selectedJobs: selectedJobs,
                  markersForDay: (day) => _jobMarkersForDay(jobStore, day),
                  onDaySelected: (day) {
                    setState(() => _selectedDay = _dayKey(day));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<WorkSupplyJob> _jobsForDay(
    MaintainiacJobController store,
    DateTime day,
  ) {
    final byId = {for (final record in store.activeJobs) record.id: record};
    return [
      for (final event in CalendarJobProjectionAdapter.eventsForDay(store, day))
        if (byId[event.sourceRecordId] case final record?)
          _workSupplyJobFromRecord(record),
    ];
  }

  List<WorkSupplyCalendarMarker> _jobMarkersForDay(
    MaintainiacJobController store,
    DateTime day,
  ) {
    final count = CalendarJobProjectionAdapter.eventsForDay(store, day).length;
    return count == 0
        ? const []
        : [
            WorkSupplyCalendarMarker(
              label: 'J',
              color: const Color(0xFF8FD3FF),
              count: count,
            ),
          ];
  }
}
