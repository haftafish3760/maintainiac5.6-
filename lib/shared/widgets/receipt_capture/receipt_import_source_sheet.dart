part of 'receipt_attachment_panel.dart';

extension _ReceiptImportSourceSheet on _SharedReceiptAttachmentPanelState {
  Future<void> openReceiptImportOptions() async {
    final action = await Navigator.of(context).push<_ReceiptImportAction>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            _ReceiptImportSourceSheetBody(showCamera: widget.showCamera),
      ),
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
          label: 'Capture Receipt Photo',
          detail: 'Open Maintainiac receipt camera.',
          color: Color(0xFF8EF6A4),
        ),
      const _ReceiptImportSource(
        action: _ReceiptImportAction.image,
        icon: Icons.photo_library_rounded,
        label: 'Upload Receipt Photos',
        detail: 'Use saved receipt photos.',
        color: Color(0xFFFFD166),
      ),
      const _ReceiptImportSource(
        action: _ReceiptImportAction.pdf,
        icon: Icons.folder_rounded,
        label: 'Upload PDF/File',
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
    return Scaffold(
      backgroundColor: const Color(0xFF050607),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 6),
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
                      'Capture or upload receipt',
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
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_ReceiptImportAction.shareHelp),
                    child: const Text('Help'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                    children: [
                      _ReceiptPrimaryImportTile(
                        source: sources.firstWhere(
                          (source) =>
                              source.action == _ReceiptImportAction.camera,
                          orElse: () => sources.first,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: compact ? 1 : 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: compact ? 4.2 : 1.75,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final source in sources)
                            if (source.action != _ReceiptImportAction.camera)
                              _ReceiptImportTile(source: source),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _ReceiptImportShareHint(),
                    ],
                  );
                },
              ),
            ),
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
