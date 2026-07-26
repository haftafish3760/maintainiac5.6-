part of 'expense_settings_screen.dart';

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro();

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Text(
        'Set up the expense command center. The top three cards, quick buttons, and other categories here use the same category list as the add-expense button.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFE8ECEE),
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

class _CategorySettingsSection extends StatelessWidget {
  const _CategorySettingsSection({
    required this.title,
    required this.categories,
    required this.active,
    required this.onCategoryPressed,
  });

  final String title;
  final List<ExpenseCategoryDefinition> categories;
  final bool active;
  final void Function(ExpenseCategoryDefinition category, bool active)
  onCategoryPressed;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 520 ? 5 : 4;
          final tileWidth =
              (constraints.maxWidth - ((columns - 1) * 8)) / columns;
          return Wrap(
            spacing: 8,
            runSpacing: 12,
            children: [
              SizedBox(
                width: constraints.maxWidth,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              for (final category in categories)
                SizedBox(
                  width: tileWidth,
                  child: _SettingsIconTile(
                    category: category,
                    active: active,
                    onPressed: () => onCategoryPressed(category, active),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsIconTile extends StatelessWidget {
  const _SettingsIconTile({
    required this.category,
    required this.active,
    required this.onPressed,
  });

  final ExpenseCategoryDefinition category;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(5),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: category.gradient,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: category.gradient.last.withValues(alpha: .48),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                      const BoxShadow(
                        color: Color(0xAA000000),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _categoryInitials(category.label),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFD32222)
                          : const Color(0xFF28A745),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      active ? Icons.remove : Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFE8ECEE),
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryInitials(String label) {
    final words = label
        .split(RegExp(r'[\s/&-]+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return words.take(2).map((word) => word.characters.first).join();
  }
}
