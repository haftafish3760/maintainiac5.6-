import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/industrial_panel.dart';
import 'contractor_dashboard_models.dart';

class ContractorMetricsStrip extends StatelessWidget {
  const ContractorMetricsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final metric in contractorMetrics)
            SizedBox(
              width: 133,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F2),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: metric.color, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF172126),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        metric.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: metric.color,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ContractorStartDayPanel extends StatelessWidget {
  const ContractorStartDayPanel({required this.onStartDay, super.key});

  final VoidCallback onStartDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0E2518),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.green, width: 1.6),
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
                  children: const [
                    Text(
                      'Start Contractor Day',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Begin mileage, job tracking, receipts, materials, and invoices for this vehicle.',
                      style: TextStyle(
                        color: Color(0xFFE4F7E9),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                label: 'Start Day',
                tone: AppButtonTone.commit,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                onPressed: onStartDay,
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
      child: BorderLabel(
        label: 'Needs Attention',
        child: Column(
          children: [
            for (final item in contractorAttentionItems) ...[
              _AttentionRow(item: item),
              if (item != contractorAttentionItems.last)
                const Divider(height: 12, color: Color(0x668B9089)),
            ],
          ],
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
        label: 'Today Jobs',
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
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final command in commands)
            SizedBox(
              width: 133,
              child: _CommandTile(
                command: command,
                onTap: () => onCommand(command),
              ),
            ),
        ],
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
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.detail,
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
                color: Color(0xFFC7D0D4),
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

class _CommandTile extends StatelessWidget {
  const _CommandTile({required this.command, required this.onTap});

  final ContractorCommand command;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: command.color,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(command.icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  command.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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
