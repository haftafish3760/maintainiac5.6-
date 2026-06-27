part of 'receipt_attachment_panel.dart';

enum _ReceiptImportAction {
  camera,
  image,
  pdf,
  savedText,
  pasteText,
  shareHelp,
}

enum _ReceiptFirstUseCameraAction { continueToCamera, openSettings }

extension _ReceiptAttachmentImportActions
    on _SharedReceiptAttachmentPanelState {
  Future<void> _takePhoto() async {
    if (_openingPicker) return;
    _updateAttachmentState(() => _openingPicker = true);
    try {
      final settings = ReceiptCaptureSettingsScope.maybeOf(context);
      if (settings != null && !settings.cameraSetupComplete) {
        final ready = await _showFirstUseReceiptCameraIntro(settings);
        if (!mounted || !ready) return;
      }
      if (NativeReceiptScannerService.documentScannerAllowedOnThisPlatform) {
        final scanResult = await const NativeReceiptScannerService()
            .scanReceipt(
              pageLimit:
                  settings?.deviceCapability.maxLocalPhotoCount ??
                  const ReceiptDeviceCapability.standard().maxLocalPhotoCount,
              allowGalleryImport: false,
            );
        if (scanResult.hasScannedPages) {
          final cameraResult = scanResult.cameraResult!;
          await _reviewPickedPhotoPaths(
            cameraResult.photoPaths,
            initialQualityChecksByPath: _qualityChecksByPathForCameraResult(
              cameraResult,
            ),
          );
          return;
        }
        if (scanResult.status == ReceiptNativeScanStatus.canceled) {
          if (mounted) await _returnToReceiptImportOptions();
          return;
        }
        _showScannerFallbackNotice(scanResult);
      }
      await _takeNativeCameraPhotoFallback();
    } on MissingPluginException {
      if (!mounted) return;
      _showScannerFallbackNotice(
        const ReceiptNativeScanResult.unavailable(
          'Document scanning is not available in this build.',
        ),
      );
      await _takeNativeCameraPhotoFallback();
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showPickerError(_nativeCameraOpenErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showPickerError(
        'The receipt camera did not open. Try Take Receipt Photo again, or choose an existing receipt image instead.',
      );
    } finally {
      if (mounted) _updateAttachmentState(() => _openingPicker = false);
    }
  }

  Future<bool> _showFirstUseReceiptCameraIntro(
    ReceiptCaptureSettingsController settings,
  ) async {
    final action = await showModalBottomSheet<_ReceiptFirstUseCameraAction>(
      context: context,
      backgroundColor: const Color(0xFF161D20),
      showDragHandle: true,
      builder: (context) => _ReceiptFirstUseCameraIntroSheet(
        area: widget.area,
        profile: settings.effectiveCameraRuntimeProfile,
      ),
    );
    if (!mounted || action == null) return false;
    await settings.setCameraSetupComplete(true);
    if (!mounted) return false;
    if (action == _ReceiptFirstUseCameraAction.openSettings) {
      return _openReceiptCaptureSettings();
    }
    return true;
  }

  Future<void> _takeNativeCameraPhotoFallback() async {
    final picked = await ReceiptImagePicker.takeReceiptPhotoSet();
    if (picked.isEmpty || !mounted) {
      await _returnToReceiptImportOptions();
      return;
    }
    await _reviewPickedPhotoPaths(
      picked.paths,
      initialQualityChecksByPath: await _qualityChecksForPhotoPaths(
        picked.paths,
      ),
    );
  }

  void _showScannerFallbackNotice(ReceiptNativeScanResult result) {
    if (!mounted || result.status == ReceiptNativeScanStatus.scanned) return;
    final detail = result.message.trim();
    final message = detail.isEmpty
        ? 'Document scanner was not available. Opening the phone camera instead so you can still capture the receipt.'
        : '$detail Opening the phone camera instead so you can still capture the receipt.';
    _showPickerError(message);
  }

  String _nativeCameraOpenErrorMessage(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = error.message?.trim();
    final combined = '$code ${message ?? ''}'.toLowerCase();
    if (combined.contains('permission') ||
        combined.contains('denied') ||
        combined.contains('restricted')) {
      return 'Camera permission is blocked. Open your phone settings, allow camera access for Maintainiac, then try Take Receipt Photo again.';
    }
    if (combined.contains('cancel')) {
      return 'Camera was canceled. No receipt photo was added.';
    }
    if (message != null && message.isNotEmpty) {
      return '$message Try Take Receipt Photo again, or choose an existing receipt image instead.';
    }
    return 'The phone camera could not open. Try Take Receipt Photo again, or choose an existing receipt image instead.';
  }

  Future<void> _uploadImage() async {
    await _pickAndReviewMultiple(
      ReceiptImagePicker.chooseReceiptImageSet,
      fallbackMessage: 'The receipt photo picker did not open correctly.',
      platformFallback: 'Could not open the photo picker.',
    );
  }

  Future<void> _pickAndReviewMultiple(
    Future<ReceiptPickedPhotoSet> Function() pickImages, {
    required String fallbackMessage,
    required String platformFallback,
  }) async {
    if (_openingPicker) return;
    _updateAttachmentState(() => _openingPicker = true);
    try {
      final picked = await pickImages();
      if (picked.isEmpty || !mounted) {
        await _returnToReceiptImportOptions();
        return;
      }
      await _reviewPickedPhotoPaths(
        picked.paths,
        initialQualityChecksByPath: await _qualityChecksForPhotoPaths(
          picked.paths,
        ),
      );
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

  Future<void> _reviewPickedPhotoPaths(
    List<String> paths, {
    Map<String, ReceiptPhotoQualityCheck> initialQualityChecksByPath = const {},
  }) async {
    final firstNewPhotoIndex = _photoPaths.length;
    final previousPhotoIdByPath = {..._photoIdByPath};
    final result = await Navigator.of(context).push<ReceiptPhotoReviewResult>(
      appNativeRoute(
        context,
        ReceiptPhotoReviewScreen(
          initialPhotoPaths: [..._photoPaths, ...paths],
          initialDataSaverLevel: _dataSaverLevel,
          initialSelectedIndex: firstNewPhotoIndex,
          initialQualityChecksByPath: {
            ..._photoQualityByPath,
            ...initialQualityChecksByPath,
          },
        ),
      ),
    );
    if (result == null || !mounted) return;
    _updateAttachmentState(() {
      _photoPaths
        ..clear()
        ..addAll(result.photoPaths);
      _photoIdByPath
        ..clear()
        ..addEntries(
          result.photoPaths
              .where(previousPhotoIdByPath.containsKey)
              .map((path) => MapEntry(path, previousPhotoIdByPath[path]!)),
        );
      _photoQualityByPath
        ..clear()
        ..addAll(result.photoQualityChecksByPath);
      _photoReadStateByPath
        ..clear()
        ..addEntries(
          result.photoPaths.map(
            (path) => MapEntry(path, ReceiptAttachmentReadState.notRead),
          ),
        );
      _dataSaverLevel = result.dataSaverLevel;
    });
    _publishAttachmentChange();
    final readResult = await _readReviewedPhotosForReceiptForm(result);
    _markReviewedPhotosReadState(result, readResult);
    unawaited(_deleteTemporaryOcrPhotos(result.ocrSourcePhotoPaths));
  }

  Future<void> _reviewPhotos() async {
    if (_photoPaths.isEmpty) return;
    final previousPhotoIdByPath = {..._photoIdByPath};
    final previousPhotoReadStateByPath = {..._photoReadStateByPath};
    final result = await Navigator.of(context).push<ReceiptPhotoReviewResult>(
      appNativeRoute(
        context,
        ReceiptPhotoReviewScreen(
          initialPhotoPaths: _photoPaths,
          initialDataSaverLevel: _dataSaverLevel,
          initialQualityChecksByPath: _photoQualityByPath,
        ),
      ),
    );
    if (result == null || !mounted) return;
    _updateAttachmentState(() {
      _photoPaths
        ..clear()
        ..addAll(result.photoPaths);
      _photoIdByPath
        ..clear()
        ..addEntries(
          result.photoPaths
              .where(previousPhotoIdByPath.containsKey)
              .map((path) => MapEntry(path, previousPhotoIdByPath[path]!)),
        );
      _photoQualityByPath
        ..clear()
        ..addAll(result.photoQualityChecksByPath);
      _photoReadStateByPath
        ..clear()
        ..addEntries(
          result.photoPaths.map(
            (path) => MapEntry(
              path,
              previousPhotoReadStateByPath[path] ??
                  ReceiptAttachmentReadState.notRead,
            ),
          ),
        );
      _dataSaverLevel = result.dataSaverLevel;
    });
    _publishAttachmentChange();
    final readResult = await _readReviewedPhotosForReceiptForm(result);
    _markReviewedPhotosReadState(result, readResult);
    unawaited(_deleteTemporaryOcrPhotos(result.ocrSourcePhotoPaths));
  }

  Future<_ReceiptAttachmentReadResult> _readReviewedPhotosForReceiptForm(
    ReceiptPhotoReviewResult result,
  ) async {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (settings?.appAssistedEnabledFor(widget.area) == false ||
        widget.onImportedText == null) {
      _updateAttachmentState(() {
        _receiptReadStatus = _ReceiptReadStatusKind.warning;
        _receiptReadStatusMessage =
            'Receipt photo saved as proof. App-assisted filling is turned off for this area.';
      });
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    if (result.ocrSourcePhotoPaths.isEmpty) {
      _updateAttachmentState(() {
        _receiptReadStatus = _ReceiptReadStatusKind.warning;
        _receiptReadStatusMessage =
            'Receipt photo saved as proof. No clear OCR source was available for app-assisted filling.';
      });
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    final now = DateTime.now();
    final ocrAttachments = [
      for (var index = 0; index < result.ocrSourcePhotoPaths.length; index++)
        ReceiptAttachmentRecord(
          id: 'RCOCR-${now.microsecondsSinceEpoch}-$index',
          path: result.ocrSourcePhotoPaths[index],
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: result.dataSaverLevel,
          createdAt: now,
          byteSize: _fileSize(result.ocrSourcePhotoPaths[index]),
        ).withPhotoQuality(_qualityForOcrSourceIndex(result, index)),
    ];
    return _readAttachmentsForReceiptForm(
      ocrAttachments,
      successMessage: _reviewedPhotoReadSuccessMessage(result.stitchResult),
      showDisabledMessage: false,
      showNoTextMessage: true,
    );
  }

  void _markReviewedPhotosReadState(
    ReceiptPhotoReviewResult result,
    _ReceiptAttachmentReadResult readResult,
  ) {
    if (readResult.outcome == _ReceiptAttachmentReadOutcome.skipped) return;
    final readState = readResult.didRead
        ? ReceiptAttachmentReadState.readIntoForm
        : ReceiptAttachmentReadState.unreadable;
    _updateAttachmentState(() {
      for (final path in result.photoPaths) {
        _photoReadStateByPath[path] = readState;
      }
    });
    _publishAttachmentChange();
  }

  ReceiptPhotoQualityCheck? _qualityForOcrSourceIndex(
    ReceiptPhotoReviewResult result,
    int index,
  ) {
    if (result.ocrSourcePhotoPaths.length == 1 &&
        result.photoPaths.length > 1) {
      return _weakestPhotoQuality(
        result.photoPaths,
        result.photoQualityChecksByPath,
      );
    }
    if (index < 0 || index >= result.photoPaths.length) return null;
    return result.photoQualityChecksByPath[result.photoPaths[index]];
  }

  ReceiptPhotoQualityCheck? _weakestPhotoQuality(
    List<String> paths,
    Map<String, ReceiptPhotoQualityCheck> qualityByPath,
  ) {
    ReceiptPhotoQualityCheck? weakest;
    for (final path in paths) {
      final quality = qualityByPath[path];
      if (quality == null) continue;
      if (weakest == null || quality.reviewScore < weakest.reviewScore) {
        weakest = quality;
      }
    }
    return weakest;
  }

  String _reviewedPhotoReadSuccessMessage(ReceiptStitchResult stitch) {
    if (stitch.didStitch) {
      return 'The matched receipt photo was read. Review the filled fields below.';
    }
    if (stitch.usedFallback && stitch.hasMultipleSections) {
      return 'Receipt photos were read from top to bottom. Review the filled fields below.';
    }
    if (stitch.hasMultipleSections) {
      return 'Receipt photos were read together. Review the filled fields below.';
    }
    return 'Receipt photo was read. Review the filled fields below.';
  }

  Map<String, ReceiptPhotoQualityCheck> _qualityChecksByPathForCameraResult(
    ReceiptCameraResult result,
  ) {
    final checks = <String, ReceiptPhotoQualityCheck>{};
    for (var index = 0; index < result.photoPaths.length; index++) {
      final quality = result.qualityForIndex(index);
      if (quality != null) checks[result.photoPaths[index]] = quality;
    }
    return checks;
  }

  Future<Map<String, ReceiptPhotoQualityCheck>> _qualityChecksForPhotoPaths(
    List<String> paths,
  ) async {
    final checks = <String, ReceiptPhotoQualityCheck>{};
    for (final path in paths) {
      try {
        checks[path] = await ReceiptImageProcessor.qualityCheckFile(path);
      } catch (_) {
        // The receipt can still be reviewed and read without an early badge.
      }
    }
    return checks;
  }

  Future<void> _deleteTemporaryOcrPhotos(List<String> paths) async {
    final keptReceiptPhotos = _photoPaths.toSet();
    for (final sourcePath in paths) {
      if (keptReceiptPhotos.contains(sourcePath)) continue;
      try {
        final file = File(sourcePath);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best effort cleanup for full-size camera photos after OCR.
      }
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
    await _saveImportedTextAttachment(attachment);
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

  Future<void> _saveImportedTextAttachment(
    ReceiptAttachmentRecord attachment,
  ) async {
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
      final onImportedText = widget.onImportedText;
      if (onImportedText != null) {
        await Future<void>.sync(() => onImportedText(attachment.importedText));
      }
    }
    _publishAttachmentChange();
  }

  Future<void> _editDocument(ReceiptAttachmentRecord attachment) async {
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
