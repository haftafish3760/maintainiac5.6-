part of 'receipt_attachment_panel.dart';

extension _ReceiptImportSourceSheet on _SharedReceiptAttachmentPanelState {
  Future<void> openReceiptImportOptions({
    ReceiptImportEntryIntent intent =
        ReceiptImportEntryIntent.standardReceiptEntry,
  }) async {
    await _openReceiptImportOptionsTransaction(intent: intent);
  }

  Future<ReceiptImportActionResult?> _openReceiptImportOptionsTransaction({
    ReceiptImportEntryIntent intent =
        ReceiptImportEntryIntent.standardReceiptEntry,
    bool notifyOwnerOnExit = true,
  }) async {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (intent != ReceiptImportEntryIntent.optionalManualProof &&
        settings != null &&
        !settings.hasReceiptAssistChoiceFor(widget.area)) {
      final choiceSaved = await _showFirstUseReceiptAssistIntro(settings);
      if (!mounted || !choiceSaved) return null;
    }
    final result = await Navigator.of(context).push<ReceiptImportActionResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ReceiptImportSourceScreen(
          showCamera: widget.showCamera,
          intent: intent,
          onAction: (action) =>
              _handleReceiptImportSourceAction(action, intent: intent),
        ),
      ),
    );
    if (!mounted) return result;
    final reviewResult = result?.reviewResult;
    if (notifyOwnerOnExit && reviewResult?.exitsReceiptFlow == true) {
      await _notifyReviewedPhotoExitRequested(reviewResult!);
      return result;
    }
    if (result == null && widget.closeParentWhenImportCanceled && mounted) {
      await Navigator.of(context).maybePop();
    }
    return result;
  }

  /// Keeps the source chooser in place while the system picker, camera, or
  /// review route opens. Popping it first briefly revealed the parent screen
  /// between "Done" and photo review, which looked like a broken transition.
  Future<ReceiptImportActionResult> _handleReceiptImportSourceAction(
    ReceiptImportSourceAction action, {
    ReceiptImportEntryIntent intent =
        ReceiptImportEntryIntent.standardReceiptEntry,
  }) async {
    switch (action) {
      case ReceiptImportSourceAction.camera:
        return takeReceiptPhoto(
          skipFirstUseReceiptAssistIntro:
              intent == ReceiptImportEntryIntent.optionalManualProof,
        );
      case ReceiptImportSourceAction.image:
        return uploadReceiptImage();
      case ReceiptImportSourceAction.pdf:
        final previousAttachmentCount = _documentAttachments.length;
        await _pickPdfFiles();
        return _documentAttachments.length > previousAttachmentCount
            ? const ReceiptImportActionResult.completed()
            : const ReceiptImportActionResult.stayOnChooser();
      case ReceiptImportSourceAction.savedText:
        final previousAttachmentCount = _documentAttachments.length;
        await pickImportedTextFile(kind: ReceiptAttachmentKind.emailText);
        return _documentAttachments.length > previousAttachmentCount
            ? const ReceiptImportActionResult.completed()
            : const ReceiptImportActionResult.stayOnChooser();
      case ReceiptImportSourceAction.pasteText:
        final textAction = await _chooseReceiptTextImportAction();
        if (!mounted || textAction == null) {
          return const ReceiptImportActionResult.stayOnChooser();
        }
        final previousAttachmentCount = _documentAttachments.length;
        switch (textAction) {
          case _ReceiptTextImportAction.pasteText:
            await openImportedTextSheet(kind: ReceiptAttachmentKind.emailText);
          case _ReceiptTextImportAction.textFile:
            await pickImportedTextFile(kind: ReceiptAttachmentKind.emailText);
        }
        return _documentAttachments.length > previousAttachmentCount
            ? const ReceiptImportActionResult.completed()
            : const ReceiptImportActionResult.stayOnChooser();
      case ReceiptImportSourceAction.settings:
        await openReceiptCaptureSettings();
        return const ReceiptImportActionResult.stayOnChooser();
      case ReceiptImportSourceAction.shareHelp:
        await _showReceiptShareHelp();
        return const ReceiptImportActionResult.stayOnChooser();
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

  Future<_ReceiptTextImportAction?> _chooseReceiptTextImportAction() {
    return showModalBottomSheet<_ReceiptTextImportAction>(
      context: context,
      backgroundColor: const Color(0xFF161D20),
      showDragHandle: true,
      builder: (context) => const _ReceiptTextImportSheet(),
    );
  }
}

class ReceiptImportSourceScreen extends StatefulWidget {
  const ReceiptImportSourceScreen({
    super.key,
    required this.showCamera,
    required this.onAction,
    this.intent = ReceiptImportEntryIntent.standardReceiptEntry,
  });

  final bool showCamera;
  final ReceiptImportEntryIntent intent;
  final Future<ReceiptImportActionResult> Function(
    ReceiptImportSourceAction action,
  )
  onAction;

  @override
  State<ReceiptImportSourceScreen> createState() =>
      _ReceiptImportSourceScreenState();
}

class _ReceiptImportSourceScreenState extends State<ReceiptImportSourceScreen> {
  var _waitingForPhotoImport = false;
  var _actionInFlight = false;

  Future<void> _handleAction(ReceiptImportSourceAction action) async {
    if (_actionInFlight) return;
    final coversPhotoRoute =
        action == ReceiptImportSourceAction.image ||
        action == ReceiptImportSourceAction.camera;
    setState(() {
      _actionInFlight = true;
      _waitingForPhotoImport = coversPhotoRoute;
    });
    if (coversPhotoRoute) {
      // Paint the neutral handoff before the system picker or camera opens.
      // When either route returns, source choices stay covered while reviewed
      // photos are installed and any accepted receipt read is completed.
      await WidgetsBinding.instance.endOfFrame;
    }

    try {
      final result = await widget.onAction(action);
      if (!mounted) return;
      if (result.closesChooser) {
        Navigator.of(context).pop(result);
        return;
      }
      setState(() {
        _actionInFlight = false;
        _waitingForPhotoImport = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _actionInFlight = false;
        _waitingForPhotoImport = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That receipt source could not be opened. Try again or choose another source.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_actionInFlight,
      child: Scaffold(
        backgroundColor: const Color(0xFF161D20),
        body: _waitingForPhotoImport
            ? const _ReceiptPhotoImportHandoff()
            : _ReceiptImportSourceSheetBody(
                showCamera: widget.showCamera,
                intent: widget.intent,
                fullScreen: true,
                onAction: _handleAction,
              ),
      ),
    );
  }
}

class _ReceiptPhotoImportHandoff extends StatelessWidget {
  const _ReceiptPhotoImportHandoff();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Just a moment…',
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptImportSourceSheetBody extends StatelessWidget {
  const _ReceiptImportSourceSheetBody({
    required this.showCamera,
    this.intent = ReceiptImportEntryIntent.standardReceiptEntry,
    this.onAction,
    this.fullScreen = false,
  });

  final bool showCamera;
  final ReceiptImportEntryIntent intent;
  final Future<void> Function(ReceiptImportSourceAction action)? onAction;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final sources = <_ReceiptImportSource>[
      if (showCamera)
        const _ReceiptImportSource(
          action: ReceiptImportSourceAction.camera,
          icon: Icons.photo_camera_rounded,
          label: 'Capture Photo',
          detail: 'Take receipt photos, review them, then read the receipt.',
          color: Color(0xFF8EF6A4),
        ),
      const _ReceiptImportSource(
        action: ReceiptImportSourceAction.image,
        icon: Icons.photo_library_rounded,
        label: 'Upload Photos',
        detail: 'Choose one or more receipt images from this device.',
        color: Color(0xFFFFD166),
      ),
      const _ReceiptImportSource(
        action: ReceiptImportSourceAction.pdf,
        icon: Icons.folder_rounded,
        label: 'Upload PDF/File',
        detail: 'Use a downloaded receipt file or emailed PDF.',
        color: Color(0xFFA9DFFF),
      ),
      const _ReceiptImportSource(
        action: ReceiptImportSourceAction.pasteText,
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
                if (fullScreen)
                  IconButton(
                    tooltip: 'Back to receipt',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Expanded(
                  child: Text(
                    intent == ReceiptImportEntryIntent.optionalManualProof
                        ? 'Add image of your receipt'
                        : 'Add Receipt',
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Receipt settings',
                  onPressed: () => _selectAction(
                    context,
                    ReceiptImportSourceAction.settings,
                  ),
                  icon: const Icon(Icons.settings_rounded),
                ),
                IconButton(
                  tooltip: 'Receipt help',
                  onPressed: () => _selectAction(
                    context,
                    ReceiptImportSourceAction.shareHelp,
                  ),
                  icon: const Icon(Icons.help_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              intent == ReceiptImportEntryIntent.optionalManualProof
                  ? 'Take a photo or choose an image. You can also add a PDF or text copy.'
                  : 'Choose how you want to add this receipt.',
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final columns = constraints.maxWidth >= 340 ? 2 : 1;
                final tileWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final source in sources)
                      SizedBox(
                        width: tileWidth,
                        child: _ReceiptImportTile(
                          source: source,
                          onSelected: () => _selectSource(context, source),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectSource(
    BuildContext context,
    _ReceiptImportSource source,
  ) => _selectAction(context, source.action);

  Future<void> _selectAction(
    BuildContext context,
    ReceiptImportSourceAction action,
  ) async {
    final handler = onAction;
    if (handler == null) {
      Navigator.of(context).pop(action);
      return;
    }
    await handler(action);
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

  final ReceiptImportSourceAction action;
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
