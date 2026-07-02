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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xC0050607),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x996B7A81)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.subject_rounded,
                  color: Color(0xFFFFD166),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (sectionLabel != null)
                  Text(
                    sectionLabel!,
                    style: const TextStyle(
                      color: Color(0xFFE4EBEE),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFD5DEE2),
                fontSize: 13,
                height: 1.18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            if (status != null) ...[
              const SizedBox(height: 8),
              Text(
                status!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFD166),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
            if (_controlChips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: _controlChips),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> get _controlChips {
    final chips = <Widget>[];
    if (capabilities.supportsTapFocus) {
      chips.add(
        const _ReceiptNativeCameraControlChip(
          icon: Icons.touch_app_rounded,
          label: 'Tap text to focus',
        ),
      );
    }
    if (capabilities.supportsZoom) {
      chips.add(
        const _ReceiptNativeCameraControlChip(
          icon: Icons.pinch_rounded,
          label: 'Pinch to zoom',
        ),
      );
    }
    if (capabilities.supportsExposureCompensation) {
      chips.add(
        const _ReceiptNativeCameraControlChip(
          icon: Icons.wb_sunny_rounded,
          label: 'Brightness assist',
        ),
      );
    }
    return chips;
  }
}

class _ReceiptNativeCameraControlChip extends StatelessWidget {
  const _ReceiptNativeCameraControlChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC11181B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF526168), width: .8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFFD166), size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
