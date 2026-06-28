part of 'maintenance_log_service_screen.dart';

class _LogSection extends StatelessWidget {
  const _LogSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaintenanceFormSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ManualItemNavigator extends StatelessWidget {
  const _ManualItemNavigator({
    required this.activeItem,
    required this.itemIndex,
    required this.itemCount,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenSetup,
  });

  final MaintenanceRecord activeItem;
  final int itemIndex;
  final int itemCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onOpenSetup;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF11191C),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF4B5960)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MaintenanceSvgIcon(itemName: activeItem.itemName, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item ${itemIndex + 1} of $itemCount',
                      style: const TextStyle(
                        color: Color(0xFFCAD2D5),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activeItem.itemName,
                      style: const TextStyle(
                        color: Color(0xFFE7EEF1),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onOpenSetup,
                child: const Text('Open Setup'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppButton(
                label: 'Previous Item',
                compact: true,
                onPressed: onPrevious,
              ),
              const Spacer(),
              AppButton(
                label: 'Next Item',
                compact: true,
                tone: AppButtonTone.commit,
                onPressed: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFCAD2D5),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
    );
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({required this.text, this.urgent = false});

  final String text;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final color = urgent ? AppColors.red : AppColors.orange;
    final textColor = urgent ? Colors.white : const Color(0xFF101416);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            urgent ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
            color: textColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedServiceSummary extends StatelessWidget {
  const _SelectedServiceSummary({
    required this.records,
    required this.onChangeItems,
  });

  final List<MaintenanceRecord> records;
  final VoidCallback? onChangeItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF11191C),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF3D4A50)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final record in records)
                  _SelectedServiceChip(label: record.itemName),
              ],
            ),
          ),
          if (onChangeItems != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onChangeItems, child: const Text('Change')),
          ],
        ],
      ),
    );
  }
}

class _SelectedServiceChip extends StatelessWidget {
  const _SelectedServiceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF23313A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF65747B)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _CompanionServicePrompt extends StatelessWidget {
  const _CompanionServicePrompt({
    required this.label,
    required this.actionLabel,
    required this.onPressed,
  });

  final String label;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11191C),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF4B5960)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFE2E8EA),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE2E8EA),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFCAD2D5),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceChoice extends StatelessWidget {
  const _ServiceChoice({
    required this.record,
    required this.selected,
    required this.onTap,
  });

  final MaintenanceRecord record;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Ink(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF173A26) : const Color(0xFF293237),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.green : const Color(0xFF647177),
            width: selected ? 2 : 1,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              MaintenanceSvgIcon(itemName: record.itemName, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  record.itemName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank,
                color: selected ? AppColors.green : const Color(0xFFE2E8EA),
              ),
            ],
          ),
        ),
      ),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.field,
            contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
          ),
          child: InkWell(
            onTap: onTap,
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
        ),
        Positioned(
          left: 8,
          right: 8,
          top: -8,
          child: StructuralBorderLabel(
            label: label,
            alignment: Alignment.centerLeft,
            maxWidthFactor: 0.62,
            backgroundColor: const Color(0xFF11181B),
            textColor: const Color(0xFFF0F4F2),
          ),
        ),
      ],
    );
  }
}
