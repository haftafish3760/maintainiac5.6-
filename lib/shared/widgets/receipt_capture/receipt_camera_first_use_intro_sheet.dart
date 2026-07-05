part of 'receipt_attachment_panel.dart';

class _ReceiptFirstUseCameraIntroSheet extends StatelessWidget {
  const _ReceiptFirstUseCameraIntroSheet({
    required this.area,
    required this.profile,
    required this.installChoice,
  });

  final ReceiptCaptureArea area;
  final ReceiptCameraRuntimeProfile profile;
  final ReceiptParserPackInstallChoice installChoice;

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
                      'Receipt Camera Setup',
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  Text(
                    'These tips apply when adding ${area.label.toLowerCase()} receipts.',
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ReceiptFirstUseCameraRuntimeCard(profile: profile),
                  const SizedBox(height: 12),
                  const _ReceiptFirstUseTip(
                    icon: Icons.center_focus_strong_rounded,
                    title: 'Clear Photo First',
                    text:
                        'Keep the receipt readable, avoid glare, and hold steady while the phone camera refocuses.',
                  ),
                  const _ReceiptFirstUseTip(
                    icon: Icons.receipt_long_rounded,
                    title: 'Long Receipts',
                    text:
                        'Use Add Photo and repeat a few readable lines so Maintainiac can match receipt sections safely.',
                  ),
                  const _ReceiptFirstUseTip(
                    icon: Icons.fact_check_rounded,
                    title: 'App-Assisted Fill',
                    text:
                        'Maintainiac can read the receipt and suggest fields, but you review before anything is trusted.',
                  ),
                  const _ReceiptFirstUseTip(
                    icon: Icons.tune_rounded,
                    title: 'Receipt Controls',
                    text:
                        'Use flash, readability guidance, long receipt help, and proof-size settings when they help.',
                  ),
                  _ReceiptFirstUseTip(
                    icon: Icons.lock_outline_rounded,
                    title: 'Storage And Privacy',
                    text:
                        'OCR uses the clear working photo first. The saved proof follows your storage setting. ${installChoice.userFacingDownloadChoiceLabel}',
                  ),
                ],
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
                    ).pop(_ReceiptFirstUseCameraAction.continueToCamera),
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Continue To Camera'),
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
                    ).pop(_ReceiptFirstUseCameraAction.openSettings),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Open Receipt Settings'),
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

class _ReceiptFirstUseCameraRuntimeCard extends StatelessWidget {
  const _ReceiptFirstUseCameraRuntimeCard({required this.profile});

  final ReceiptCameraRuntimeProfile profile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD166)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                profile.summaryLabel,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptFirstUseTip extends StatelessWidget {
  const _ReceiptFirstUseTip({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFD166), size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFC7D0D4),
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
    );
  }
}
