part of 'expense_settings_screen.dart';

class _TopThreeSettingsPanel extends StatelessWidget {
  const _TopThreeSettingsPanel({
    required this.categories,
    required this.autoTrackTopThree,
    required this.onAutoTrackChanged,
  });

  final List<ExpenseCategoryDefinition> categories;
  final bool autoTrackTopThree;
  final ValueChanged<bool> onAutoTrackChanged;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Top Three',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _SettingsTopThreeStrip(categories: categories),
          const SizedBox(height: 10),
          _AutoTopThreeToggleCopy(
            value: autoTrackTopThree,
            onChanged: onAutoTrackChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsTopThreeStrip extends StatelessWidget {
  const _SettingsTopThreeStrip({required this.categories});

  final List<ExpenseCategoryDefinition> categories;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < categories.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _SettingsTopThreeCard(
              label: categories[index].label,
              business: r'$0.00',
              personal: r'$0.00',
              color: categories[index].gradient.first,
            ),
          ),
        ],
      ],
    );
  }
}

class _SettingsTopThreeCard extends StatelessWidget {
  const _SettingsTopThreeCard({
    required this.label,
    required this.business,
    required this.personal,
    required this.color,
  });

  final String label;
  final String business;
  final String personal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF101416),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          _SettingsTopThreeLine(label: 'Business', value: business),
          const SizedBox(height: 4),
          _SettingsTopThreeLine(label: 'Personal', value: personal),
        ],
      ),
    );
  }
}

class _SettingsTopThreeLine extends StatelessWidget {
  const _SettingsTopThreeLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFD166),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AutoTopThreeToggleCopy extends StatelessWidget {
  const _AutoTopThreeToggleCopy({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101416),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF66737A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD166)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Allow Maintainiac to automatically track your top three expense categories.',
              style: TextStyle(fontWeight: FontWeight.w800, height: 1.2),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
