import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/industrial_panel.dart';
import 'contractor_dashboard_models.dart';
import 'contractor_dashboard_tiles.dart';

class ContractorMetricsStrip extends StatelessWidget {
  const ContractorMetricsStrip({
    required this.metrics,
    required this.onMetricSelected,
    super.key,
  });

  final List<ContractorMetric> metrics;
  final ValueChanged<ContractorMetricTarget> onMetricSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: BorderLabel(
        label: 'Business Snapshot',
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisExtent: contractorMetricTileExtent(context),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final metric in metrics)
              ContractorMetricTile(
                metric: metric,
                onTap: metric.target == null
                    ? null
                    : () => onMetricSelected(metric.target!),
              ),
          ],
        ),
      ),
    );
  }
}

class ContractorScaleStrip extends StatelessWidget {
  const ContractorScaleStrip({required this.metrics, super.key});

  final List<ContractorMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF101719),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF5B6A70), width: 1.4),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          child: Row(
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: ContractorShiftReadout(
                    label: metrics[index].label,
                    value: metrics[index].value,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ContractorDayControlPanel extends StatelessWidget {
  const ContractorDayControlPanel({
    required this.dayStarted,
    required this.onStartDay,
    this.onOpenDay,
    this.onStartGps,
    super.key,
  });

  final bool dayStarted;
  final VoidCallback onStartDay;
  final VoidCallback? onOpenDay;
  final VoidCallback? onStartGps;

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
                          ? 'GPS assistance is optional. Start it here, or open the workday to pause, review, add stops, and end with the vehicle odometer.'
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
                SizedBox(
                  width: 180,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton(
                        label: 'Start GPS',
                        compact: true,
                        tone: AppButtonTone.commit,
                        icon: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                        ),
                        onPressed: onStartGps,
                      ),
                      const SizedBox(height: 6),
                      AppButton(
                        label: 'Open Workday',
                        compact: true,
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: onOpenDay,
                      ),
                    ],
                  ),
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

class ContractorAttentionPanel extends StatelessWidget {
  const ContractorAttentionPanel({required this.items, super.key});

  final List<ContractorAttentionItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: items.isEmpty
              ? const Color(0xFF0E2518)
              : const Color(0xFF2A170A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: items.isEmpty
                ? const Color(0xFF55D68A)
                : const Color(0xFFFFC44D),
            width: 1.6,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    items.isEmpty
                        ? Icons.check_circle_rounded
                        : Icons.priority_high_rounded,
                    color: items.isEmpty
                        ? const Color(0xFF55D68A)
                        : const Color(0xFFFFC44D),
                    size: 22,
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
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
              if (items.isEmpty)
                const Text(
                  'No expense or invoice records need attention right now.',
                  style: TextStyle(
                    color: Color(0xFFF1F7F3),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                for (final item in items) ...[
                  _AttentionRow(item: item),
                  if (item != items.last)
                    const Divider(height: 12, color: Color(0x66FFC44D)),
                ],
            ],
          ),
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
