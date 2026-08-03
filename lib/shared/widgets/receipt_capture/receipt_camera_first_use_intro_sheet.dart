part of 'receipt_attachment_panel.dart';

/// A short, non-blocking first-use choice shown from the receipt source sheet.
/// It records a preference; it never changes the receipt fields themselves.
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
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: SizedBox(
                    width: 36,
                    child: Divider(color: Color(0xFF69777E), thickness: 3),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFFD166),
                      size: 24,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        uiConfig.firstUseTitle,
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFFC7D0D4),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  uiConfig.firstUsePrompt,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  uiConfig.firstUseExplanation,
                  style: const TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.28,
                  ),
                ),
                const SizedBox(height: 12),
                _ReceiptAssistPromiseCard(uiConfig: uiConfig),
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
                    minimumSize: const Size.fromHeight(50),
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
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manual entry is always available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8FA0A8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can change this later in ${area.label} receipt settings.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8FA0A8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptAssistPromiseCard extends StatelessWidget {
  const _ReceiptAssistPromiseCard({required this.uiConfig});

  final ReceiptCaptureUiConfig uiConfig;

  @override
  Widget build(BuildContext context) {
    const promises = [
      (Icons.visibility_rounded, 'You approve photos first'),
      (Icons.edit_note_rounded, 'You can edit every field'),
      (Icons.lock_outline_rounded, 'Manual entry stays available'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: uiConfig.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: uiConfig.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            for (final promise in promises)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(promise.$1, color: const Color(0xFFFFD166), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        promise.$2,
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
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
