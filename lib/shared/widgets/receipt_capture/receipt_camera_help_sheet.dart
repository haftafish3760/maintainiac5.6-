part of 'receipt_attachment_panel.dart';

Future<void> _showReceiptCameraHelp(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF161D20),
    showDragHandle: true,
    builder: (context) => const _ReceiptCameraHelpSheet(),
  );
}

class _ReceiptCameraHelpSheet extends StatelessWidget {
  const _ReceiptCameraHelpSheet();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Receipt Photo Help',
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              const Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ReceiptHelpRow(
                        icon: Icons.photo_camera_rounded,
                        title: 'Take A Clear Receipt Photo',
                        text:
                            'Keep the full receipt visible, avoid glare, tap receipt text to focus, and pinch the preview to zoom when the print is small.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.receipt_long_rounded,
                        title: 'Long Receipts',
                        text:
                            'Use Add Another Photo for the next part of a long receipt. Overlap a few lines so the app can avoid repeated lines when it reads the receipt.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.burst_mode_rounded,
                        title: 'Best-Photo Burst',
                        text:
                            'Some captures keep more than one candidate photo. Pick the clearest readable photo before moving on.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.document_scanner_rounded,
                        title: 'App-Assisted Receipt Fill',
                        text:
                            'When assistance is on, Maintainiac reads the photo, PDF, or imported text and fills out what it can. You review the result before saving.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Business, Personal, Or Split',
                        text:
                            'For a mixed receipt, mark each line as business, personal, or split so totals and tax can be separated correctly.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.cloud_upload_outlined,
                        title: 'Storage And Backup',
                        text:
                            'Maintainiac reads the clearest accepted image, then saves a smaller receipt image for review and backup unless you choose otherwise.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got It'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptFirstUseCameraIntroSheet extends StatelessWidget {
  const _ReceiptFirstUseCameraIntroSheet({
    required this.area,
    required this.profile,
  });

  final ReceiptCaptureArea area;
  final ReceiptCameraRuntimeProfile profile;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Before Your First Receipt Photo',
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'These tips apply when adding ${area.label.toLowerCase()} receipts.',
              style: const TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            _ReceiptFirstUseCameraRuntimeCard(profile: profile),
            const SizedBox(height: 10),
            const _ReceiptFirstUseTip(
              icon: Icons.center_focus_strong_rounded,
              title: 'Clear Photo First',
              text:
                  'Keep the receipt readable, avoid glare, and tap printed text to focus when needed.',
            ),
            const _ReceiptFirstUseTip(
              icon: Icons.receipt_long_rounded,
              title: 'Long Receipts',
              text:
                  'Use Add Another Photo and overlap a few lines so Maintainiac can match sections safely.',
            ),
            const _ReceiptFirstUseTip(
              icon: Icons.fact_check_rounded,
              title: 'Review Before Saving',
              text:
                  'If app-assisted fill is on, Maintainiac reads the receipt and then shows what it found for you to review.',
            ),
            const _ReceiptFirstUseTip(
              icon: Icons.lock_outline_rounded,
              title: 'Storage And Privacy',
              text:
                  'OCR uses the clear photo first. The smaller saved proof is only for review and backup.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pop(_ReceiptFirstUseCameraAction.continueToCamera),
              icon: const Icon(Icons.photo_camera_rounded),
              label: const Text('Continue To Camera'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF28A745),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
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
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
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
