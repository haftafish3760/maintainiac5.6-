import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import 'invoice_home_models.dart';

class InvoiceQuickActionGrid extends StatelessWidget {
  const InvoiceQuickActionGrid({
    required this.actions,
    required this.onSelected,
    super.key,
  });

  final List<InvoiceQuickAction> actions;
  final ValueChanged<InvoiceQuickActionType> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 16) / 3;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final action in actions)
              SizedBox(
                width: tileWidth.clamp(88.0, 128.0).toDouble(),
                child: _InvoiceQuickActionTile(
                  key: Key('invoice-quick-action-${action.action.name}'),
                  action: action,
                  onTap: () => onSelected(action.action),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InvoiceQuickActionTile extends StatelessWidget {
  const _InvoiceQuickActionTile({
    required this.action,
    required this.onTap,
    super.key,
  });

  final InvoiceQuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFF273033),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF7B8588)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x77000000),
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _glyphFor(action.iconName),
                    style: const TextStyle(fontSize: 30, height: 1),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvoiceStatusRail extends StatelessWidget {
  const InvoiceStatusRail({
    required this.metrics,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<InvoiceStatusMetric> metrics;
  final InvoiceStatusFilter selected;
  final ValueChanged<InvoiceStatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: metrics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final metric = metrics[index];
          final active = metric.filter == selected;
          return InvoiceStatusChip(
            key: Key('invoice-status-${metric.filter.name}'),
            metric: metric,
            active: active,
            onTap: () => onSelected(metric.filter),
          );
        },
      ),
    );
  }
}

class InvoiceStatusChip extends StatelessWidget {
  const InvoiceStatusChip({
    required this.metric,
    required this.active,
    required this.onTap,
    super.key,
  });

  final InvoiceStatusMetric metric;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 138,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF12384F) : const Color(0xFF242B2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.yellow : const Color(0xFF687275),
            width: active ? 1.8 : 1.1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              metric.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _statusColor(metric.filter, active),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              metric.detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(InvoiceStatusFilter filter, bool active) {
  return switch (filter) {
    InvoiceStatusFilter.paid => const Color(0xFF6BE58D),
    InvoiceStatusFilter.unpaid => const Color(0xFFFFC928),
    InvoiceStatusFilter.overdue => const Color(0xFFFF6B58),
    InvoiceStatusFilter.upcoming => const Color(0xFF7FB9FF),
    InvoiceStatusFilter.approved => const Color(0xFF6BE58D),
    InvoiceStatusFilter.sent => const Color(0xFF7FB9FF),
    InvoiceStatusFilter.draft => const Color(0xFFFFD166),
    InvoiceStatusFilter.all => active ? AppColors.yellow : Colors.white,
  };
}

class InvoiceMonthStrip extends StatelessWidget {
  const InvoiceMonthStrip({
    required this.monthLabel,
    required this.modeLabel,
    super.key,
  });

  final String monthLabel;
  final String modeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_month_rounded, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$modeLabel calendar: $monthLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          tooltip: 'Choose month',
          onPressed: () {},
          icon: const Icon(Icons.expand_more_rounded),
        ),
      ],
    );
  }
}

class InvoiceTimelineList extends StatelessWidget {
  const InvoiceTimelineList({required this.entries, super.key});

  final List<InvoiceTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No records match this view yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    }
    return Column(
      children: [for (final entry in entries) InvoiceTimelineRow(entry: entry)],
    );
  }
}

class InvoiceTimelineRow extends StatelessWidget {
  const InvoiceTimelineRow({required this.entry, super.key});

  final InvoiceTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Text(
                    '${entry.day.day}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(_month(entry.day), style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    entry.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.amount,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(entry.status, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _glyphFor(String iconName) {
  return switch (iconName) {
    'company' => '🏢',
    'client' => '👥',
    'payment' => '💵',
    'estimate' => '📝',
    'invoice' => '📄',
    _ => '📄',
  };
}

String _month(DateTime day) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return labels[day.month - 1];
}
