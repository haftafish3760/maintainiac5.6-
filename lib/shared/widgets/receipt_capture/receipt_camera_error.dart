part of 'receipt_camera_screen.dart';

class _ReceiptCameraError extends StatelessWidget {
  const _ReceiptCameraError({
    required this.message,
    required this.onRetry,
    required this.onClose,
    this.onOpenSettings,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography_rounded,
              color: Color(0xFFFFD166),
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1976B9),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (onOpenSettings != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Open Camera Permission'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD166),
                    foregroundColor: const Color(0xFF101416),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
