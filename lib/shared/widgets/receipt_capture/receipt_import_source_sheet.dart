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
        final textAction = await _chooseReceiptTextImportAction();
        if (!mounted) return;
        if (textAction == null) {
          await returnToReceiptImportOptions();
          return;
        }
        switch (textAction) {
          case _ReceiptTextImportAction.pasteText:
            await openImportedTextSheet(kind: ReceiptAttachmentKind.emailText);
          case _ReceiptTextImportAction.textFile:
            await pickImportedTextFile(kind: ReceiptAttachmentKind.emailText);
        }
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

  Future<_ReceiptTextImportAction?> _chooseReceiptTextImportAction() {
    return showModalBottomSheet<_ReceiptTextImportAction>(
      context: context,
      backgroundColor: const Color(0xFF161D20),
      showDragHandle: true,
      builder: (context) => const _ReceiptTextImportSheet(),
    );
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
          label: 'Capture Photo',
          detail: 'Take receipt photos, review them, then read the receipt.',
          color: Color(0xFF8EF6A4),
        ),
      const _ReceiptImportSource(
        action: _ReceiptImportAction.image,
        icon: Icons.photo_library_rounded,
        label: 'Upload Photos',
        detail: 'Choose one or more receipt images from this device.',
        color: Color(0xFFFFD166),
      ),
      const _ReceiptImportSource(
        action: _ReceiptImportAction.pdf,
        icon: Icons.folder_rounded,
        label: 'Upload PDF/File',
        detail: 'Use a downloaded receipt file or emailed PDF.',
        color: Color(0xFFA9DFFF),
      ),
      const _ReceiptImportSource(
        action: _ReceiptImportAction.pasteText,
        icon: Icons.content_paste_rounded,
        label: 'Paste/Text',
        detail: 'Use copied receipt text when there is no photo.',
        color: Color(0xFF8FD3FF),
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
                    'Add Receipt',
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
            const SizedBox(height: 6),
            const Text(
              'Choose the source first. You review photos before Maintainiac reads anything.',
              style: TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            const _ReceiptImportFlowPreview(),
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

class _ReceiptImportFlowPreview extends StatelessWidget {
  const _ReceiptImportFlowPreview();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Capture or upload'),
      ('2', 'Review photos'),
      ('3', 'Use receipt'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1416),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Expanded(
                child: _ReceiptImportStepBadge(
                  number: steps[i].$1,
                  label: steps[i].$2,
                ),
              ),
              if (i != steps.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF95A3A8),
                    size: 18,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReceiptImportStepBadge extends StatelessWidget {
  const _ReceiptImportStepBadge({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFD166),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF101416),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
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

class _ReceiptTextImportSheet extends StatelessWidget {
  const _ReceiptTextImportSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste or import receipt text',
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use pasted text from email or messages, or choose a saved text receipt file from this device.',
              style: TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            _ReceiptTextImportTile(
              icon: Icons.content_paste_rounded,
              title: 'Paste Text',
              detail: 'Paste copied receipt text now.',
              onTap: () =>
                  Navigator.of(context).pop(_ReceiptTextImportAction.pasteText),
            ),
            const SizedBox(height: 8),
            _ReceiptTextImportTile(
              icon: Icons.description_rounded,
              title: 'Text File',
              detail: 'Choose a saved receipt text file.',
              onTap: () =>
                  Navigator.of(context).pop(_ReceiptTextImportAction.textFile),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptTextImportTile extends StatelessWidget {
  const _ReceiptTextImportTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFF0E1416),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3D4A50)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF8FD3FF), size: 22),
              const SizedBox(width: 10),
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
                      detail,
                      style: const TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8FA0A8)),
            ],
          ),
        ),
      ),
    );
  }
}
