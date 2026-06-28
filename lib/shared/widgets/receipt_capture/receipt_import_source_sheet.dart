part of 'receipt_attachment_panel.dart';

extension _ReceiptImportSourceSheet on _SharedReceiptAttachmentPanelState {
  Future<void> _openReceiptImportOptions() async {
    final action = await showModalBottomSheet<_ReceiptImportAction>(
      context: context,
      backgroundColor: const Color(0xFF161D20),
      showDragHandle: true,
      builder: (context) {
        return _ReceiptImportSourceSheetBody(showCamera: widget.showCamera);
      },
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _ReceiptImportAction.camera:
        await _takePhoto();
      case _ReceiptImportAction.image:
        await _uploadImage();
      case _ReceiptImportAction.pdf:
        await _pickPdfFiles();
      case _ReceiptImportAction.savedText:
        await _pickImportedTextFile(kind: ReceiptAttachmentKind.emailText);
      case _ReceiptImportAction.pasteText:
        await _openImportedTextSheet(kind: ReceiptAttachmentKind.emailText);
      case _ReceiptImportAction.shareHelp:
        await _showReceiptShareHelp();
        await _returnToReceiptImportOptions();
    }
  }

  Future<void> _showReceiptShareHelp() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161D20),
      showDragHandle: true,
      builder: (context) => const _ReceiptShareHelpSheet(),
    );
  }

  Future<void> _returnToReceiptImportOptions() async {
    if (!mounted) return;
    _updateAttachmentState(() => _openingPicker = false);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted) await _openReceiptImportOptions();
  }
}

class _ReceiptImportSourceSheetBody extends StatelessWidget {
  const _ReceiptImportSourceSheetBody({required this.showCamera});

  final bool showCamera;

  @override
  Widget build(BuildContext context) {
    final sources = <_ReceiptImportSource>[
      if (showCamera)
        const _ReceiptImportSource(
          action: _ReceiptImportAction.camera,
          icon: Icons.photo_camera_rounded,
          label: 'Take Receipt Photo',
          detail: 'Open Maintainiac receipt camera.',
          color: Color(0xFF8EF6A4),
        ),
      const _ReceiptImportSource(
        action: _ReceiptImportAction.image,
        icon: Icons.photo_library_rounded,
        label: 'Gallery Photos',
        detail: 'Use saved receipt photos.',
        color: Color(0xFFFFD166),
      ),
      const _ReceiptImportSource(
        action: _ReceiptImportAction.pdf,
        icon: Icons.folder_rounded,
        label: 'PDF Or File',
        detail: 'Import downloaded receipts.',
        color: Color(0xFFA9DFFF),
      ),
      const _ReceiptImportSource(
        action: _ReceiptImportAction.savedText,
        icon: Icons.description_rounded,
        label: 'Text File',
        detail: 'Use copied receipt text.',
        color: Color(0xFFFF8FA3),
      ),
      const _ReceiptImportSource(
        action: _ReceiptImportAction.pasteText,
        icon: Icons.content_paste_rounded,
        label: 'Paste Text',
        detail: 'Paste receipt text here.',
        color: Color(0xFF8FD3FF),
      ),
      const _ReceiptImportSource(
        action: _ReceiptImportAction.shareHelp,
        icon: Icons.ios_share_rounded,
        label: 'Share Help',
        detail: 'Send receipts into the app.',
        color: Color(0xFFC7B8FF),
      ),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Add receipt',
                    style: TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_ReceiptImportAction.shareHelp),
                  child: const Text('Help'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.75,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final source in sources)
                  _ReceiptImportTile(source: source),
              ],
            ),
            const SizedBox(height: 14),
            const _ReceiptImportShareHint(),
          ],
        ),
      ),
    );
  }
}

class _ReceiptImportSource {
  const _ReceiptImportSource({
    required this.action,
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });

  final _ReceiptImportAction action;
  final IconData icon;
  final String label;
  final String detail;
  final Color color;
}

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
          'For emailed or texted receipts, use the phone Share button and choose Maintainiac, or save the receipt to your device and choose PDF Or File or Text File here.',
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
                        title: 'Take Receipt Photo',
                        text:
                            'Open Maintainiac receipt camera for a new paper receipt, then review the accepted photo before reading it.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.photo_library_rounded,
                        title: 'Gallery',
                        text:
                            'Choose one or more receipt photos already on this device. Use this for long receipts captured in multiple photos.',
                      ),
                      _ReceiptHelpRow(
                        icon: Icons.folder_rounded,
                        title: 'PDF Or File',
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
