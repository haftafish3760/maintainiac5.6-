import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/industrial_panel.dart';
import 'contractor_dashboard_models.dart';

class ContractorJobsPanel extends StatelessWidget {
  const ContractorJobsPanel({
    required this.jobs,
    required this.onOpenJobs,
    super.key,
  });

  final List<ContractorJobPreview> jobs;
  final VoidCallback onOpenJobs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: BorderLabel(
        label: 'Today Work Queue',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: 'View All Jobs',
                compact: true,
                icon: const Icon(
                  Icons.work_outline_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                onPressed: onOpenJobs,
              ),
            ),
            const SizedBox(height: 10),
            if (jobs.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No jobs are scheduled for today.',
                  style: TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              for (final job in jobs) ...[
                _ContractorJobRow(job: job),
                if (job != jobs.last)
                  const Divider(height: 12, color: Color(0x668B9089)),
              ],
          ],
        ),
      ),
    );
  }
}

class _ContractorJobRow extends StatelessWidget {
  const _ContractorJobRow({required this.job});

  final ContractorJobPreview job;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            job.time,
            style: const TextStyle(
              color: AppColors.yellow,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                job.summary,
                style: const TextStyle(
                  color: Color(0xFFC7D0D4),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          job.status,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
