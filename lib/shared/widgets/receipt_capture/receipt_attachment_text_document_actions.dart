part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentTextDocumentActions
    on _SharedReceiptAttachmentPanelState {
  Future<void> openImportedTextSheet({
    required ReceiptAttachmentKind kind,
    ReceiptAttachmentRecord? initialAttachment,
  }) async {
    final attachment = await showModalBottomSheet<ReceiptAttachmentRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2528),
      builder: (context) => _ImportedReceiptTextSheet(
        kind: kind,
        initialAttachment: initialAttachment,
      ),
    );
    if (attachment == null || !mounted) return;
    await _saveImportedTextAttachment(attachment);
  }

  Future<void> pickImportedTextFile({
    required ReceiptAttachmentKind kind,
  }) async {
    if (_openingPicker) return;
    updateAttachmentState(() => _openingPicker = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'text', 'eml', 'html', 'htm', 'csv'],
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty || !mounted) {
        return;
      }
      final file = result.files.single;
      final path = file.path?.trim() ?? '';
      if (path.isEmpty) {
        showPickerError('That saved receipt file could not be opened.');
        return;
      }
      final text = await File(path).readAsString();
      if (!mounted) return;
      final cleaned = text.trim();
      if (cleaned.isEmpty) {
        showPickerError('That saved receipt file was empty.');
        return;
      }
      final now = DateTime.now();
      await _saveImportedTextAttachment(
        ReceiptAttachmentRecord(
          id: 'RCPT-${now.microsecondsSinceEpoch}',
          path: path,
          kind: kind,
          dataSaverLevel: _dataSaverLevel,
          createdAt: now,
          displayName: file.name,
          importedText: cleaned,
          byteSize: file.size > 0 ? file.size : cleaned.length,
        ),
      );
    } on MissingPluginException {
      if (!mounted) return;
      showPickerError(
        'Saved receipt file importing is not available in this build. Reinstall the app and try again.',
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      final message = error.message?.trim();
      showPickerError(
        message == null || message.isEmpty
            ? 'Could not open the device file picker.'
            : message,
      );
    } catch (_) {
      if (!mounted) return;
      showPickerError('The saved receipt file could not be imported.');
    } finally {
      if (mounted) updateAttachmentState(() => _openingPicker = false);
    }
  }

  Future<void> _saveImportedTextAttachment(
    ReceiptAttachmentRecord attachment,
  ) async {
    updateAttachmentState(() {
      final index = _documentAttachments.indexWhere(
        (current) => current.id == attachment.id,
      );
      if (index == -1) {
        _documentAttachments.add(attachment);
      } else {
        _documentAttachments[index] = attachment;
      }
    });
    if (_appAssistedReceiptFillEnabled) {
      final onImportedText = widget.onImportedText;
      if (onImportedText != null) {
        await Future<void>.sync(() => onImportedText(attachment.importedText));
      }
    }
    publishAttachmentChange();
  }

  Future<void> editReceiptDocument(ReceiptAttachmentRecord attachment) async {
    if (attachment.isPdf) {
      final capability =
          ReceiptCaptureSettingsScope.maybeOf(context)?.deviceCapability ??
          const ReceiptDeviceCapability.standard();
      await Navigator.of(context).push<void>(
        appNativeRoute(
          context,
          ReceiptPdfViewerScreen(
            path: attachment.path,
            title: attachment.label,
            performanceProfile: ReceiptPdfPerformanceProfile.fromCapability(
              capability,
            ),
          ),
        ),
      );
      return;
    }
    if (!attachment.isImportedText) {
      showPickerError('This receipt attachment can be removed or replaced.');
      return;
    }
    await openImportedTextSheet(
      kind: attachment.kind,
      initialAttachment: attachment,
    );
  }

  Future<void> readDocumentForReceipt(
    ReceiptAttachmentRecord attachment,
  ) async {
    if (!attachment.isPdf && !attachment.isImportedText) {
      showPickerError('Only PDFs and imported text can be read from here.');
      return;
    }
    if (attachment.isPdf) {
      final inspection = await ReceiptPdfInspector.inspect(attachment.path);
      final blocker = inspection.importBlocker;
      if (blocker != null) {
        showPickerError(blocker);
        return;
      }
      final assistedBlocker = inspection.assistedReadBlocker;
      if (assistedBlocker != null) {
        showPickerError(assistedBlocker);
        return;
      }
      final shouldRead = await _confirmLongPdfReading([inspection]);
      if (!mounted || !shouldRead) return;
    }
    updateAttachmentState(() => _openingPicker = true);
    try {
      final result = await _readAttachmentsForReceiptForm(
        [attachment],
        successMessage: attachment.isPdf
            ? 'PDF receipt opened receipt details.'
            : 'Receipt photo opened receipt details.',
        showDisabledMessage: true,
        showNoTextMessage: true,
      );
      if (attachment.isPdf) {
        updateAttachmentState(() {
          final index = _documentAttachments.indexWhere(
            (current) => current.id == attachment.id,
          );
          if (index != -1) {
            _documentAttachments[index] = _documentAttachments[index].copyWith(
              readState: result.didRead
                  ? ReceiptAttachmentReadState.readIntoForm
                  : result.wasUnreadable
                  ? ReceiptAttachmentReadState.unreadable
                  : _documentAttachments[index].readState,
            );
          }
        });
        publishAttachmentChange();
      }
    } finally {
      if (mounted) updateAttachmentState(() => _openingPicker = false);
    }
  }
}
