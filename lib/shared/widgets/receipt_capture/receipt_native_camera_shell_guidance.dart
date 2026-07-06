part of 'receipt_native_camera_shell.dart';

class _ReceiptNativeCameraGuidance extends StatelessWidget {
  const _ReceiptNativeCameraGuidance({
    required this.title,
    required this.message,
    required this.capabilities,
    this.status,
    this.sectionLabel,
  });

  final String title;
  final String message;
  final ReceiptNativeCameraCapabilities capabilities;
  final String? status;
  final String? sectionLabel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xB8050607),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x8077888F)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFFFD166),
                  size: 16,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    _compactText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (sectionLabel != null) ...[
                  const SizedBox(width: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xDD11181B),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      child: Text(
                        sectionLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE4EBEE),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _compactText {
    final statusText = status?.trim();
    if (statusText != null && statusText.isNotEmpty) return statusText;
    final titleText = title.trim();
    if (titleText.isNotEmpty && titleText != 'Line up the receipt') {
      return titleText;
    }
    return 'Fill the screen with readable receipt text';
  }
}
