part of 'receipt_attachment_panel.dart';

class _ReceiptDataSaverDefaultPicker extends StatelessWidget {
  const _ReceiptDataSaverDefaultPicker({required this.settings});

  final ReceiptCaptureSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final cloudAssistPlan = settings.defaultDataSaverCloudAssistPlan;
    return _ReceiptSettingsSection(
      icon: Icons.photo_size_select_large_rounded,
      title: 'Receipt Details And Saved Proof',
      subtitle:
          'Choose the default backup copy size. Receipt Assist still uses the clearest receipt source first.',
      children: [
        _ReceiptSettingsSwitch(
          title: 'Ask Every Receipt',
          detail:
              'Show the saved-proof size choice during receipt review instead of always using the default below.',
          value: settings.askSavedProofSizeEachReceipt,
          onChanged: settings.setAskSavedProofSizeEachReceipt,
        ),
        const SizedBox(height: 6),
        _ReceiptSettingsNote(
          icon: Icons.photo_size_select_large_rounded,
          text: settings.defaultDataSaverProofTargetSummary,
        ),
        const SizedBox(height: 6),
        const _ReceiptSettingsNote(
          icon: Icons.preview_rounded,
          text:
              'You preview the actual saved proof after taking a photo. Keep it with the receipt only after checking readability.',
        ),
        if (cloudAssistPlan.hasOptionalCloudAssist ||
            settings.defaultDataSaverShouldOfferOptionalLocalParserPacks) ...[
          const SizedBox(height: 6),
          const _ReceiptSettingsNote(
            icon: Icons.cloud_queue_rounded,
            text:
                'Extra cloud or offline receipt help must remain optional and user-approved. The receipt photo flow should work before any optional download.',
          ),
        ],
        if (settings.defaultDataSaverUsesDeviceRecommendation) ...[
          const SizedBox(height: 6),
          Text(
            'Current default: ${settings.deviceCapability.recommendedSpaceSavingLabel}.',
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _ReceiptRecommendedDataSaverChoice(
              selected: settings.defaultDataSaverUsesDeviceRecommendation,
              onTap: settings.useRecommendedDataSaverLevel,
            ),
            for (final level in _receiptBackupLevels)
              _ReceiptDataSaverChoice(
                level: level,
                selected: settings.defaultDataSaverLevel == level,
                onTap: () => settings.setDefaultDataSaverLevel(level),
              ),
          ],
        ),
      ],
    );
  }

  static const _receiptBackupLevels = [
    ReceiptDataSaverLevel.light,
    ReceiptDataSaverLevel.balanced,
    ReceiptDataSaverLevel.strong,
    ReceiptDataSaverLevel.maximum,
  ];
}

class _ReceiptRecommendedDataSaverChoice extends StatelessWidget {
  const _ReceiptRecommendedDataSaverChoice({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: const Text('Recommended Size'),
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFFD166),
      backgroundColor: const Color(0xFF161D20),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF101416) : const Color(0xFFE8ECEE),
        fontWeight: FontWeight.w900,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFFFFD166) : const Color(0xFF526168),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );
  }
}

class _ReceiptDataSaverChoice extends StatelessWidget {
  const _ReceiptDataSaverChoice({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final ReceiptDataSaverLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _choiceLabel(level);
    final tooltip = _choiceTooltip(level);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label. $tooltip',
        child: ChoiceChip(
          selected: selected,
          label: Text(label),
          onSelected: (_) => onTap(),
          selectedColor: const Color(0xFFFFD166),
          backgroundColor: const Color(0xFF161D20),
          labelStyle: TextStyle(
            color: selected ? const Color(0xFF101416) : const Color(0xFFE8ECEE),
            fontWeight: FontWeight.w900,
          ),
          side: BorderSide(
            color: selected ? const Color(0xFFFFD166) : const Color(0xFF526168),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
    );
  }

  static String _choiceLabel(ReceiptDataSaverLevel level) {
    return switch (level) {
      ReceiptDataSaverLevel.original => 'Original source: temporary only',
      ReceiptDataSaverLevel.light => 'Best readability: 750 KB-1 MB',
      ReceiptDataSaverLevel.balanced => 'Everyday: 450-650 KB',
      ReceiptDataSaverLevel.strong => 'Compact: 200-350 KB',
      ReceiptDataSaverLevel.maximum => 'Tiny proof: 75-150 KB',
    };
  }

  static String _choiceTooltip(ReceiptDataSaverLevel level) {
    return switch (level) {
      ReceiptDataSaverLevel.original =>
        'Keeps the full photo only on this phone unless the user chooses otherwise.',
      ReceiptDataSaverLevel.light =>
        'Largest saved proof. Easiest to review, uses more phone and cloud space.',
      ReceiptDataSaverLevel.balanced =>
        'Everyday saved proof size. Good balance for review, phone space, and cloud backup.',
      ReceiptDataSaverLevel.strong =>
        'Smaller saved proof for tight phone storage or lower cloud backup use.',
      ReceiptDataSaverLevel.maximum =>
        'Smallest saved proof. Saves the most space, review it before keeping it.',
    };
  }
}
