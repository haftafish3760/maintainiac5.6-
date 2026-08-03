part of 'receipt_photo_review_screen.dart';

/// Deliberately lives beside the image rather than under it.  The person can
/// compare the actual saved-image preview with each size without a large tool
/// tray covering the receipt or competing camera controls.
class _ReceiptSavedImageSideRail extends StatelessWidget {
  const _ReceiptSavedImageSideRail({
    required this.selected,
    required this.preview,
    required this.enabled,
    required this.visible,
    required this.onSelected,
    required this.onPreview,
  });

  final ReceiptDataSaverLevel selected;
  final ReceiptImageStoragePreview? preview;
  final bool enabled;
  final bool visible;
  final ValueChanged<ReceiptDataSaverLevel> onSelected;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    final previewLabel = preview == null
        ? 'Preparing preview'
        : 'This receipt: about ${preview!.estimatedLabel}';
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      top: 10,
      right: visible ? 8 : -222,
      bottom: 10,
      child: SizedBox(
        width: 206,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xF00D1316),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF526168)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 10,
                offset: Offset(-2, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(9, 10, 9, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Save space for this receipt',
                    style: TextStyle(
                      color: Color(0xFFF0F4F2),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose how clear the saved copy should be. You can hide this panel and check the full receipt before continuing.',
                    style: TextStyle(
                      color: Color(0xFFC8D0D3),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 9),
                  for (final level in _levels) ...[
                    _SavedImageSizeChoice(
                      level: level,
                      selected: level == selected,
                      enabled: enabled,
                      onTap: () => onSelected(level),
                    ),
                    const SizedBox(height: 7),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    previewLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8EF6A4),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    selected.proofTargetSizePolicy.earlyAccessProofCapacityLabel
                        .replaceFirst('About ', 'At this size, about '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF9FB0B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _DataSaverDeviceSpaceSummary(
                    key: ValueKey(preview?.estimatedBytes ?? 0),
                    savedImageBytes: preview?.estimatedBytes,
                  ),
                  const SizedBox(height: 9),
                  OutlinedButton.icon(
                    onPressed: enabled ? onPreview : null,
                    icon: const Icon(
                      Icons.keyboard_double_arrow_right_rounded,
                      size: 18,
                    ),
                    label: const Text('Hide panel & view full receipt'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D2216),
                      backgroundColor: const Color(0xFF8EF6A4),
                      side: const BorderSide(color: Color(0xFF8EF6A4)),
                      textStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (settings != null) ...[
                    const Divider(height: 20, color: Color(0xFF526168)),
                    const Text(
                      'SAVED ON THIS DEVICE',
                      style: TextStyle(
                        color: Color(0xFFF0F4F2),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'You stay in control of whether receipt images are backed up.',
                      style: TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    _DataSaverSettingToggle(
                      label: 'Ask me for each receipt',
                      value: settings.askSavedProofSizeEachReceipt,
                      enabled: enabled,
                      onChanged: settings.setAskSavedProofSizeEachReceipt,
                    ),
                    _DataSaverSettingToggle(
                      label: 'Back up receipt photos',
                      value: settings.receiptPhotoBackupEnabled,
                      enabled: enabled,
                      onChanged: settings.setReceiptPhotoBackupEnabled,
                    ),
                    _DataSaverBackupStatus(
                      backupRequested: settings.receiptPhotoBackupEnabled,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _levels = [
    ReceiptDataSaverLevel.original,
    ReceiptDataSaverLevel.light,
    ReceiptDataSaverLevel.balanced,
    ReceiptDataSaverLevel.strong,
    ReceiptDataSaverLevel.economy,
    ReceiptDataSaverLevel.maximum,
  ];
}

/// Shows only information we can verify locally.  A percentage of the whole
/// device would be misleading because Android does not provide a stable total
/// capacity through this shared storage guard; free space is the useful fact
/// for deciding whether this photo can be kept.
class _DataSaverDeviceSpaceSummary extends StatefulWidget {
  const _DataSaverDeviceSpaceSummary({
    super.key,
    required this.savedImageBytes,
  });

  final int? savedImageBytes;

  @override
  State<_DataSaverDeviceSpaceSummary> createState() =>
      _DataSaverDeviceSpaceSummaryState();
}

class _DataSaverDeviceSpaceSummaryState
    extends State<_DataSaverDeviceSpaceSummary> {
  late final Future<AppStorageCheck> _storageCheck =
      AppStorageGuard.checkForBytes(
        operationBytes:
            widget.savedImageBytes ?? AppStorageGuard.receiptProofSaveBytes,
        purpose: AppStoragePurpose.receiptPhotoSave,
      );

  @override
  Widget build(BuildContext context) => FutureBuilder<AppStorageCheck>(
    future: _storageCheck,
    builder: (context, snapshot) {
      final check = snapshot.data;
      final known = check?.canVerify == true;
      final available = check?.availableBytes;
      final isLow = check?.shouldWarnLowStorage == true;
      final title = !known
          ? 'PHONE STORAGE'
          : isLow
          ? 'PHONE STORAGE IS LOW'
          : 'PHONE STORAGE';
      final detail = !known
          ? 'Checking free space on this phone.'
          : '${AppStorageGuard.formatBytes(available!)} free on this phone';
      final statusColor = !known
          ? const Color(0xFF9FB0B8)
          : isLow
          ? const Color(0xFFF3C65D)
          : const Color(0xFF8EF6A4);
      final statusLabel = !known
          ? 'Checking'
          : isLow
          ? 'Low space'
          : 'Enough room for this receipt';
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF111B1F),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFF526168)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFF0F4F2),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withValues(alpha: .7)),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// The receipt screen must never invent a backup quota.  This clearly tells a
/// person whether this choice remains local or whether an account connection
/// is still needed before a real remaining-backup amount can be shown.
class _DataSaverBackupStatus extends StatelessWidget {
  const _DataSaverBackupStatus({required this.backupRequested});

  final bool backupRequested;

  @override
  Widget build(BuildContext context) {
    final title = backupRequested ? 'BACKUP SPACE' : 'BACKUP';
    final detail = backupRequested
        ? 'Connect an authorized backup account to see its real remaining space.'
        : 'Off. This receipt will stay on this phone.';
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF111B1F),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF526168)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF0F4F2),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataSaverSettingToggle extends StatelessWidget {
  const _DataSaverSettingToggle({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    toggled: value,
    child: SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFF0F4F2),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      value: value,
      activeThumbColor: const Color(0xFF8EF6A4),
      activeTrackColor: const Color(0xFF276841),
      onChanged: enabled ? onChanged : null,
    ),
  );
}

class _SavedImageSizeChoice extends StatelessWidget {
  const _SavedImageSizeChoice({
    required this.level,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ReceiptDataSaverLevel level;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected ? const Color(0xFF8EF6A4) : const Color(0xFF526168);
    return Material(
      color: selected ? const Color(0xFF1B342B) : const Color(0xFF172126),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 7, 6, 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? const Color(0xFF8EF6A4)
                    : const Color(0xFF9FB0B8),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dataSaverChoiceTitle(level),
                      style: const TextStyle(
                        color: Color(0xFFF0F4F2),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _dataSaverChoiceDetail(level),
                      style: const TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _dataSaverChoiceTitle(ReceiptDataSaverLevel level) => switch (level) {
  ReceiptDataSaverLevel.light => 'Clearer copy',
  ReceiptDataSaverLevel.balanced => 'High quality',
  ReceiptDataSaverLevel.strong => 'Balanced',
  ReceiptDataSaverLevel.economy => 'Smaller copy',
  ReceiptDataSaverLevel.maximum => 'Smallest copy',
  ReceiptDataSaverLevel.original => 'Original photo',
};

String _dataSaverChoiceDetail(ReceiptDataSaverLevel level) => switch (level) {
  ReceiptDataSaverLevel.light => '750 KB–1 MB · Best for fine print',
  ReceiptDataSaverLevel.balanced => '450–650 KB · Clear everyday copy',
  ReceiptDataSaverLevel.strong => '200–300 KB · Recommended for most receipts',
  ReceiptDataSaverLevel.economy => '100–175 KB · Check the preview first',
  ReceiptDataSaverLevel.maximum => '50–90 KB · Use only when space is tight',
  ReceiptDataSaverLevel.original => 'Kept on this device only',
};
