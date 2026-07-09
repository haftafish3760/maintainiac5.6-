part of 'receipt_attachment_panel.dart';

class _ReceiptFirstUseCameraIntroSheet extends StatelessWidget {
  const _ReceiptFirstUseCameraIntroSheet({required this.area});

  final ReceiptCaptureArea area;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050607),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xDD11181B),
                      minimumSize: const Size(46, 46),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFF526168)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Receipt Assist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          color: Color(0xFFFFD166),
                          size: 44,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Would you like Maintainiac to help fill out receipt details?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFE8ECEE),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Receipt Assist reads the accepted photo and suggests totals and lines. You review everything before saving.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFC7D0D4),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.28,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Manual entry is always available for ${area.label.toLowerCase()} receipts.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF8FA0A8),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _ReceiptAssistPromiseCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_ReceiptFirstUseCameraAction.useReceiptAssist),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Yes, Use Receipt Assist'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
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
                    label: const Text('No, Manual Entry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD166),
                      side: const BorderSide(color: Color(0xFFFFD166)),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
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

class _ReceiptAssistPromiseCard extends StatelessWidget {
  const _ReceiptAssistPromiseCard();

  @override
  Widget build(BuildContext context) {
    const promises = [
      (Icons.visibility_rounded, 'You approve photos first'),
      (Icons.edit_note_rounded, 'You can edit every field'),
      (Icons.lock_outline_rounded, 'Manual entry stays available'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        child: Column(
          children: [
            for (final promise in promises) ...[
              Row(
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
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              if (promise != promises.last) const SizedBox(height: 7),
            ],
          ],
        ),
      ),
    );
  }
}
