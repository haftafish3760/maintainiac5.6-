part of 'work_supply_settings_screen.dart';

class _TradePackDownloadsPanel extends StatelessWidget {
  const _TradePackDownloadsPanel({
    required this.settings,
    required this.runtimeContext,
    required this.selectedTrade,
    required this.onSelectTrade,
  });

  final WorkSupplyInventorySettingsController settings;
  final _TradePackRuntimeContext? runtimeContext;
  final String selectedTrade;
  final ValueChanged<String> onSelectTrade;

  @override
  Widget build(BuildContext context) {
    final fullCatalogOption = buildFullWorkSupplyTradePackOption();
    final allOptions = buildAllWorkSupplyDownloadOptions();
    final summaries = buildWorkSupplyTradePackSummaries();
    final selectedSummary = summaries.firstWhere(
      (summary) => summary.tradeName == selectedTrade,
      orElse: () => summaries.first,
    );
    final selectedOptions = buildWorkSupplyTradePackOptions(
      selectedSummary.tradeName,
    );
    final installedCount = allOptions
        .where(settings.hasInstalledTradePackOption)
        .length;
    return _SettingsPanel(
      title: 'Trade Pack Downloads',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Install only the trade data this device needs. Packs help search, receipt review, and add-item suggestions without loading every trade into the base app.',
            style: const TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$installedCount of ${allOptions.length} pack choices marked for this device.',
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Whole catalog',
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          _TradePackOptionRow(
            settings: settings,
            runtimeContext: runtimeContext,
            option: fullCatalogOption,
          ),
          const SizedBox(height: 12),
          _TradePackSelector(
            summaries: summaries,
            selectedTrade: selectedSummary.tradeName,
            installedKeys: settings.installedTradePackOptions,
            onSelectTrade: onSelectTrade,
          ),
          const SizedBox(height: 10),
          _SelectedTradePackSummary(summary: selectedSummary),
          const SizedBox(height: 8),
          for (final option in selectedOptions) ...[
            _TradePackOptionRow(
              settings: settings,
              runtimeContext: runtimeContext,
              option: option,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TradePackRuntimeContext {
  const _TradePackRuntimeContext({
    required this.availableStorageBytes,
    required this.deviceProfile,
    required this.isMeteredNetwork,
    required this.networkVerified,
  });

  final int? availableStorageBytes;
  final WorkSupplyParserDeviceProfile deviceProfile;
  final bool isMeteredNetwork;
  final bool networkVerified;
}

class _TradePackSelector extends StatelessWidget {
  const _TradePackSelector({
    required this.summaries,
    required this.selectedTrade,
    required this.installedKeys,
    required this.onSelectTrade,
  });

  final List<WorkSupplyTradePackTradeSummary> summaries;
  final String selectedTrade;
  final Set<String> installedKeys;
  final ValueChanged<String> onSelectTrade;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final summary in summaries)
          _TradePackSelectorChip(
            summary: summary,
            selected: summary.tradeName == selectedTrade,
            installedCount: _installedCountFor(summary.tradeName),
            onTap: () => onSelectTrade(summary.tradeName),
          ),
      ],
    );
  }

  int _installedCountFor(String tradeName) {
    final prefix = '${workSupplyTradePackTradeKey(tradeName)}:';
    return installedKeys.where((key) => key.startsWith(prefix)).length;
  }
}

class _TradePackSelectorChip extends StatelessWidget {
  const _TradePackSelectorChip({
    required this.summary,
    required this.selected,
    required this.installedCount,
    required this.onTap,
  });

  final WorkSupplyTradePackTradeSummary summary;
  final bool selected;
  final int installedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF53656D);
    final fill = selected ? const Color(0xFF254234) : const Color(0xFF111B20);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.tradeName,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${summary.itemCount} items',
                style: const TextStyle(
                  color: Color(0xFFC7D0D4),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              if (installedCount > 0) ...[
                const SizedBox(height: 3),
                Text(
                  '$installedCount installed',
                  style: const TextStyle(
                    color: Color(0xFF7EE0A1),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedTradePackSummary extends StatelessWidget {
  const _SelectedTradePackSummary({required this.summary});

  final WorkSupplyTradePackTradeSummary summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F191E),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF53656D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _HealthPill(
              label: 'Pack choices',
              value: summary.optionCount,
              color: const Color(0xFF7EE0A1),
            ),
            _HealthPill(
              label: 'Full items',
              value: summary.itemCount,
              color: const Color(0xFF7EE0A1),
            ),
            Text(
              'Full pack: ${summary.estimatedSizeLabel}',
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TradePackOptionRow extends StatelessWidget {
  const _TradePackOptionRow({
    required this.settings,
    required this.runtimeContext,
    required this.option,
  });

  final WorkSupplyInventorySettingsController settings;
  final _TradePackRuntimeContext? runtimeContext;
  final WorkSupplyTradePackOption option;

  @override
  Widget build(BuildContext context) {
    final marked = settings.hasInstalledTradePackOption(option);
    final manifest = buildWorkSupplyTradePackManifest(option);
    final runtime = runtimeContext;
    final installCheck = runtime == null
        ? null
        : checkWorkSupplyTradePackInstall(
            option: option,
            availableStorageBytes: runtime.availableStorageBytes,
            isMeteredNetwork: runtime.isMeteredNetwork,
            deviceProfile: runtime.deviceProfile,
          );
    final borderColor = marked
        ? const Color(0xFF7EE0A1)
        : const Color(0xFF53656D);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: marked ? const Color(0xFF10251A) : const Color(0xFF111B20),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    option.displayName,
                    softWrap: true,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  option.estimatedSizeLabel,
                  style: const TextStyle(
                    color: Color(0xFF7EE0A1),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              option.tier.description,
              softWrap: true,
              style: const TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            _PackDeliveryFacts(manifest: manifest, option: option),
            const SizedBox(height: 8),
            _PackInstallFacts(check: installCheck, runtimeContext: runtime),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _HealthPill(
                  label: 'Items',
                  value: option.itemCount,
                  color: const Color(0xFF7EE0A1),
                ),
                _MiniToggleButton(
                  label: marked ? 'Marked' : 'Mark Needed',
                  active: marked,
                  color: const Color(0xFF58D67D),
                  onTap: () =>
                      settings.setTradePackOptionInstalled(option, !marked),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PackInstallFacts extends StatelessWidget {
  const _PackInstallFacts({required this.check, required this.runtimeContext});

  final WorkSupplyTradePackInstallCheck? check;
  final _TradePackRuntimeContext? runtimeContext;

  @override
  Widget build(BuildContext context) {
    final checked = check;
    final color = checked == null
        ? const Color(0xFFFFC857)
        : checked.canInstall
        ? const Color(0xFF7EE0A1)
        : const Color(0xFFFFC857);
    final status = checked?.status.name ?? 'checkingDevice';
    final requiredFree = checked == null
        ? 'Checking'
        : workSupplyByteSizeLabel(checked.requiredFreeBytes);
    final deviceLabel =
        runtimeContext?.deviceProfile.statusLabel ?? 'Checking device';
    final networkLabel = runtimeContext == null
        ? 'Checking network'
        : runtimeContext!.networkVerified
        ? runtimeContext!.isMeteredNetwork
              ? 'Metered'
              : 'Not metered'
        : 'Not verified';
    final message =
        checked?.message ??
        'Checking this device before any pack download is allowed.';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F191E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF33444B)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _SmallFact(label: 'Needs free', value: requiredFree),
                _SmallFact(label: 'Safety', value: status),
                _SmallFact(label: 'Device', value: deviceLabel),
                _SmallFact(label: 'Network', value: networkLabel),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackDeliveryFacts extends StatelessWidget {
  const _PackDeliveryFacts({required this.manifest, required this.option});

  final WorkSupplyTradePackManifest manifest;
  final WorkSupplyTradePackOption option;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F191E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF33444B)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _SmallFact(label: 'Manifest reads', value: '1'),
                _SmallFact(label: 'Item doc reads', value: '0'),
                _SmallFact(label: 'Chunks', value: '${manifest.chunkCount}'),
                _SmallFact(
                  label: 'Mode',
                  value: manifest.isFirestoreReadSafe ? 'Bundled' : 'Review',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              option.storagePath,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF94A3AA),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallFact extends StatelessWidget {
  const _SmallFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111B20),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF42535B)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Text(
          '$label: $value',
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
