part of 'work_supply_settings_screen.dart';

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro({required this.audit});

  final WorkSupplyCatalogAuditSummary audit;

  @override
  Widget build(BuildContext context) {
    return _SettingsPanel(
      title: 'Inventory Database',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${audit.itemCount} starter recognition nodes across ${audit.tradeCount} trades. Trade packs are local data sets for search, receipt review, and add-item suggestions.',
            style: const TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          _CatalogHealthStrip(audit: audit),
          const SizedBox(height: 10),
          _CatalogCoverageSummary(audit: audit),
        ],
      ),
    );
  }
}

class _CatalogCoverageSummary extends StatelessWidget {
  const _CatalogCoverageSummary({required this.audit});

  final WorkSupplyCatalogAuditSummary audit;

  @override
  Widget build(BuildContext context) {
    final weakest = audit.weakestTrades;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Parser coverage watchlist',
          style: TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        for (final trade in weakest) ...[
          _TradeCoverageRow(coverage: trade),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _TradeCoverageRow extends StatelessWidget {
  const _TradeCoverageRow({required this.coverage});

  final WorkSupplyCatalogTradeCoverage coverage;

  @override
  Widget build(BuildContext context) {
    final score = (coverage.parserReadinessScore * 100).round();
    final color = switch (coverage.parserReadinessLabel) {
      'Strong' => const Color(0xFF7EE0A1),
      'Needs aliases' => const Color(0xFFFFD166),
      _ => const Color(0xFFFF8A8A),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10171B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF34434A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              coverage.tradeName,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '${coverage.itemCount} items',
            style: const TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '$score%',
              style: const TextStyle(
                color: Color(0xFF07100A),
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogHealthStrip extends StatelessWidget {
  const _CatalogHealthStrip({required this.audit});

  final WorkSupplyCatalogAuditSummary audit;

  @override
  Widget build(BuildContext context) {
    final color = audit.passesCoreIntegrity
        ? const Color(0xFF7EE0A1)
        : const Color(0xFFFFD166);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _HealthPill(label: 'Stable IDs', value: audit.itemCount, color: color),
        _HealthPill(
          label: 'Duplicate IDs',
          value: audit.duplicateIdCount,
          color: audit.duplicateIdCount == 0
              ? const Color(0xFF7EE0A1)
              : const Color(0xFFFF8A8A),
        ),
        _HealthPill(
          label: 'Missing fields',
          value: audit.incompleteItemCount,
          color: audit.incompleteItemCount == 0
              ? const Color(0xFF7EE0A1)
              : const Color(0xFFFF8A8A),
        ),
      ],
    );
  }
}

class _HealthPill extends StatelessWidget {
  const _HealthPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF10171B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFFE8ECEE),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReceiptAssistPanel extends StatelessWidget {
  const _ReceiptAssistPanel({required this.settings});

  final WorkSupplyInventorySettingsController settings;

  @override
  Widget build(BuildContext context) {
    return _SettingsPanel(
      title: 'Receipt Entry',
      child: Column(
        children: [
          _SettingsSwitchRow(
            label: 'Use app-assisted receipt entry',
            detail:
                'The manual form remains available. Assistance can help identify receipt lines when we wire OCR/parser support in.',
            value: settings.appAssistedReceipts,
            onChanged: settings.setAppAssistedReceipts,
          ),
          const SizedBox(height: 8),
          _SettingsSwitchRow(
            label: 'Keep receipt assistance local only',
            detail:
                'Use device-side help first. Cloud parsing can be a separate opt-in later.',
            value: settings.localOnlyReceiptAssistance,
            onChanged: settings.setLocalOnlyReceiptAssistance,
          ),
        ],
      ),
    );
  }
}

class _CatalogVisibilityPanel extends StatelessWidget {
  const _CatalogVisibilityPanel({required this.settings});

  final WorkSupplyInventorySettingsController settings;

  @override
  Widget build(BuildContext context) {
    return _SettingsPanel(
      title: 'Trade Pack Visibility',
      child: Column(
        children: [
          _SettingsSwitchRow(
            label: 'Use only followed trade-pack paths',
            detail:
                'Use this when a company wants suggestions narrowed to the trades, categories, and items it actually tracks.',
            value: settings.showOnlyFollowedCatalog,
            onChanged: settings.setShowOnlyFollowedCatalog,
          ),
          const SizedBox(height: 8),
          _SettingsSwitchRow(
            label: 'Show hidden trade-pack items in settings',
            detail:
                'Turn this on when you need to unhide something that was removed from normal inventory browsing.',
            value: settings.showHiddenCatalogItems,
            onChanged: settings.setShowHiddenCatalogItems,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Reset followed and hidden trade-pack choices',
            tone: AppButtonTone.destructive,
            icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
            onPressed: settings.resetCatalogPreferences,
          ),
        ],
      ),
    );
  }
}

class _TradeSettingsPanel extends StatelessWidget {
  const _TradeSettingsPanel({
    required this.settings,
    required this.selectedTrade,
    required this.onSelectTrade,
  });

  final WorkSupplyInventorySettingsController settings;
  final String? selectedTrade;
  final ValueChanged<String> onSelectTrade;

  @override
  Widget build(BuildContext context) {
    return _SettingsPanel(
      title: 'Trades',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final trade in workSupplyTrades)
            _CatalogNodeButton(
              label: trade.name,
              count: _tradeItemCount(trade),
              selected: selectedTrade == trade.name,
              followed: settings.followsTrade(trade.name),
              hidden: settings.hidesTrade(trade.name),
              color: Color(trade.color.value),
              onTap: () => onSelectTrade(trade.name),
              onFollow: () => settings.setTradeFollowed(
                trade.name,
                !settings.followsTrade(trade.name),
              ),
              onHide: () => settings.setTradeHidden(
                trade.name,
                !settings.hidesTrade(trade.name),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySettingsPanel extends StatelessWidget {
  const _CategorySettingsPanel({required this.settings, required this.trade});

  final WorkSupplyInventorySettingsController settings;
  final String trade;

  @override
  Widget build(BuildContext context) {
    final definition = workSupplyTrades.firstWhere(
      (entry) => entry.name == trade,
    );
    return _SettingsPanel(
      title: '$trade Categories',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final category in definition.categories)
            _CatalogNodeButton(
              label: category.name,
              count: _categoryItemCount(category),
              selected: false,
              followed: settings.followsCategory(trade, category.name),
              hidden: settings.hidesCategory(trade, category.name),
              color: Color(definition.color.value),
              onTap: () => settings.setCategoryFollowed(
                trade,
                category.name,
                !settings.followsCategory(trade, category.name),
              ),
              onFollow: () => settings.setCategoryFollowed(
                trade,
                category.name,
                !settings.followsCategory(trade, category.name),
              ),
              onHide: () => settings.setCategoryHidden(
                trade,
                category.name,
                !settings.hidesCategory(trade, category.name),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemSettingsPanel extends StatelessWidget {
  const _ItemSettingsPanel({
    required this.settings,
    required this.controller,
    required this.onChanged,
  });

  final WorkSupplyInventorySettingsController settings;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final query = controller.text.trim();
    final items = query.isEmpty
        ? workSupplyCatalogItems.take(30).toList()
        : searchWorkSupplies(query);
    return _SettingsPanel(
      title: 'Item Follow And Hide',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            cursorColor: const Color(0xFFE8ECEE),
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0E1519),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFFC7D0D4),
              ),
              hintText: 'Search catalog item to follow or hide',
              hintStyle: const TextStyle(
                color: Color(0xFF8F9EA5),
                fontWeight: FontWeight.w700,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items.take(30)) ...[
            _ItemSettingsRow(settings: settings, item: item),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
