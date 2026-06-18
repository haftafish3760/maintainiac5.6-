part of 'expense_receipt_entry_screen.dart';

class _ReceiptParseReviewDetails extends StatelessWidget {
  const _ReceiptParseReviewDetails({
    required this.quality,
    required this.maintenanceHints,
  });

  final ExpenseReceiptParseQuality? quality;
  final List<ExpenseReceiptMaintenanceHint> maintenanceHints;

  @override
  Widget build(BuildContext context) {
    final quality = this.quality;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (quality != null) _ReceiptParseQualityRow(quality: quality),
        if (maintenanceHints.isNotEmpty) ...[
          if (quality != null) const SizedBox(height: 8),
          const _ReceiptMaintenanceHintHeader(),
          const SizedBox(height: 6),
          for (final hint in maintenanceHints.take(3)) ...[
            _ReceiptMaintenanceHintRow(hint: hint),
            if (hint != maintenanceHints.take(3).last)
              const SizedBox(height: 6),
          ],
        ],
      ],
    );
  }
}

class _ReceiptParseQualityRow extends StatelessWidget {
  const _ReceiptParseQualityRow({required this.quality});

  final ExpenseReceiptParseQuality quality;

  @override
  Widget build(BuildContext context) {
    final color = quality.label == 'Good'
        ? const Color(0xFF8EF6A4)
        : quality.label == 'Review'
        ? const Color(0xFFFFD166)
        : const Color(0xFFFF8FA3);
    return _ReceiptParseReviewBox(
      icon: Icons.fact_check_rounded,
      color: color,
      title: 'Receipt fill: ${quality.confidencePercentLabel} ${quality.label}',
      detail: quality.reasons.take(2).join(' '),
    );
  }
}

class _ReceiptMaintenanceHintHeader extends StatelessWidget {
  const _ReceiptMaintenanceHintHeader();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Possible maintenance details found. Nothing is logged to maintenance until you choose that later.',
      style: TextStyle(
        color: Color(0xFFC8D0D3),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: 0,
      ),
    );
  }
}

class _ReceiptMaintenanceHintRow extends StatelessWidget {
  const _ReceiptMaintenanceHintRow({required this.hint});

  final ExpenseReceiptMaintenanceHint hint;

  @override
  Widget build(BuildContext context) {
    final details = [
      if ((hint.detail ?? '').trim().isNotEmpty) hint.detail!.trim(),
      if ((hint.oilWeight ?? '').trim().isNotEmpty) hint.oilWeight!.trim(),
      if (hint.serviceOdometer != null) 'odo ${hint.serviceOdometer}',
      if (hint.dueOdometer != null) 'due ${hint.dueOdometer}',
      if (hint.intervalMiles != null) '${hint.intervalMiles} mi interval',
      if (hint.intervalMonths != null) '${hint.intervalMonths} mo interval',
    ];
    final color = hint.label == 'Good'
        ? const Color(0xFF8EF6A4)
        : hint.label == 'Review'
        ? const Color(0xFFFFD166)
        : const Color(0xFFFF8FA3);
    return _ReceiptParseReviewBox(
      icon: Icons.build_rounded,
      color: color,
      title:
          '${hint.itemName} - ${hint.serviceType} (${(hint.confidence * 100).round()}% ${hint.label})',
      detail: details.isEmpty
          ? hint.evidence.take(2).join(', ')
          : details.join(' | '),
    );
  }
}

class _ReceiptParseReviewBox extends StatelessWidget {
  const _ReceiptParseReviewBox({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1114),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: .55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                if (detail.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC8D0D3),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
