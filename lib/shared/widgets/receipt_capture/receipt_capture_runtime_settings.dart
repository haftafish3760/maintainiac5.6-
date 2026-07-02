part of 'receipt_attachment_panel.dart';

class _ReceiptCameraRuntimeSummary extends StatelessWidget {
  const _ReceiptCameraRuntimeSummary({
    required this.profile,
    required this.privacySafeCapabilityLabel,
  });

  final ReceiptCameraRuntimeProfile profile;
  final String privacySafeCapabilityLabel;

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
                  const SizedBox(height: 4),
                  Text(
                    'Detected safely: $privacySafeCapabilityLabel',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFAEB8BC),
                      fontSize: 10.5,
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
          const SizedBox(height: 4),
          _ReceiptSettingsNote(
            icon: Icons.install_mobile_rounded,
            text: settings.defaultDataSaverInstallFootprintSummary,
          ),
          const SizedBox(height: 6),
          _ReceiptCameraRuntimeSummary(
            profile: runtime,
            privacySafeCapabilityLabel: settings.privacySafeCapabilityLabel,
          ),
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
