part of 'receipt_attachment_panel.dart';

class _ReceiptFirstUseCameraIntroSheet extends StatelessWidget {
  const _ReceiptFirstUseCameraIntroSheet({
    required this.area,
    required this.uiConfig,
  });

  final ReceiptCaptureArea area;
  final ReceiptCaptureUiConfig uiConfig;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              uiConfig.firstUseTitle,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              uiConfig.firstUsePrompt,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              uiConfig.firstUseExplanation,
              style: const TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Manual entry is always available.',
              style: TextStyle(
                color: Color(0xFF8FA0A8),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pop(_ReceiptFirstUseCameraAction.useReceiptAssist),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(uiConfig.enableAssistLabel),
              style: FilledButton.styleFrom(
                backgroundColor: uiConfig.primaryActionColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pop(_ReceiptFirstUseCameraAction.manualEntry),
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(uiConfig.manualEntryLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFD166),
                side: const BorderSide(color: Color(0xFFFFD166)),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can change this later in ${area.label} receipt settings.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8FA0A8),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
