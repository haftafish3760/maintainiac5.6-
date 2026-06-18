import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/industrial_panel.dart';
import 'contractor_dashboard_models.dart';
import 'contractor_dashboard_tiles.dart';

class ContractorMetricsStrip extends StatelessWidget {
  const ContractorMetricsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: BorderLabel(
        label: 'Business Snapshot',
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 2.45,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final metric in contractorMetrics)
              ContractorMetricTile(metric: metric),
          ],
        ),
      ),
    );
  }
}

class ContractorDayControlPanel extends StatelessWidget {
  const ContractorDayControlPanel({
    required this.dayStarted,
    required this.onStartDay,
    super.key,
  });

  final bool dayStarted;
  final VoidCallback onStartDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dayStarted ? const Color(0xFF1E1010) : const Color(0xFF0E2518),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: dayStarted ? const Color(0xFFE3342F) : AppColors.green,
            width: 1.7,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 9,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayStarted ? 'Day Controls' : 'Start Contractor Day',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayStarted
                          ? 'Pause the shift, end the day, or keep adding job records above.'
                          : 'Begin mileage, jobs, receipts, materials, and invoices for this vehicle.',
                      style: const TextStyle(
                        color: Color(0xFFF1F7F3),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (dayStarted)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: 'Pause Day',
                      compact: true,
                      icon: const Icon(
                        Icons.pause_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 7),
                    AppButton(
                      label: 'End Day',
                      compact: true,
                      tone: AppButtonTone.destructive,
                      icon: const Icon(Icons.stop_rounded, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                )
              else
                AppButton(
                  label: 'Start Day',
                  tone: AppButtonTone.commit,
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  onPressed: onStartDay,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContractorActiveShiftPanel extends StatelessWidget {
  const ContractorActiveShiftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF081A22),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF4DA3FF), width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x77000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_rounded, color: Color(0xFF7CC7FF), size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Active Contractor Day',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Oak Street repair is active. Add stops, notes, expenses, receipts, materials, invoices, and payments from here.',
                style: TextStyle(
                  color: Color(0xFFE6F5FF),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(
                    child: ContractorShiftReadout(
                      label: 'Shift Time',
                      value: '00:00',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ContractorShiftReadout(
                      label: 'Miles Today',
                      value: '14.2',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ContractorShiftReadout(
                      label: 'Current Job',
                      value: '1',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContractorAttentionPanel extends StatelessWidget {
  const ContractorAttentionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2A170A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFFC44D), width: 1.6),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.priority_high_rounded,
                    color: Color(0xFFFFC44D),
                    size: 22,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Needs Attention',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final item in contractorAttentionItems) ...[
                _AttentionRow(item: item),
                if (item != contractorAttentionItems.last)
                  const Divider(height: 12, color: Color(0x66FFC44D)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ContractorJobsPanel extends StatelessWidget {
  const ContractorJobsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: BorderLabel(
        label: 'Today Work Queue',
        child: Column(
          children: [
            for (final job in contractorJobsToday) ...[
              _JobRow(job: job),
              if (job != contractorJobsToday.last)
                const Divider(height: 12, color: Color(0x668B9089)),
            ],
          ],
        ),
      ),
    );
  }
}

class ContractorCommandGrid extends StatelessWidget {
  const ContractorCommandGrid({
    required this.commands,
    required this.onCommand,
    super.key,
  });

  final List<ContractorCommand> commands;
  final ValueChanged<ContractorCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: BorderLabel(
        label: 'Quick Actions',
        child: GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1.18,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final command in commands)
              ContractorCommandTile(
                command: command,
                onTap: () => onCommand(command),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});

  final ContractorAttentionItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(item.icon, color: item.color, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.detail,
                style: const TextStyle(
                  color: Color(0xFFFFE5B8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});

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
                job.customer,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              job.amount,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              job.status,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
