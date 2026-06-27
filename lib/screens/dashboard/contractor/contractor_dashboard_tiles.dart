import 'package:flutter/material.dart';

import 'contractor_dashboard_models.dart';

class ContractorMetricTile extends StatelessWidget {
  const ContractorMetricTile({required this.metric, super.key});

  final ContractorMetric metric;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF050909),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: metric.color, width: 1.7),
        boxShadow: [
          BoxShadow(
            color: metric.color.withValues(alpha: 0.18),
            blurRadius: 9,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFC9D1D4),
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
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractorShiftReadout extends StatelessWidget {
  const ContractorShiftReadout({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FA),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF7CC7FF), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF10202A),
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0E4F78),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractorCommandTile extends StatelessWidget {
  const ContractorCommandTile({
    required this.command,
    required this.onTap,
    super.key,
  });

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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(command.icon, color: Colors.white, size: 24),
              const SizedBox(height: 5),
              Flexible(
                child: Text(
                  command.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
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
