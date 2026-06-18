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
                'Receipt Camera Help',
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
                        icon: Icons.auto_awesome_rounded,
                        title: 'Live Guidance',
                        text:
                            'Red means fix the photo, yellow means almost ready, and green means it looks readable.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.camera_rounded,
                        title: 'Manual Capture',
                        text:
                            'You can always tap the shutter. Guidance helps you aim but does not block a normal photo.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.burst_mode_rounded,
                        title: 'Best Shot',
                        text:
                            'Best Shot takes several frames, scores them, and lets you choose the clearest one.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.receipt_long_rounded,
                        title: 'Long Receipts',
                        text:
                            'Capture the receipt in sections, then use Add Additional Photos on the review screen before saving.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.flashlight_on_rounded,
                        title: 'Light',
                        text:
                            'Use the flashlight when the receipt is dark, but tilt the phone if glossy paper creates glare.',
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
