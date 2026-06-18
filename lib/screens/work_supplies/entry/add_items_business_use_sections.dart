part of 'work_supply_add_items_screen.dart';

class _BusinessUsePicker extends StatelessWidget {
  const _BusinessUsePicker({
    required this.selected,
    required this.businessPercent,
    required this.onSelected,
    required this.onPercentChanged,
  });

  final _LineBusinessUse selected;
  final TextEditingController businessPercent;
  final ValueChanged<_LineBusinessUse> onSelected;
  final ValueChanged<String> onPercentChanged;

  @override
  Widget build(BuildContext context) {
    return _BorderPanel(
      label: 'This Line Counts As',
      surfaceColor: const Color(0xFF151B20),
      borderColor: const Color(0xFF50616B),
      labelColor: const Color(0xFFD6DEE2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Change this only when this line is different from the receipt choice above.',
            style: TextStyle(
              color: Color(0xFFD6DEE2),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 360;
              final itemWidth = narrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 3;
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final value in _LineBusinessUse.values)
                    SizedBox(
                      width: itemWidth,
                      child: _BusinessUseButton(
                        value: value,
                        selected: selected == value,
                        onTap: () => onSelected(value),
                      ),
                    ),
                ],
              );
            },
          ),
          if (selected == _LineBusinessUse.split) ...[
            const SizedBox(height: 9),
            _Field(
              controller: businessPercent,
              label: 'Business %',
              hint: 'Example: 60',
              keyboardType: TextInputType.number,
              onChanged: onPercentChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _BusinessUseButton extends StatelessWidget {
  const _BusinessUseButton({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final _LineBusinessUse value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (value) {
      _LineBusinessUse.business => const Color(0xFF63B3E6),
      _LineBusinessUse.personal => const Color(0xFFE0A7FF),
      _LineBusinessUse.split => const Color(0xFFFFD166),
    };
    return Material(
      color: selected ? const Color(0xFF202B31) : const Color(0xFF101417),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected ? color : const Color(0xFF46545C),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.label,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.detail,
                style: const TextStyle(
                  color: Color(0xFFC7D0D4),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
