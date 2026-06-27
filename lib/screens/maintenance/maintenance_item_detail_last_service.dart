part of 'maintenance_item_detail_screen.dart';

enum _LastDateEntryMode { date, elapsed }

enum _LastOdometerEntryMode { reading, distance }

class _LastServiceEntrySection extends StatelessWidget {
  const _LastServiceEntrySection({
    required this.timeOnly,
    required this.dateMode,
    required this.odometerMode,
    required this.lastServiceDate,
    required this.lastServiceOdometer,
    required this.monthsSinceService,
    required this.milesSinceService,
    required this.onDateModeChanged,
    required this.onOdometerModeChanged,
    required this.onPickDate,
  });

  final bool timeOnly;
  final _LastDateEntryMode dateMode;
  final _LastOdometerEntryMode odometerMode;
  final DateTime lastServiceDate;
  final TextEditingController lastServiceOdometer;
  final TextEditingController monthsSinceService;
  final TextEditingController milesSinceService;
  final ValueChanged<_LastDateEntryMode> onDateModeChanged;
  final ValueChanged<_LastOdometerEntryMode> onOdometerModeChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SetupChoiceLabel('When was it last serviced?'),
        const SizedBox(height: 8),
        _ResponsiveTwoColumn(
          left: _SetupChoiceCard(
            title: 'Date of last service',
            selected: dateMode == _LastDateEntryMode.date,
            onTap: () => onDateModeChanged(_LastDateEntryMode.date),
            child: _DateButton(
              label: 'Service Date',
              date: lastServiceDate,
              onTap: onPickDate,
            ),
          ),
          right: _SetupChoiceCard(
            title: 'How long has it been?',
            selected: dateMode == _LastDateEntryMode.elapsed,
            onTap: () => onDateModeChanged(_LastDateEntryMode.elapsed),
            child: RecordTextField(
              label: 'Months Since Service',
              controller: monthsSinceService,
              keyboardType: TextInputType.number,
            ),
          ),
        ),
        if (!timeOnly) ...[
          const SizedBox(height: 14),
          const _SetupChoiceLabel('What mileage do you know?'),
          const SizedBox(height: 8),
          _ResponsiveTwoColumn(
            left: _SetupChoiceCard(
              title: 'Odometer reading',
              selected: odometerMode == _LastOdometerEntryMode.reading,
              onTap: () =>
                  onOdometerModeChanged(_LastOdometerEntryMode.reading),
              child: RecordTextField(
                label: 'Last Service Odometer',
                controller: lastServiceOdometer,
                keyboardType: TextInputType.number,
              ),
            ),
            right: _SetupChoiceCard(
              title: 'Estimated miles since',
              selected: odometerMode == _LastOdometerEntryMode.distance,
              onTap: () =>
                  onOdometerModeChanged(_LastOdometerEntryMode.distance),
              child: RecordTextField(
                label: 'Miles Since Service',
                controller: milesSinceService,
                keyboardType: TextInputType.number,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SetupChoiceLabel extends StatelessWidget {
  const _SetupChoiceLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFE7EEF1),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        height: 1.15,
      ),
    );
  }
}

class _SetupChoiceCard extends StatelessWidget {
  const _SetupChoiceCard({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? AppActionColors.positive
        : const Color(0xFF4C5A61);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Ink(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF152D20) : const Color(0xFF101719),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: border, width: selected ? 1.4 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: border,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE7EEF1),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            IgnorePointer(ignoring: !selected, child: child),
          ],
        ),
      ),
    );
  }
}
