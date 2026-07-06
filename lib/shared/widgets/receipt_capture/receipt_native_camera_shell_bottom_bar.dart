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
    return Semantics(
      label: _semanticLabel,
      child: DecoratedBox(
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
                    const Expanded(child: SizedBox()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ReceiptNativeCameraShutterButton(
                        capturing: capturing,
                        onPressed: capturing ? null : onCapture,
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _semanticLabel {
    final assist = settings.assistedReceiptFill
        ? 'receipt assist'
        : 'manual receipt';
    final quality = qualityLabel == null
        ? 'quality pending'
        : 'quality $qualityLabel';
    final engine = capabilities.engine == ReceiptNativeCameraEngine.unavailable
        ? 'backup camera'
        : 'native camera';
    return '$engine shutter, $assist, $quality';
  }
}
