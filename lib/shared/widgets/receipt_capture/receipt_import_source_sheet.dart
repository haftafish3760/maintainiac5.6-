part of 'receipt_attachment_panel.dart';

extension _ReceiptImportSourceSheet on _SharedReceiptAttachmentPanelState {
  Future<void> openReceiptImportOptions() async {
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
        await takeReceiptPhoto();
      case _ReceiptImportAction.image:
        await uploadReceiptImage();
      case _ReceiptImportAction.pdf:
        await _pickPdfFiles();
      case _ReceiptImportAction.savedText:
        await pickImportedTextFile(kind: ReceiptAttachmentKind.emailText);
      case _ReceiptImportAction.pasteText:
        await openImportedTextSheet(kind: ReceiptAttachmentKind.emailText);
      case _ReceiptImportAction.shareHelp:
        await _showReceiptShareHelp();
        await returnToReceiptImportOptions();
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

  Future<void> returnToReceiptImportOptions() async {
    if (!mounted) return;
    updateAttachmentState(() => _openingPicker = false);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted) await openReceiptImportOptions();
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
