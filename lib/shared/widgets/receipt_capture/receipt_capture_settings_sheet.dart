part of 'receipt_attachment_panel.dart';

class _ReceiptCaptureSettingsSheet extends StatelessWidget {
  const _ReceiptCaptureSettingsSheet({
    required this.settings,
    this.setupMode = false,
  });

  final ReceiptCaptureSettingsController settings;
  final bool setupMode;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 12),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Receipt Photo Settings',
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                setupMode
                    ? 'Set how much help you want before the camera opens. You can change this later.'
                    : 'These choices apply anywhere Maintaniac attaches receipts.',
                style: TextStyle(
                  color: const Color(0xFFC7D0D4),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              _ReceiptSettingsSwitch(
                title: 'App-Assisted Receipt Fill',
                detail:
                    'Let Maintaniac read receipt photos or imported receipt text and help fill fields for your review.',
                value: settings.appAssistedReceiptFill,
                onChanged: settings.setAppAssistedReceiptFill,
              ),
              const SizedBox(height: 8),
              _ReceiptAssistedAreaPicker(settings: settings),
              const SizedBox(height: 8),
              _ReceiptCameraExperiencePicker(settings: settings),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showReceiptCameraHelp(context),
                icon: const Icon(Icons.help_outline_rounded),
                label: const Text('Camera Help'),
              ),
              const SizedBox(height: 8),
              const _ReceiptSettingsInfo(
                title: 'Photo Reading Accuracy',
                detail:
                    'Maintaniac reads the clear accepted photo before saving the smaller copy. This stays automatic so space saving does not make receipt reading worse.',
              ),
              const SizedBox(height: 8),
              _ReceiptDataSaverDefaultPicker(settings: settings),
              const SizedBox(height: 8),
              _ReceiptSettingsSwitch(
                title: 'Google Vision Access',
                detail:
                    'Future cloud receipt reading. Free users will be limited by the server to ${settings.monthlyGoogleVisionLimit} receipts per month.',
                value: settings.googleVisionAccess,
                onChanged: settings.setGoogleVisionAccess,
              ),
              if (setupMode) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await settings.setCameraSetupComplete(true);
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: const Text('Open Camera'),
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
            ],
          ),
        );
      },
    );
  }
}

class _ReceiptCameraExperiencePicker extends StatelessWidget {
  const _ReceiptCameraExperiencePicker({required this.settings});

  final ReceiptCaptureSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final guidanceEnabled = settings.cameraGuidanceEnabled;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Camera Assistance',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Keeps the camera clean while letting you choose how much help it gives.',
            style: TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          _ReceiptSettingsSwitch(
            title: 'Live Photo Guidance',
            detail:
                'Shows simple red, yellow, and green guidance for light, focus, angle, and framing.',
            value: settings.cameraGuidanceEnabled,
            onChanged: settings.setCameraGuidanceEnabled,
          ),
          _ReceiptSettingsSwitch(
            title: 'Start With Guidance On',
            detail:
                'Open the receipt camera in assisted aiming mode by default.',
            value: settings.cameraStartAssisted,
            onChanged: guidanceEnabled ? settings.setCameraStartAssisted : null,
          ),
          _ReceiptSettingsSwitch(
            title: 'Auto Capture When Ready',
            detail:
                'When the receipt stays readable, take a best-shot burst automatically. Manual capture still works.',
            value: settings.cameraAutoCapture,
            onChanged: guidanceEnabled ? settings.setCameraAutoCapture : null,
          ),
          _ReceiptSettingsSwitch(
            title: 'Voice Capture',
            detail:
                'Reserved for hands-free capture phrases like capture, snap, or take photo.',
            value: settings.cameraVoiceCapture,
            onChanged: settings.setCameraVoiceCapture,
          ),
          _ReceiptSettingsSwitch(
            title: 'Long Receipt Tips',
            detail:
                'Remind you that long receipts can be saved as multiple photos on the review screen.',
            value: settings.cameraLongReceiptTips,
            onChanged: settings.setCameraLongReceiptTips,
          ),
        ],
      ),
    );
  }
}

class _ReceiptAssistedAreaPicker extends StatelessWidget {
  const _ReceiptAssistedAreaPicker({required this.settings});

  final ReceiptCaptureSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final enabled = settings.appAssistedReceiptFill;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Use App Assistance In',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Turn it off anywhere you want receipts entered fully by hand.',
            style: TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          _ReceiptSettingsSwitch(
            title: ReceiptCaptureArea.expenses.label,
            detail: 'Expense receipts and mixed business/personal receipts.',
            value: settings.appAssistedExpenses,
            onChanged: enabled ? settings.setAppAssistedExpenses : null,
          ),
          _ReceiptSettingsSwitch(
            title: ReceiptCaptureArea.materialsInventory.label,
            detail: 'Material receipts that may also become inventory.',
            value: settings.appAssistedMaterials,
            onChanged: enabled ? settings.setAppAssistedMaterials : null,
          ),
          _ReceiptSettingsSwitch(
            title: ReceiptCaptureArea.maintenanceRepair.label,
            detail: 'Service, repair, and maintenance receipts.',
            value: settings.appAssistedMaintenance,
            onChanged: enabled ? settings.setAppAssistedMaintenance : null,
          ),
        ],
      ),
    );
  }
}

class _ReceiptSettingsInfo extends StatelessWidget {
  const _ReceiptSettingsInfo({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFFFFD166),
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
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
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            'Default Space Saving',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final level in ReceiptDataSaverLevel.values)
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
      label: Text('${level.label}: ${level.shortLabel}'),
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
