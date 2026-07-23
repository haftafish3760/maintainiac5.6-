part of 'maintenance_item_detail_screen.dart';

class _SetupSection extends StatelessWidget {
  const _SetupSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF182023),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF445159), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE7EEF1),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ItemIdentitySection extends StatelessWidget {
  const _ItemIdentitySection({required this.record});

  final MaintenanceRecord record;

  @override
  Widget build(BuildContext context) {
    final status = record.setupComplete
        ? _currentStatusText(record)
        : 'Not set up yet';
    final color = record.setupComplete
        ? _statusColor(record)
        : const Color(0xFFB8C4C8);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        children: [
          MaintenanceSvgIcon(itemName: record.itemName, size: 62),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.itemName,
                  style: const TextStyle(
                    color: Color(0xFFE7EEF1),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _currentStatusText(MaintenanceRecord record) {
    if (record.timeOnly) {
      return '${record.monthsRemaining} months remaining';
    }
    return '${_formatNumber(record.milesRemaining)} miles and '
        '${record.monthsRemaining} months remaining';
  }

  Color _statusColor(MaintenanceRecord record) {
    if (!record.thresholdsEnabled) return AppActionColors.primary;
    if (record.timeOnly) {
      if (record.monthsRemaining <= 1) return AppColors.red;
      if (record.monthsRemaining <= 3) return AppColors.orange;
      if (record.monthsRemaining <= 6) return AppColors.yellow;
      return AppActionColors.positive;
    }
    if (record.milesRemaining <= record.mileageRedAt) {
      return AppColors.red;
    }
    if (record.milesRemaining <= record.mileageOrangeAt) {
      return AppColors.orange;
    }
    if (record.milesRemaining <= record.mileageYellowAt) {
      return AppColors.yellow;
    }
    return AppActionColors.positive;
  }
}

class _ResponsiveTwoColumn extends StatelessWidget {
  const _ResponsiveTwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 10), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 10),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/${date.year}';
    return _FieldShell(
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF101416),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Color(0xFF101416),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF101416),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.field,
            contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: const BorderSide(color: Color(0xFF879299)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: const BorderSide(color: Color(0xFFE2E8EA), width: 2),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
          ),
          child: child,
        ),
        Positioned(
          left: 8,
          top: -8,
          child: Container(
            color: const Color(0xFF11181B),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFFF0F4F2),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdvancedDisclosure extends StatelessWidget {
  const _AdvancedDisclosure({required this.advanced, required this.onTap});

  final bool advanced;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF101719),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFF4C5A61)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              advanced
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFFE7EEF1),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  advanced ? 'Hide Advanced Details' : 'Show Advanced Details',
                  style: const TextStyle(
                    color: Color(0xFFE7EEF1),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailDropdown extends StatelessWidget {
  const _DetailDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = options.isEmpty ? ['Not specified', 'Other'] : options;
    final normalizedValue = value.trim().toLowerCase();
    final selected = items.firstWhere(
      (item) => item.trim().toLowerCase() == normalizedValue,
      orElse: () => items.first,
    );
    return _CompactDropdownField<String>(
      label: label,
      value: selected,
      items: items,
      itemLabel: (item) => item,
      onChanged: onChanged,
    );
  }
}

class _NextDueSection extends StatelessWidget {
  const _NextDueSection({required this.nextOdometer, required this.nextDate});

  final int? nextOdometer;
  final DateTime? nextDate;

  @override
  Widget build(BuildContext context) {
    return _SetupSection(
      title: 'Next Due Preview',
      child: _ResponsiveTwoColumn(
        left: _PreviewTile(
          label: 'Next Odometer',
          value: nextOdometer == null
              ? 'Time only'
              : '${_formatNumber(nextOdometer!)} miles',
        ),
        right: _PreviewTile(
          label: 'Next Date',
          value: nextDate == null
              ? 'Select interval'
              : '${nextDate!.month.toString().padLeft(2, '0')}/'
                    '${nextDate!.day.toString().padLeft(2, '0')}/${nextDate!.year}',
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1517),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF5D6A71)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE7EEF1),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
