import 'package:flutter/material.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../calendar/work_supply_calendar_panel.dart';
import '../data/work_supply_models.dart';

part 'work_supply_jobs_sections.dart';
part 'work_supply_jobs_day_sections.dart';

class WorkSupplyJobsScreen extends StatefulWidget {
  const WorkSupplyJobsScreen({super.key});

  @override
  State<WorkSupplyJobsScreen> createState() => _WorkSupplyJobsScreenState();
}

class _WorkSupplyJobsScreenState extends State<WorkSupplyJobsScreen> {
  final _jobs = _demoJobs();
  late DateTime _selectedDay = _dayKey(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final selectedJobs = _jobsForDay(_selectedDay);
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
                _JobsHeader(jobCount: _jobs.length),
                const SizedBox(height: 10),
                _JobQuickActions(
                  onCreateJob: () {},
                  onLinkMileage: () {},
                  onAddExpense: () {},
                  onUseInventory: () {},
                ),
                const SizedBox(height: 10),
                _JobsCommandSummary(jobs: _jobs),
                const SizedBox(height: 10),
                for (final job in _jobs) _JobCard(job: job),
                const SizedBox(height: 3),
                _JobScheduleSection(
                  selectedDay: _selectedDay,
                  selectedJobs: selectedJobs,
                  allJobs: _jobs,
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

  List<WorkSupplyJob> _jobsForDay(DateTime day) {
    return _jobs.where((job) {
      final scheduledDate = job.scheduledDate;
      if (scheduledDate == null) return false;
      return _dayKey(scheduledDate) == day;
    }).toList();
  }
}
