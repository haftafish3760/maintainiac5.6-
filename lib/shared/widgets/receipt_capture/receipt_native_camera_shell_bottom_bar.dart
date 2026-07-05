part of 'receipt_native_camera_shell.dart';

class _ReceiptNativeCameraBottomBar extends StatelessWidget {
  const _ReceiptNativeCameraBottomBar({
    required this.capturing,
    required this.capabilities,
    required this.settings,
    required this.onCapture,
    this.qualityLabel,
  });

  final bool capturing;
  final ReceiptNativeCameraCapabilities capabilities;
  final ReceiptNativeCameraSettings settings;
  final VoidCallback onCapture;
  final String? qualityLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00050607), Color(0xB8050607)],
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _ReceiptNativeCameraModePill(
                      icon: settings.assistedReceiptFill
                          ? Icons.receipt_long_rounded
                          : Icons.edit_note_rounded,
                      label: settings.assistedReceiptFill
                          ? 'Receipt assist'
                          : 'Manual receipt',
                      detail: settings.assistedReceiptFill
                          ? 'Next reviews text'
                          : 'Save photo only',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ReceiptNativeCameraShutterButton(
                      capturing: capturing,
                      onPressed: capturing ? null : onCapture,
                    ),
                  ),
                  Expanded(
                    child: _ReceiptNativeCameraModePill(
                      icon: Icons.storage_rounded,
                      label: qualityLabel ?? 'Saved proof',
                      detail: _storageDetail(settings.dataSaverLevel),
                      alignRight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ReceiptNativeCameraNextStepStrip(
                settings: settings,
                capabilities: capabilities,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _storageDetail(ReceiptDataSaverLevel level) {
    return switch (level) {
      ReceiptDataSaverLevel.original => 'Local original',
      ReceiptDataSaverLevel.light => 'Sharp proof',
      ReceiptDataSaverLevel.balanced => 'Normal proof',
      ReceiptDataSaverLevel.strong => 'Smaller proof',
      ReceiptDataSaverLevel.maximum => 'Tiny proof',
    };
  }
}

class _ReceiptNativeCameraNextStepStrip extends StatelessWidget {
  const _ReceiptNativeCameraNextStepStrip({
    required this.settings,
    required this.capabilities,
  });

  final ReceiptNativeCameraSettings settings;
  final ReceiptNativeCameraCapabilities capabilities;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xD911181B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF526168), width: .8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              const Icon(
                Icons.route_rounded,
                color: Color(0xFFFFD166),
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 11,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _captureBadge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFD166),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _label {
    if (settings.assistedReceiptFill) {
      return 'After capture: review receipt text, then choose business, personal, or mixed.';
    }
    return 'After capture: keep the receipt photo attached to this expense.';
  }

  String get _semanticLabel {
    if (settings.assistedReceiptFill) {
      return 'After capture, review receipt text before saving the expense.';
    }
    return 'After capture, save the receipt photo with manual entry.';
  }

  String get _captureBadge =>
      capabilities.engine == ReceiptNativeCameraEngine.unavailable
      ? 'Backup'
      : 'Ready';
}
