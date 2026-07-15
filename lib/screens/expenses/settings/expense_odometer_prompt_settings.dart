part of 'expense_settings_screen.dart';

class _OdometerPromptSettingsPanel extends StatelessWidget {
  const _OdometerPromptSettingsPanel({
    required this.settings,
    required this.categories,
  });

  final ExpenseSettingsController settings;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    final suppressed = settings.odometerPromptSuppressedCategories;
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Odometer Prompts By Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'An odometer reading is always optional. Choose which expense categories should ask before you record the expense.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ask for an odometer reading'),
            subtitle: const Text('You can still enter a reading manually.'),
            value: settings.odometerPromptEnabled,
            onChanged: settings.setOdometerPromptEnabled,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask for these categories',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                FilterChip(
                  label: Text(category),
                  selected: !suppressed.any(
                    (item) => item.toLowerCase() == category.toLowerCase(),
                  ),
                  onSelected: (askForCategory) => settings
                      .setOdometerPromptSuppressed(category, !askForCategory),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
