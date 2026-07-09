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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD4DCE0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.tune_rounded, color: Color(0xFF2B6CB0), size: 18),
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
                      color: Color(0xFF172126),
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
                      color: Color(0xFF4E5B61),
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
                      color: Color(0xFF66757D),
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

class _ReceiptBackupStorageSummary extends StatelessWidget {
  const _ReceiptBackupStorageSummary();

  @override
  Widget build(BuildContext context) {
    final settings = ReceiptCaptureSettingsScope.of(context);
    const cloudStatus = CloudBackupStatusSnapshot.notConnected();
    final quotaCheck = cloudStatus.checkPendingBytes(0);
    final policy = settings.defaultDataSaverProofTargetSizePolicy;
    final estimate = _estimatedReceiptCount(policy);
    final sizeLabel = policy.keepsOriginalLocalOnly
        ? 'saved proof copy'
        : policy.targetLabel;
    return _ReceiptSettingsSection(
      icon: Icons.cloud_done_rounded,
      title: 'Backup Storage',
      subtitle:
          'Shows the receipt backup quota Maintainiac will use for this account.',
      children: [
        _ReceiptStorageMetricRow(
          label: 'Backup account',
          value: cloudStatus.connectionState.label,
          detail: cloudStatus.message ?? 'Local receipt saving still works.',
        ),
        const SizedBox(height: 8),
        _ReceiptStorageMetricRow(
          label: 'Storage remaining',
          value: '${quotaCheck.remainingLabel} of ${quotaCheck.quotaLabel}',
          detail: policy.keepsOriginalLocalOnly
              ? 'Original photos stay local by default. Backup should use a smaller proof copy.'
              : 'At about $sizeLabel per receipt, that is roughly $estimate receipt proofs before extra storage.',
        ),
      ],
    );
  }

  static int _estimatedReceiptCount(ReceiptProofTargetSizePolicy policy) {
    if (policy.targetBytes <= 0) return 0;
    return (CloudBackupStatusSnapshot.notConnected()
                .checkPendingBytes(0)
                .remainingBytes /
            policy.targetBytes)
        .floor();
  }
}

class _ReceiptStorageMetricRow extends StatelessWidget {
  const _ReceiptStorageMetricRow({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD4DCE0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF536167),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF172126),
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFF4E5B61),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.22,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptAssistSettings extends StatelessWidget {
  const _ReceiptAssistSettings({
    required this.settings,
    required this.area,
    required this.title,
    required this.detail,
  });

  final ReceiptCaptureSettingsController settings;
  final ReceiptCaptureArea area;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return _ReceiptSettingsSection(
      icon: Icons.auto_awesome_rounded,
      title: 'Receipt Assist',
      subtitle: 'Manual entry always stays available.',
      children: [
        _ReceiptSettingsSwitch(
          title: title,
          detail: detail,
          value: settings.appAssistedEnabledFor(area),
          onChanged: (value) async {
            if (value) await settings.setAppAssistedReceiptFill(true);
            await _setAreaEnabled(value);
          },
        ),
      ],
    );
  }

  Future<void> _setAreaEnabled(bool value) {
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
    return _ReceiptSettingsSection(
      icon: Icons.receipt_long_rounded,
      title: 'Capture Flow',
      subtitle:
          'Keep receipt capture simple: take photos, review sections, then read the receipt.',
      children: [
        const SizedBox(height: 4),
        const _ReceiptSettingsNote(
          icon: Icons.radio_button_checked_rounded,
          text:
              'Automatic photo capture stays off unless you turn it on. The shutter button remains the primary capture action.',
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
              'Show top-to-bottom section guidance, overlap reminders, and photo-order review for long receipts.',
          value: settings.cameraLongReceiptTips,
          onChanged: settings.setCameraLongReceiptTips,
        ),
        const SizedBox(height: 4),
        _ReceiptSettingsNote(
          icon: Icons.install_mobile_rounded,
          text: settings.defaultDataSaverInstallFootprintSummary,
        ),
      ],
    );
  }
}

class _ReceiptDiagnosticsSettings extends StatelessWidget {
  const _ReceiptDiagnosticsSettings({required this.settings});

  final ReceiptCaptureSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return _ReceiptSettingsSection(
      icon: Icons.privacy_tip_rounded,
      title: 'Privacy And Diagnostics',
      subtitle: 'Optional help for improving receipt capture.',
      children: [
        _ReceiptSettingsSwitch(
          title: 'Help Improve Receipt Camera',
          detail:
              'Shares privacy-safe camera failure counts only when enabled. Receipt images and receipt text stay out of owner-visible diagnostics.',
          value: settings.cameraDiagnosticsImprovementOptIn,
          onChanged: settings.setCameraDiagnosticsImprovementOptIn,
        ),
      ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      activeThumbColor: const Color(0xFF2B6CB0),
      title: Text(
        title,
        style: TextStyle(
          color: onChanged == null
              ? const Color(0xFF7E8A90)
              : const Color(0xFF172126),
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      subtitle: Text(
        detail,
        style: const TextStyle(
          color: Color(0xFF4E5B61),
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

class _ReceiptSettingsSection extends StatelessWidget {
  const _ReceiptSettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD4DCE0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF2B6CB0), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF172126),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF536167),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
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
        color: const Color(0xFFF5F7F8),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD4DCE0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2B6CB0), size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4E5B61),
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
