part of 'receipt_attachment_panel.dart';

enum _PdfReceiptSelectionMode { addAllToReceipt, useFirstOnly }

enum _PdfReceiptReadMode { saveProofOnly, readIntoForm }

extension _ReceiptPdfImportActions on _SharedReceiptAttachmentPanelState {
  Future<void> _pickPdfFiles() async {
    if (_openingPicker) return;
    updateAttachmentState(() => _openingPicker = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: true,
        withData: false,
        lockParentWindow: true,
        dialogTitle: 'Choose Receipt PDF',
      );
      if (result == null || result.files.isEmpty || !mounted) {
        await returnToReceiptImportOptions();
        return;
      }
      final selectedFiles = result.files;
      final mode = selectedFiles.length <= 1
          ? _PdfReceiptSelectionMode.addAllToReceipt
          : await _chooseMultiplePdfMode(selectedFiles.length);
      if (!mounted || mode == null) return;
      final filesToAttach = switch (mode) {
        _PdfReceiptSelectionMode.addAllToReceipt => selectedFiles,
        _PdfReceiptSelectionMode.useFirstOnly => [selectedFiles.first],
      };
      final now = DateTime.now();
      final attachments = <ReceiptAttachmentRecord>[];
      final inspections = <ReceiptPdfInspection>[];
      final selectedHashes = <String>{};
      final selectedPaths = <String>{};
      var duplicateCount = 0;
      var blockedCount = 0;
      for (var index = 0; index < filesToAttach.length; index++) {
        final file = filesToAttach[index];
        final path = file.path?.trim() ?? '';
        if (path.isEmpty) continue;
        final inspection = await ReceiptPdfInspector.inspect(path);
        final blocker = inspection.importBlocker;
        if (blocker != null) {
          blockedCount += 1;
          showPickerError(blocker);
          continue;
        }
        final warning = inspection.userWarning;
        if (warning != null) {
          showPickerMessage(warning);
        }
        final storageCheck = await ReceiptStorageGuard.checkForBytes(
          requiredBytes: inspection.byteSize + (2 * 1024 * 1024),
          purpose: ReceiptStoragePurpose.importPdf,
        );
        if (!storageCheck.hasEnoughSpace) {
          showPickerError(
            storageCheck.blockingMessage(ReceiptStoragePurpose.importPdf),
          );
          continue;
        }
        if (!storageCheck.canVerify) {
          showPickerMessage(
            storageCheck.unknownMessage(ReceiptStoragePurpose.importPdf),
          );
        } else if (storageCheck.shouldWarnLowStorage) {
          showPickerMessage(storageCheck.warningMessage());
        }
        late final ReceiptAttachmentRecord attachment;
        try {
          attachment = await ReceiptProofStorage.instance.stageAttachment(
            ReceiptAttachmentRecord(
              id: 'RCPF-${now.microsecondsSinceEpoch}-$index',
              path: path,
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: _dataSaverLevel,
              createdAt: now,
              displayName: file.name,
              originalFileName: file.name,
              mimeType: 'application/pdf',
              byteSize: inspection.byteSize,
              pageCount: inspection.pageCount,
              pageCountStatus: inspection.pageCountStatus,
              validationStatus: inspection.validationStatus,
              riskFlags: inspection.riskFlags,
              documentSignals: inspection.documentSignals,
              sourceLabel: 'Files',
            ),
          );
        } on ReceiptProofStorageException catch (error) {
          blockedCount += 1;
          showPickerError(error.message);
          continue;
        }
        final duplicateInCurrentForm = _hasDuplicateAttachment(attachment);
        final duplicateInSelection = _isDuplicatePdfSelection(
          attachment,
          selectedHashes,
          selectedPaths,
        );
        if (duplicateInCurrentForm || duplicateInSelection) {
          duplicateCount += 1;
          unawaited(
            ReceiptProofStorage.instance.deleteStagedAttachment(attachment),
          );
          showPickerMessage('${attachment.label} is already attached.');
        } else {
          _rememberPdfSelection(attachment, selectedHashes, selectedPaths);
          attachments.add(attachment);
          inspections.add(inspection);
        }
      }
      if (attachments.isEmpty) {
        if (duplicateCount > 0 && blockedCount == 0) {
          showPickerMessage(
            duplicateCount == 1
                ? 'That PDF is already attached to this receipt.'
                : 'Those PDFs are already attached to this receipt.',
          );
        } else {
          showPickerError('That PDF could not be opened from this device.');
        }
        return;
      }
      updateAttachmentState(() => _documentAttachments.addAll(attachments));
      publishAttachmentChange();
      final readMode = await _choosePdfReadMode(
        attachments.length,
        inspections,
      );
      if (!mounted) return;
      if (readMode != _PdfReceiptReadMode.readIntoForm) {
        showPickerMessage(_pdfAttachedMessage(attachments.length));
        return;
      }
      final readableAttachments = <ReceiptAttachmentRecord>[];
      final readableInspections = <ReceiptPdfInspection>[];
      final proofOnlyAttachments = <ReceiptAttachmentRecord>[];
      for (var index = 0; index < attachments.length; index++) {
        if (inspections[index].canUseAssistedRead) {
          readableAttachments.add(attachments[index]);
          readableInspections.add(inspections[index]);
        } else {
          proofOnlyAttachments.add(attachments[index]);
        }
      }
      if (readableAttachments.isEmpty) {
        showPickerMessage(_pdfAttachedMessage(attachments.length));
        return;
      }
      if (proofOnlyAttachments.isNotEmpty) {
        _markAttachmentsRead(
          proofOnlyAttachments,
          ReceiptAttachmentReadState.notRead,
        );
        showPickerMessage(
          '${proofOnlyAttachments.length} PDF${proofOnlyAttachments.length == 1 ? '' : 's'} saved as read-only proof only.',
        );
      }
      final shouldRead = await _confirmLongPdfReading(readableInspections);
      if (!mounted || !shouldRead) {
        showPickerMessage(_pdfAttachedMessage(attachments.length));
        return;
      }
      final read = await _readAttachmentsForReceiptForm(
        readableAttachments,
        successMessage: readableAttachments.length == 1
            ? 'PDF receipt proof opened receipt details.'
            : '${readableAttachments.length} PDF receipts opened receipt details.',
      );
      if (read.didRead) {
        _markAttachmentsRead(
          readableAttachments,
          ReceiptAttachmentReadState.readIntoForm,
        );
      }
      if (!mounted || read.didRead) return;
      if (read.wasUnreadable) {
        _markAttachmentsRead(
          readableAttachments,
          ReceiptAttachmentReadState.unreadable,
        );
        final warning = read.warning.trim().isEmpty
            ? 'PDF attached as proof, but receipt text could not be read.'
            : '${read.warning} PDF attached as proof.';
        showPickerError(warning);
        return;
      }
      if (mounted) {
        showPickerMessage(_pdfAttachedMessage(attachments.length));
      }
    } on MissingPluginException {
      if (!mounted) return;
      showPickerError(
        'PDF picking is not available in this build. Reinstall the app and try again.',
      );
    } on ReceiptProofStorageException catch (error) {
      if (!mounted) return;
      showPickerError(error.message);
    } on PlatformException catch (error) {
      if (!mounted) return;
      final message = error.message?.trim();
      showPickerError(
        message == null || message.isEmpty
            ? 'The PDF picker could not be opened.'
            : message,
      );
    } catch (_) {
      if (!mounted) return;
      showPickerError('The PDF picker did not open correctly.');
    } finally {
      if (mounted) updateAttachmentState(() => _openingPicker = false);
    }
  }

  bool _hasDuplicateAttachment(ReceiptAttachmentRecord attachment) {
    final hash = attachment.fileHash.trim();
    return _documentAttachments.any((current) {
      if (hash.isNotEmpty && current.fileHash == hash) return true;
      return current.path.trim().isNotEmpty && current.path == attachment.path;
    });
  }

  void _markAttachmentsRead(
    List<ReceiptAttachmentRecord> attachments,
    ReceiptAttachmentReadState readState,
  ) {
    if (!mounted || attachments.isEmpty) return;
    final ids = attachments.map((attachment) => attachment.id).toSet();
    updateAttachmentState(() {
      for (var index = 0; index < _documentAttachments.length; index++) {
        final current = _documentAttachments[index];
        if (ids.contains(current.id)) {
          _documentAttachments[index] = current.copyWith(readState: readState);
        }
      }
    });
    publishAttachmentChange();
  }
}
