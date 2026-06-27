part of 'expense_settings_screen.dart';

class _RecapTileSettingsPanel extends StatelessWidget {
  const _RecapTileSettingsPanel({required this.settings});

  final ExpenseSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final groups = expenseRecapTileDefinitions
        .map((tile) => tile.group)
        .toSet()
        .toList(growable: false);
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recap Tiles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton.icon(
                  onPressed: settings.resetRecapTiles,
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Show Everything'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose which tiles appear on the Expense Recap screen.',
              style: TextStyle(
                color: Color(0xFFC8D0D3),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final group in groups) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 2),
                child: Text(
                  group,
                  style: const TextStyle(
                    color: Color(0xFFFFD166),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              for (final tile in expenseRecapTileDefinitions.where(
                (tile) => tile.group == group,
              ))
                SwitchListTile.adaptive(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: settings.recapTileVisible(tile.id),
                  onChanged: (value) =>
                      settings.setRecapTileVisible(tile.id, value),
                  title: Text(
                    tile.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
