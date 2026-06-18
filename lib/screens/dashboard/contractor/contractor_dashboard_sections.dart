import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/industrial_panel.dart';
import 'contractor_dashboard_models.dart';

class ContractorModeSwitch extends StatelessWidget {
  const ContractorModeSwitch({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final ContractorDayMode mode;
  final ValueChanged<ContractorDayMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ContractorDayMode>(
      segments: const [
        ButtonSegment(
          value: ContractorDayMode.preDay,
          icon: Icon(Icons.wb_sunny_rounded),
          label: Text('Pre-Day'),
        ),
        ButtonSegment(
          value: ContractorDayMode.activeDay,
          icon: Icon(Icons.timer_rounded),
          label: Text('Active Day'),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (value) => onChanged(value.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.blue;
          return const Color(0xFF1B2428);
        }),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
      ),
    );
  }
}

class ContractorCommandHeader extends StatelessWidget {
  const ContractorCommandHeader({required this.mode, super.key});

  final ContractorDayMode mode;

  @override
  Widget build(BuildContext context) {
    final active = mode == ContractorDayMode.activeDay;
    return IndustrialPanel(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  label: 'Work Profile',
                  value: 'Independent Contractor',
                  icon: Icons.handyman_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderStat(
                  label: active ? 'Shift Status' : 'Day Status',
                  value: active ? 'Running' : 'Not Started',
                  icon: active ? Icons.timer_rounded : Icons.schedule_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            active
                ? 'Current job, mileage, materials, expenses, payments, and proof records stay tied to today.'
                : 'Review the day before rolling. Start from the vehicle, then work jobs, receipts, estimates, and material needs.',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

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
                  color: const Color(0xFF11191D),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: metric.color, width: 1.1),
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
                          color: Color(0xFFC7D0D4),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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

class ContractorActiveJobPanel extends StatelessWidget {
  const ContractorActiveJobPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: BorderLabel(
        label: 'Active Job',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Oak Street repair',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Truck 1 - Owner assigned - 14.2 miles logged - invoice draft open',
              style: TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Pause',
                    compact: true,
                    icon: const Icon(Icons.pause_rounded, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'End Day',
                    compact: true,
                    tone: AppButtonTone.destructive,
                    icon: const Icon(Icons.stop_rounded, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BorderLabel(
      label: label,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.yellow, size: 20),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
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
