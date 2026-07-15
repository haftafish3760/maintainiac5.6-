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
    final strings = MaintaniacLocalizations.of(context);
    final suppressed = settings.odometerPromptSuppressedCategories;
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.odometerPromptsByCategory,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            strings.odometerPromptExplanation,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.askForOdometerReading),
            subtitle: Text(strings.odometerStillManual),
            value: settings.odometerPromptEnabled,
            onChanged: settings.setOdometerPromptEnabled,
          ),
          const SizedBox(height: 8),
          Text(
            strings.askForTheseCategories,
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
