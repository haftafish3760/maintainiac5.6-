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
                            'Keep the full receipt visible, avoid glare, hold steady for continuous focus, and pinch the preview to zoom when the print is small.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.receipt_long_rounded,
                        title: 'Long Receipts',
                        text:
                            'Use Add Another Photo for the next part of a long receipt. Repeat 3-5 readable lines in the top ghost slice so the app can match sections without duplicating lines.',
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
