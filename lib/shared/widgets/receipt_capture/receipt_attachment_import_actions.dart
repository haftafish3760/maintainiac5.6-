part of 'receipt_attachment_panel.dart';

enum _ReceiptImportAction {
  camera,
  image,
  pdf,
  savedText,
  pasteText,
  shareHelp,
}

extension _ReceiptAttachmentImportActions
    on _SharedReceiptAttachmentPanelState {
  Future<void> _takePhoto() async {
    if (_openingPicker) return;
    _updateAttachmentState(() => _openingPicker = true);
    try {
      final settings = ReceiptCaptureSettingsScope.maybeOf(context);
      if (settings != null && !settings.cameraSetupComplete) {
        final shouldOpenCamera = await _openReceiptCaptureSettings(
          setupMode: true,
        );
        if (!shouldOpenCamera || !mounted) {
          await _returnToReceiptImportOptions();
          return;
        }
      }
      final result = await Navigator.of(context).push<ReceiptCameraResult>(
        appNativeRoute(
          context,
          ReceiptCameraScreen(
            startAssisted:
                settings?.cameraGuidanceEnabled == true &&
                settings?.cameraStartAssisted == true,
            liveGuidanceEnabled: settings?.cameraGuidanceEnabled != false,
            autoCaptureEnabled:
                settings?.cameraGuidanceEnabled == true &&
                settings?.cameraAutoCapture == true,
            showLongReceiptTips: settings?.cameraLongReceiptTips != false,
          ),
        ),
      );
      if (result == null || result.photoPaths.isEmpty || !mounted) {
        await _returnToReceiptImportOptions();
        return;
      }
      await _reviewPickedCameraResult(result);
    } catch (_) {
      if (!mounted) return;
      _showPickerError('The receipt camera did not open correctly.');
    } finally {
      if (mounted) _updateAttachmentState(() => _openingPicker = false);
    }
  }

  Future<void> _uploadImage() async {
    await _pickAndReview(
      ReceiptImagePicker.chooseReceiptImage,
      fallbackMessage: 'The receipt photo picker did not open correctly.',
      platformFallback: 'Could not open the photo picker.',
    );
  }

  Future<void> _pickAndReview(
    Future<XFile?> Function() pickImage, {
    required String fallbackMessage,
    required String platformFallback,
  }) async {
    if (_openingPicker) return;
    _updateAttachmentState(() => _openingPicker = true);
    try {
      final image = await pickImage();
      if (image == null || !mounted) {
        await _returnToReceiptImportOptions();
        return;
      }
      await _reviewPickedImage(image);
    } on MissingPluginException {
      if (!mounted) return;
      _showPickerError(
        'Receipt photo picking is not available in this build. Reinstall the app and try again.',
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      final message = error.message?.trim();
      _showPickerError(
        message == null || message.isEmpty ? platformFallback : message,
      );
    } catch (_) {
      if (!mounted) return;
      _showPickerError(fallbackMessage);
    } finally {
      if (mounted) _updateAttachmentState(() => _openingPicker = false);
    }
  }

  Future<void> _reviewPickedImage(XFile image) async {
    await _reviewPickedPhotoPaths([image.path]);
  }

  Future<void> _reviewPickedCameraResult(ReceiptCameraResult result) async {
    if (!result.isBestShotCandidateSet) {
      await _reviewPickedPhotoPaths(result.photoPaths);
      return;
    }
    await _reviewBestShotCandidates(result);
  }

  Future<void> _reviewBestShotCandidates(
    ReceiptCameraResult cameraResult,
  ) async {
    final existingPaths = [..._photoPaths];
    final result = await Navigator.of(context).push<ReceiptPhotoReviewResult>(
      appNativeRoute(
        context,
        ReceiptPhotoReviewScreen(
          initialPhotoPaths: cameraResult.photoPaths,
          initialDataSaverLevel: _dataSaverLevel,
          bestShotCandidateMode: true,
          initialQualityChecks: cameraResult.qualityChecks,
        ),
      ),
    );
    if (result == null || !mounted) return;
    _updateAttachmentState(() {
      _photoPaths
        ..clear()
        ..addAll([...existingPaths, ...result.photoPaths]);
      _dataSaverLevel = result.dataSaverLevel;
    });
    _publishAttachmentChange();
    unawaited(_extractTextFromOriginalPhotos(result.ocrSourcePhotoPaths));
  }

  Future<void> _reviewPickedPhotoPaths(List<String> paths) async {
    final result = await Navigator.of(context).push<ReceiptPhotoReviewResult>(
      appNativeRoute(
        context,
        ReceiptPhotoReviewScreen(
          initialPhotoPaths: [..._photoPaths, ...paths],
          initialDataSaverLevel: _dataSaverLevel,
        ),
      ),
    );
    if (result == null || !mounted) return;
    _updateAttachmentState(() {
      _photoPaths
        ..clear()
        ..addAll(result.photoPaths);
      _dataSaverLevel = result.dataSaverLevel;
    });
    _publishAttachmentChange();
    unawaited(_extractTextFromOriginalPhotos(result.ocrSourcePhotoPaths));
  }

  Future<void> _reviewPhotos() async {
    if (_photoPaths.isEmpty) return;
    final result = await Navigator.of(context).push<ReceiptPhotoReviewResult>(
      appNativeRoute(
        context,
        ReceiptPhotoReviewScreen(
          initialPhotoPaths: _photoPaths,
          initialDataSaverLevel: _dataSaverLevel,
        ),
      ),
    );
    if (result == null || !mounted) return;
    _updateAttachmentState(() {
      _photoPaths
        ..clear()
        ..addAll(result.photoPaths);
      _dataSaverLevel = result.dataSaverLevel;
    });
    _publishAttachmentChange();
    unawaited(_extractTextFromOriginalPhotos(result.ocrSourcePhotoPaths));
  }

  Future<void> _extractTextFromOriginalPhotos(List<String> paths) async {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (widget.onImportedText == null ||
        paths.isEmpty ||
        settings?.appAssistedEnabledFor(widget.area) == false) {
      return;
    }
    final sourcePaths = paths;
    if (sourcePaths.isEmpty) return;
    final now = DateTime.now();
    final attachments = [
      for (var index = 0; index < sourcePaths.length; index++)
        ReceiptAttachmentRecord(
          id: 'RCPO-${now.microsecondsSinceEpoch}-$index',
          path: sourcePaths[index],
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: now,
          byteSize: _fileSize(sourcePaths[index]),
        ),
    ];
    final result = await const ReceiptOcrService().recognizeTextFromAttachments(
      attachments,
    );
    if (!mounted || !result.hasText) return;
    widget.onImportedText?.call(result.appFillText);
    if (result.warnings.isNotEmpty) {
      _showPickerMessage(result.warnings.first);
    }
  }

  Future<void> _openImportedTextSheet({
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
    _saveImportedTextAttachment(attachment);
  }

  Future<void> _pickImportedTextFile({
    required ReceiptAttachmentKind kind,
  }) async {
    if (_openingPicker) return;
    _updateAttachmentState(() => _openingPicker = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'text', 'eml', 'html', 'htm', 'csv'],
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty || !mounted) {
        await _returnToReceiptImportOptions();
        return;
      }
      final file = result.files.single;
      final path = file.path?.trim() ?? '';
      if (path.isEmpty) {
        _showPickerError('That saved receipt file could not be opened.');
        return;
      }
      final text = await File(path).readAsString();
      if (!mounted) return;
      final cleaned = text.trim();
      if (cleaned.isEmpty) {
        _showPickerError('That saved receipt file was empty.');
        return;
      }
      final now = DateTime.now();
      _saveImportedTextAttachment(
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
      _showPickerError(
        'Saved receipt file importing is not available in this build. Reinstall the app and try again.',
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      final message = error.message?.trim();
      _showPickerError(
        message == null || message.isEmpty
            ? 'Could not open the device file picker.'
            : message,
      );
    } catch (_) {
      if (!mounted) return;
      _showPickerError('The saved receipt file could not be imported.');
    } finally {
      if (mounted) _updateAttachmentState(() => _openingPicker = false);
    }
  }

  void _saveImportedTextAttachment(ReceiptAttachmentRecord attachment) {
    _updateAttachmentState(() {
      final index = _documentAttachments.indexWhere(
        (current) => current.id == attachment.id,
      );
      if (index == -1) {
        _documentAttachments.add(attachment);
      } else {
        _documentAttachments[index] = attachment;
      }
    });
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (settings?.appAssistedEnabledFor(widget.area) != false) {
      widget.onImportedText?.call(attachment.importedText);
    }
    _publishAttachmentChange();
  }

  Future<void> _editDocument(ReceiptAttachmentRecord attachment) async {
    if (attachment.isPdf) {
      await Navigator.of(context).push<void>(
        appNativeRoute(
          context,
          ReceiptPdfViewerScreen(
            path: attachment.path,
            title: attachment.label,
          ),
        ),
      );
      return;
    }
    if (!attachment.isImportedText) {
      _showPickerError('This receipt attachment can be removed or replaced.');
      return;
    }
    await _openImportedTextSheet(
      kind: attachment.kind,
      initialAttachment: attachment,
    );
  }

  Future<void> _readDocumentForReceipt(
    ReceiptAttachmentRecord attachment,
  ) async {
    if (!attachment.isPdf && !attachment.isImportedText) {
      _showPickerError('Only PDFs and imported text can be read from here.');
      return;
    }
    if (attachment.isPdf) {
      final inspection = await ReceiptPdfInspector.inspect(attachment.path);
      final blocker = inspection.importBlocker;
      if (blocker != null) {
        _showPickerError(blocker);
        return;
      }
      final assistedBlocker = inspection.assistedReadBlocker;
      if (assistedBlocker != null) {
        _showPickerError(assistedBlocker);
        return;
      }
      final shouldRead = await _confirmLongPdfReading([inspection]);
      if (!mounted || !shouldRead) return;
    }
    _updateAttachmentState(() => _openingPicker = true);
    try {
      final result = await _readAttachmentsForReceiptForm(
        [attachment],
        successMessage: attachment.isPdf
            ? 'PDF receipt proof was read into the form.'
            : 'Receipt text sent to the receipt form.',
        showDisabledMessage: true,
        showNoTextMessage: true,
      );
      if (attachment.isPdf) {
        _updateAttachmentState(() {
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
        _publishAttachmentChange();
      }
    } finally {
      if (mounted) _updateAttachmentState(() => _openingPicker = false);
    }
  }
}
