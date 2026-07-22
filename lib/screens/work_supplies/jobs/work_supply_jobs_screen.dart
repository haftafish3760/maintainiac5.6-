import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/context/operational_context_store.dart';
import '../../../shared/jobs/maintainiac_job_store.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../calendar/work_supply_calendar_panel.dart';
import '../data/work_supply_models.dart';

part 'work_supply_jobs_sections.dart';
part 'work_supply_jobs_day_sections.dart';
part 'work_supply_jobs_actions.dart';

class WorkSupplyJobsScreen extends StatefulWidget {
  const WorkSupplyJobsScreen({super.key});

  @override
  State<WorkSupplyJobsScreen> createState() => _WorkSupplyJobsScreenState();
}

class _WorkSupplyJobsScreenState extends State<WorkSupplyJobsScreen> {
  late DateTime _selectedDay = _dayKey(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final jobs = MaintainiacJobScope.of(
      context,
    ).activeJobs.map(_workSupplyJobFromRecord).toList(growable: false);
    final selectedJobs = _jobsForDay(jobs, _selectedDay);
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
                _JobsHeader(jobCount: jobs.length),
                const SizedBox(height: 10),
                _JobQuickActions(
                  onCreateJob: _beginCreateJob,
                  onLinkMileage: () {},
                  onAddExpense: () {},
                  onUseInventory: () {},
                ),
                const SizedBox(height: 10),
                _JobsCommandSummary(jobs: jobs),
                const SizedBox(height: 10),
                for (final job in jobs) _JobCard(job: job),
                const SizedBox(height: 3),
                _JobScheduleSection(
                  selectedDay: _selectedDay,
                  selectedJobs: selectedJobs,
                  allJobs: jobs,
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

  List<WorkSupplyJob> _jobsForDay(List<WorkSupplyJob> jobs, DateTime day) {
    return jobs.where((job) {
      final scheduledDate = job.scheduledDate;
      if (scheduledDate == null) return false;
      return _dayKey(scheduledDate) == day;
    }).toList();
  }
}
