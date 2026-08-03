part of 'receipt_attachment_panel.dart';

class _ReceiptDataSaverDefaultPicker extends StatelessWidget {
  const _ReceiptDataSaverDefaultPicker({required this.settings});

  final ReceiptCaptureSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return _ReceiptSettingsSection(
      icon: Icons.photo_size_select_large_rounded,
      title: 'Saved Receipt Image',
      subtitle:
          'Choose the photo copy kept after review. Receipt Assist always reads the clear source first.',
      children: [
        _ReceiptSettingsSwitch(
          title: 'Ask Every Receipt',
          detail:
              'Choose the saved image size while reviewing each receipt instead of always using the default.',
          value: settings.askSavedProofSizeEachReceipt,
          onChanged: settings.setAskSavedProofSizeEachReceipt,
        ),
        const SizedBox(height: 6),
        const _ReceiptSettingsNote(
          icon: Icons.preview_rounded,
          text:
              'After a photo is taken, you preview the actual saved image before keeping it. If it is not readable, pick a larger size or retake the photo.',
        ),
        const SizedBox(height: 8),
        const _ReceiptSettingsNote(
          icon: Icons.recommend_rounded,
          text:
              'Recommended: Everyday uses about 250 KB per photo. On the early-access 100 MB backup plan, that leaves room for about 390 receipt photos after the protected text reserve.',
        ),
        const SizedBox(height: 8),
        for (final level in _receiptBackupLevels) ...[
          _ReceiptDataSaverChoice(
            level: level,
            selected: settings.defaultDataSaverLevel == level,
            onTap: () => settings.setDefaultDataSaverLevel(level),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  static const _receiptBackupLevels = [
    ReceiptDataSaverLevel.light,
    ReceiptDataSaverLevel.balanced,
    ReceiptDataSaverLevel.strong,
    ReceiptDataSaverLevel.economy,
    ReceiptDataSaverLevel.maximum,
  ];
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
        child: Material(
          color: selected ? const Color(0xFFFFD166) : const Color(0xFF161D20),
          borderRadius: BorderRadius.circular(7),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFFE2A1)
                      : const Color(0xFF526168),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF101416)
                                : const Color(0xFFE8ECEE),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tooltip,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF263238)
                                : const Color(0xFFC7D0D4),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? const Color(0xFF101416)
                        : const Color(0xFFC7D0D4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _choiceLabel(ReceiptDataSaverLevel level) {
    return switch (level) {
      ReceiptDataSaverLevel.original => 'Original source: temporary only',
      ReceiptDataSaverLevel.light => 'Best readability: 750 KB-1 MB',
      ReceiptDataSaverLevel.balanced => 'Clear: 450-650 KB',
      ReceiptDataSaverLevel.strong => 'Everyday: about 250 KB',
      ReceiptDataSaverLevel.economy => 'Saver: about 125 KB',
      ReceiptDataSaverLevel.maximum => 'Minimum: about 75 KB',
    };
  }

  static String _choiceTooltip(ReceiptDataSaverLevel level) {
    return switch (level) {
      ReceiptDataSaverLevel.original =>
        'Keeps the full photo only on this phone unless the user chooses otherwise.',
      ReceiptDataSaverLevel.light =>
        'Largest saved image. Easiest to review, uses more phone and backup space.',
      ReceiptDataSaverLevel.balanced =>
        'Clear saved image for receipts with small print or when you want more visual detail.',
      ReceiptDataSaverLevel.strong =>
        'Recommended for the 100 MB early-access backup plan: about 390 receipt photos after the protected text reserve.',
      ReceiptDataSaverLevel.economy =>
        'Uses less backup space. Check the actual preview before you keep it.',
      ReceiptDataSaverLevel.maximum =>
        'Smallest saved image. Use only after confirming the actual preview is readable.',
    };
  }
}
