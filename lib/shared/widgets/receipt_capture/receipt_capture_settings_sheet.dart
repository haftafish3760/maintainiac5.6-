part of 'receipt_attachment_panel.dart';

class _ReceiptCaptureSettingsScreen extends StatelessWidget {
  const _ReceiptCaptureSettingsScreen({
    required this.settings,
    required this.area,
    required this.hasSavedReceiptProof,
  });

  final ReceiptCaptureSettingsController settings;
  final ReceiptCaptureArea area;
  final bool hasSavedReceiptProof;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161D20),
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
                hasSavedReceiptProof: hasSavedReceiptProof,
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
    required this.hasSavedReceiptProof,
    this.showTitle = true,
  });

  final ReceiptCaptureSettingsController settings;
  final ReceiptCaptureArea area;
  final bool hasSavedReceiptProof;
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
                style: const TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              _ReceiptSettingsOverviewCard(settings: settings, area: area),
              const SizedBox(height: 8),
              const _ReceiptSettingsNote(
                icon: Icons.route_rounded,
                text:
                    'Recommended flow: add receipt, review photos, use receipt, then review the filled details. Capture settings do not replace your phone camera software.',
              ),
              const SizedBox(height: 8),
              const _ReceiptBackupStorageSummary(),
              const SizedBox(height: 8),
              _ReceiptAssistSettings(
                settings: settings,
                area: area,
                title: _assistedReceiptTitle(area),
                detail: _assistedReceiptDetail(area),
              ),
              const SizedBox(height: 8),
              _ReceiptDataSaverDefaultPicker(settings: settings),
              if (expenseSettings != null) ...[
                const SizedBox(height: 8),
                _ExpenseReceiptReviewDefaultPicker(settings: expenseSettings),
              ],
              const SizedBox(height: 8),
              _ReceiptScannerBehaviorSettings(settings: settings),
              const SizedBox(height: 8),
              const _ReceiptPostCaptureWorkflowSettings(),
              const SizedBox(height: 8),
              _ReceiptDiagnosticsSettings(settings: settings),
              const SizedBox(height: 8),
              const _ReceiptSettingsNote(
                icon: Icons.light_mode_rounded,
                text:
                    'Brightness and light controls stay on the camera viewer, not in Settings, so you can see the receipt while adjusting them.',
              ),
              if (!hasSavedReceiptProof) ...[
                const SizedBox(height: 8),
                const _ReceiptSettingsNote(
                  icon: Icons.photo_library_outlined,
                  text:
                      'After a receipt photo is attached, the review screen shows the actual proof size and lets you inspect readability before saving.',
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showReceiptCameraHelp(context),
                icon: const Icon(Icons.help_outline_rounded),
                label: const Text('Receipt Photo Help'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE8ECEE),
                  side: const BorderSide(color: Color(0xFF526168)),
                  backgroundColor: const Color(0xFF1F2528),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    _confirmResetReceiptSettings(context, settings, area),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset Receipt Photo Defaults'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD166),
                  side: const BorderSide(color: Color(0xFFC7922E)),
                  backgroundColor: const Color(0xFF1F2528),
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
}

class _ReceiptSettingsOverviewCard extends StatelessWidget {
  const _ReceiptSettingsOverviewCard({
    required this.settings,
    required this.area,
  });

  final ReceiptCaptureSettingsController settings;
  final ReceiptCaptureArea area;

  @override
  Widget build(BuildContext context) {
    final assistOn = settings.appAssistedEnabledFor(area);
    final backupOn = settings.receiptPhotoBackupEnabled;
    final proofLabel = settings.defaultDataSaverUsesDeviceRecommendation
        ? settings.deviceCapability.recommendedSpaceSavingLabel
        : settings.defaultDataSaverLevel.label;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1416),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3D4A50)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Current Receipt Flow',
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ReceiptSettingsStatusChip(
                  icon: assistOn
                      ? Icons.auto_awesome_rounded
                      : Icons.edit_note_rounded,
                  label: assistOn ? 'Receipt Assist On' : 'Manual Entry',
                  emphasized: assistOn,
                ),
                _ReceiptSettingsStatusChip(
                  icon: backupOn
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  label: backupOn ? 'Photo Backup On' : 'Photo Backup Off',
                  emphasized: backupOn,
                ),
                _ReceiptSettingsStatusChip(
                  icon: Icons.photo_size_select_large_rounded,
                  label: proofLabel,
                  emphasized: false,
                ),
                _ReceiptSettingsStatusChip(
                  icon: Icons.receipt_long_rounded,
                  label: settings.cameraLongReceiptTips
                      ? 'Long Receipt Tips'
                      : 'Simple Capture',
                  emphasized: settings.cameraLongReceiptTips,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptSettingsStatusChip extends StatelessWidget {
  const _ReceiptSettingsStatusChip({
    required this.icon,
    required this.label,
    required this.emphasized,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized ? const Color(0xFFFFD166) : const Color(0xFF161D20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: emphasized ? const Color(0xFFFFD166) : const Color(0xFF526168),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: emphasized
                  ? const Color(0xFF101416)
                  : const Color(0xFFE8ECEE),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: emphasized
                    ? const Color(0xFF101416)
                    : const Color(0xFFE8ECEE),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
