part of 'receipt_attachment_panel.dart';

class _ReceiptImportShareHint extends StatelessWidget {
  const _ReceiptImportShareHint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1416),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3D4A50)),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(10, 9, 10, 9),
        child: Text(
          'For emailed or texted receipts, use the phone Share button and choose Maintainiac, or save the receipt to your device and choose Upload PDF/File or Text File here.',
          style: TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ReceiptShareHelpSheet extends StatelessWidget {
  const _ReceiptShareHelpSheet();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Receipt Import Help',
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
                        title: 'Capture Receipt Photo',
                        text:
                            'Open Maintainiac receipt camera for a new paper receipt, then review the accepted photo before reading it.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.photo_library_rounded,
                        title: 'Upload Photos',
                        text:
                            'Choose one or more receipt photos already on this device. Use this for long receipts captured in multiple photos.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.folder_rounded,
                        title: 'Upload PDF/File',
                        text:
                            'Choose a PDF receipt from device storage, Drive, Files, or another document provider.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.description_rounded,
                        title: 'Text File',
                        text:
                            'Choose a saved text file when a receipt was exported or saved as plain text.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.content_paste_rounded,
                        title: 'Paste Text',
                        text:
                            'Paste receipt text you copied from email, messages, a website, or another app.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.ios_share_rounded,
                        title: 'Share Help',
                        text:
                            'From email, messages, photos, Drive, or Files, use the phone Share button and choose Maintainiac.',
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

class _ReceiptHelpRow extends StatelessWidget {
  const _ReceiptHelpRow({
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
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFD166), size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: Color(0xFFC8D0D3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
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
