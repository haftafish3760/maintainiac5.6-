part of 'receipt_attachment_panel.dart';

class _ReceiptCaptureSettingsScreen extends StatelessWidget {
  const _ReceiptCaptureSettingsScreen({
    required this.settings,
    required this.area,
  });

  final ReceiptCaptureSettingsController settings;
  final ReceiptCaptureArea area;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF11181B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(42, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: Color(0xFF526168)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _settingsTitle(area),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _ReceiptCaptureSettingsSheet(
                settings: settings,
                area: area,
                showTitle: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _settingsTitle(ReceiptCaptureArea area) {
    return switch (area) {
      ReceiptCaptureArea.expenses => 'Expense Receipt Settings',
      ReceiptCaptureArea.materialsInventory => 'Materials Receipt Settings',
      ReceiptCaptureArea.maintenanceRepair => 'Maintenance Receipt Settings',
    };
  }
}

class _ReceiptCaptureSettingsSheet extends StatelessWidget {
  const _ReceiptCaptureSettingsSheet({
    required this.settings,
    required this.area,
    this.showTitle = true,
  });

  final ReceiptCaptureSettingsController settings;
  final ReceiptCaptureArea area;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final expenseSettings = area == ReceiptCaptureArea.expenses
        ? ExpenseSettingsScope.maybeOf(context)
        : null;
    return AnimatedBuilder(
      animation: Listenable.merge([settings, ?expenseSettings]),
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 12),
          child: ListView(
            shrinkWrap: showTitle,
            children: [
              if (showTitle) ...[
                Text(
                  _ReceiptCaptureSettingsScreen._settingsTitle(area),
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                _settingsSubtitle(area),
                style: TextStyle(
                  color: const Color(0xFFC7D0D4),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              const _ReceiptSettingsNote(
                icon: Icons.save_rounded,
                text:
                    'Changes save as soon as you tap a switch or size choice. Apply Settings closes this screen.',
              ),
              const SizedBox(height: 8),
              _ReceiptSettingsSwitch(
                title: _assistedReceiptTitle(area),
                detail: _assistedReceiptDetail(area),
                value: settings.appAssistedEnabledFor(area),
                onChanged: (value) =>
                    _setAppAssistedForArea(settings, area, value),
              ),
              if (expenseSettings != null) ...[
                const SizedBox(height: 8),
                _ExpenseReceiptReviewDefaultPicker(settings: expenseSettings),
              ],
              const SizedBox(height: 8),
              _ReceiptScannerBehaviorSettings(settings: settings),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showReceiptCameraHelp(context),
                icon: const Icon(Icons.help_outline_rounded),
                label: const Text('Receipt Photo Help'),
              ),
              const SizedBox(height: 8),
              _ReceiptDataSaverDefaultPicker(settings: settings),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    _confirmResetReceiptSettings(context, settings, area),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset Receipt Photo Defaults'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD166),
                  side: const BorderSide(color: Color(0xFFFFD166)),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Apply Settings'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF28A745),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _confirmResetReceiptSettings(
    BuildContext context,
    ReceiptCaptureSettingsController settings,
    ReceiptCaptureArea area,
  ) async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2528),
          title: const Text(
            'Reset Receipt Photo Settings?',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'This restores the recommended receipt scanner and saved proof settings for ${area.label}.',
            style: const TextStyle(
              color: Color(0xFFC7D0D4),
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Settings'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset Defaults'),
            ),
          ],
        );
      },
    );
    if (reset != true) return;
    await settings.resetReceiptPhotoDefaultsFor(area);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt photo settings reset to defaults.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static String _settingsSubtitle(ReceiptCaptureArea area) {
    return switch (area) {
      ReceiptCaptureArea.expenses =>
        'These choices apply when you add receipts from the Expense screen.',
      ReceiptCaptureArea.materialsInventory =>
        'These choices apply when you add receipts from Materials or Inventory.',
      ReceiptCaptureArea.maintenanceRepair =>
        'These choices apply when you add maintenance or repair receipts.',
    };
  }

  static String _assistedReceiptDetail(ReceiptCaptureArea area) {
    return switch (area) {
      ReceiptCaptureArea.expenses =>
        'When this is on, Maintainiac reads the receipt photo, PDF, or imported text and helps fill out the expense receipt form. You still review and fix everything before saving.',
      ReceiptCaptureArea.materialsInventory =>
        'When this is on, the app reads material receipts and helps prepare line items for review. Inventory is not updated until you confirm it.',
      ReceiptCaptureArea.maintenanceRepair =>
        'When this is on, the app reads maintenance receipts and helps fill store, date, total, and repair details for review.',
    };
  }

  static String _assistedReceiptTitle(ReceiptCaptureArea area) {
    return switch (area) {
      ReceiptCaptureArea.expenses =>
        'Let Maintainiac Help Fill Expense Receipts',
      ReceiptCaptureArea.materialsInventory =>
        'Let Maintainiac Help Fill Material Receipts',
      ReceiptCaptureArea.maintenanceRepair =>
        'Let Maintainiac Help Fill Maintenance Receipts',
    };
  }

  static Future<void> _setAppAssistedForArea(
    ReceiptCaptureSettingsController settings,
    ReceiptCaptureArea area,
    bool value,
  ) {
    return switch (area) {
      ReceiptCaptureArea.expenses => settings.setAppAssistedExpenses(value),
      ReceiptCaptureArea.materialsInventory => settings.setAppAssistedMaterials(
        value,
      ),
      ReceiptCaptureArea.maintenanceRepair =>
        settings.setAppAssistedMaintenance(value),
    };
  }
}

class _ReceiptScannerBehaviorSettings extends StatelessWidget {
  const _ReceiptScannerBehaviorSettings({required this.settings});

  final ReceiptCaptureSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final runtime = settings.effectiveCameraRuntimeProfile;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Receipt Scanner',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Maintainiac uses its own receipt camera when available. Backup scanner and photo options stay available so receipt capture does not get stuck.',
            style: TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.24,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          const _ReceiptSettingsNote(
            icon: Icons.touch_app_rounded,
            text:
                'Automatic photo capture stays off unless you turn it on later. You stay in control of when the receipt photo is taken.',
          ),
          const SizedBox(height: 6),
          _ReceiptCameraRuntimeSummary(profile: runtime),
          const SizedBox(height: 6),
          _ReceiptSettingsSwitch(
            title: 'Show Long Receipt Tips',
            detail:
                'Reminds you to scan long receipts from top to bottom and review the photo order before the app reads them.',
            value: settings.cameraLongReceiptTips,
            onChanged: settings.setCameraLongReceiptTips,
          ),
        ],
      ),
    );
  }
}

class _ReceiptCameraRuntimeSummary extends StatelessWidget {
  const _ReceiptCameraRuntimeSummary({required this.profile});

  final ReceiptCameraRuntimeProfile profile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.tune_rounded, color: Color(0xFFFFD166), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    profile.summaryLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1.16,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile.notesLabel,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.18,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseReceiptReviewDefaultPicker extends StatelessWidget {
  const _ExpenseReceiptReviewDefaultPicker({required this.settings});

  final ExpenseSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Expense Receipt Review Detail',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose what Maintainiac shows after it reads an expense receipt. You can still change this on each receipt before saving.',
            style: TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.24,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          _ReceiptReviewStyleChoice(
            selected:
                settings.receiptReviewStyle ==
                ExpenseReceiptReviewStyle.simpleAmounts,
            icon: Icons.price_check_rounded,
            title: 'Show Prices Only',
            detail:
                'Fastest review. Maintainiac lists detected receipt amounts so you can mark each one Business, Personal, or Split.',
            onTap: () => settings.setReceiptReviewStyle(
              ExpenseReceiptReviewStyle.simpleAmounts,
            ),
          ),
          const SizedBox(height: 8),
          _ReceiptReviewStyleChoice(
            selected:
                settings.receiptReviewStyle ==
                ExpenseReceiptReviewStyle.fullItemDetails,
            icon: Icons.receipt_long_rounded,
            title: 'Show Full Item Details',
            detail:
                'Use this when you want item names, quantities, fuel details, materials, packages, or inventory review.',
            onTap: () => settings.setReceiptReviewStyle(
              ExpenseReceiptReviewStyle.fullItemDetails,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptReviewStyleChoice extends StatelessWidget {
  const _ReceiptReviewStyleChoice({
    required this.selected,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected ? const Color(0xFFFFD166) : const Color(0xFF526168);
    final fill = selected ? const Color(0xFF2E2812) : const Color(0xFF172126);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFFFFD166)
                  : const Color(0xFFC7D0D4),
              size: 19,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.23,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? const Color(0xFFFFD166)
                  : const Color(0xFFC7D0D4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptSettingsSwitch extends StatelessWidget {
  const _ReceiptSettingsSwitch({
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: const Color(0xFFFFD166),
      title: Text(
        title,
        style: TextStyle(
          color: onChanged == null
              ? const Color(0xFF7E8A90)
              : const Color(0xFFE8ECEE),
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      subtitle: Text(
        detail,
        style: const TextStyle(
          color: Color(0xFFC7D0D4),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ReceiptSettingsNote extends StatelessWidget {
  const _ReceiptSettingsNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF334047)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8FD3FF), size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptDataSaverDefaultPicker extends StatelessWidget {
  const _ReceiptDataSaverDefaultPicker({required this.settings});

  final ReceiptCaptureSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Receipt Backup Image Size',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose the default saved proof size for receipt photos. Smaller files save phone space and cloud backup storage.',
            style: TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          const _ReceiptSettingsNote(
            icon: Icons.visibility_rounded,
            text:
                'You preview the actual saved proof after taking a photo. On the photo review screen, open Cleanup And Backup to see what this size looks like before keeping it.',
          ),
          if (settings.defaultDataSaverUsesDeviceRecommendation) ...[
            const SizedBox(height: 6),
            Text(
              'Current default: ${settings.deviceCapability.recommendedSpaceSavingLabel}.',
              style: const TextStyle(
                color: Color(0xFF9BA8AE),
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
      ),
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
      backgroundColor: const Color(0xFF172126),
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
    return ChoiceChip(
      selected: selected,
      label: Text(_choiceLabel(level)),
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFFD166),
      backgroundColor: const Color(0xFF172126),
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

  static String _choiceLabel(ReceiptDataSaverLevel level) {
    return switch (level) {
      ReceiptDataSaverLevel.original => 'Original: Local only',
      ReceiptDataSaverLevel.light => 'High Quality: 500-700 KB',
      ReceiptDataSaverLevel.balanced => 'Normal: 200-300 KB',
      ReceiptDataSaverLevel.strong => 'Low Storage: 100-150 KB',
      ReceiptDataSaverLevel.maximum => 'Tiny Backup: 40-100 KB',
    };
  }
}
