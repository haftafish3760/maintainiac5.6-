part of 'expense_settings_screen.dart';

class _OdometerPromptSettingsPanel extends StatelessWidget {
  const _OdometerPromptSettingsPanel();

  @override
  Widget build(BuildContext context) {
    final strings = MaintaniacLocalizations.of(context);
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.expenseOdometerRequiredTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            strings.expenseOdometerRequiredExplanation,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
