part of 'work_supply_settings_screen.dart';

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro({required this.itemCount, required this.tradeCount});

  final int itemCount;
  final int tradeCount;

  @override
  Widget build(BuildContext context) {
    return _SettingsPanel(
      title: 'Inventory Database',
      child: Text(
        '$itemCount starter recognition nodes across $tradeCount trades. Trade packs are local data sets for search, receipt review, and add-item suggestions. They are not a screen the user has to browse.',
        style: const TextStyle(
          color: Color(0xFFC7D0D4),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.35,
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
              color: trade.color,
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
              color: definition.color,
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
