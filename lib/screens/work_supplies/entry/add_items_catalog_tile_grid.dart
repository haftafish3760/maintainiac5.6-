part of 'work_supply_add_items_screen.dart';

class _CatalogWizardTileGrid extends StatelessWidget {
  const _CatalogWizardTileGrid({
    required this.title,
    required this.detail,
    required this.choices,
    this.customField,
  });

  final String title;
  final String detail;
  final List<_CatalogWizardChoice> choices;
  final Widget? customField;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InlineSectionHeader(
          icon: Icons.inventory_2_outlined,
          title: title,
          detail: detail,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final hasImages = choices.any(
              (choice) => choice.imageAsset != null,
            );
            final columns = hasImages
                ? 3
                : constraints.maxWidth >= 520
                ? 4
                : 3;
            final spacing = hasImages ? 16.0 : 10.0;
            final width =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: hasImages ? 20 : 10,
              children: [
                for (final choice in choices)
                  SizedBox(
                    width: width,
                    child: _CatalogWizardTile(
                      choice: choice,
                      imageMode: hasImages,
                    ),
                  ),
              ],
            );
          },
        ),
        if (customField != null) ...[const SizedBox(height: 10), customField!],
      ],
    );
  }
}

class _CatalogWizardTile extends StatelessWidget {
  const _CatalogWizardTile({required this.choice, required this.imageMode});

  final _CatalogWizardChoice choice;
  final bool imageMode;

  @override
  Widget build(BuildContext context) {
    final imageAsset = choice.imageAsset;
    return InkWell(
      onTap: choice.onTap,
      borderRadius: BorderRadius.circular(13),
      child: imageMode && imageAsset != null
          ? Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              _CatalogWizardFallbackArt(color: choice.color),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: choice.color, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  height: 34,
                  child: Center(
                    child: Text(
                      choice.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : _CatalogWizardTextTile(choice: choice),
    );
  }
}

class _CatalogWizardTextTile extends StatelessWidget {
  const _CatalogWizardTextTile({required this.choice});

  final _CatalogWizardChoice choice;

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            choice.color.withValues(alpha: .33),
            const Color(0xFF10191E),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: choice.color.withValues(alpha: .82),
          width: 2,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x99000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
          BoxShadow(color: choice.color.withValues(alpha: .18), blurRadius: 8),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 104),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 11, 8, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 5,
                decoration: BoxDecoration(
                  color: choice.color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                choice.label,
                softWrap: true,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                choice.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFC7D0D4),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogWizardFallbackArt extends StatelessWidget {
  const _CatalogWizardFallbackArt({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: .72), const Color(0xFF062B57)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_rounded,
          color: const Color(0xFFE8ECEE).withValues(alpha: .86),
          size: 36,
        ),
      ),
    );
  }
}

Color _receiptTradeColor(String? trade) {
  return switch (trade) {
    'Plumbing' => const Color(0xFF2D7EA7),
    'Electrical' => const Color(0xFFF6B73C),
    'HVAC' => const Color(0xFF4EB7C4),
    'Carpentry' => const Color(0xFFB57742),
    'Insulation' => const Color(0xFFDF9A3A),
    'Drywall' => const Color(0xFF9AA3A8),
    'Painting' => const Color(0xFF66A6D8),
    'Roofing' => const Color(0xFF6D7A84),
    'Tile' => const Color(0xFF5FA58E),
    'Fencing' => const Color(0xFF8A704D),
    'Masonry and Concrete' => const Color(0xFFA77E55),
    'Landscaping' => const Color(0xFF4F9B59),
    'Low Voltage and Data' => const Color(0xFF8E72D8),
    'Tools and Safety' => const Color(0xFFD05D4B),
    _ => const Color(0xFF64C98A),
  };
}

String? _receiptTradeIconAsset(String trade) {
  return switch (trade) {
    'Plumbing' => 'assets/generated_trade_icons/plumbing.png',
    'Electrical' => 'assets/generated_trade_icons/electrical.png',
    'HVAC' => 'assets/generated_trade_icons/hvac.png',
    'Carpentry' => 'assets/generated_trade_icons/carpentry.png',
    'Drywall' => 'assets/generated_trade_icons/drywall.png',
    'Painting' => 'assets/generated_trade_icons/painting.png',
    'Roofing' => 'assets/generated_trade_icons/roofing.png',
    'Tile' => 'assets/generated_trade_icons/tile.png',
    'Insulation' => 'assets/generated_trade_icons/insulation.png',
    'Fencing' => 'assets/generated_trade_icons/fencing.png',
    'Masonry and Concrete' =>
      'assets/generated_trade_icons/masonry_concrete.png',
    'Landscaping' => 'assets/generated_trade_icons/landscaping.png',
    'Low Voltage and Data' =>
      'assets/generated_trade_icons/low_voltage_data.png',
    'Tools and Safety' => 'assets/generated_trade_icons/tools_safety.png',
    _ => null,
  };
}
