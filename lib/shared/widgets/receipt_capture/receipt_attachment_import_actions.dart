part of 'receipt_attachment_panel.dart';

enum _ReceiptImportAction {
  camera,
  image,
  pdf,
  savedText,
  pasteText,
  settings,
  shareHelp,
}

enum _ReceiptTextImportAction { pasteText, textFile }

enum _ReceiptFirstUseCameraAction { useReceiptAssist, manualEntry }

enum _MaintainiacNativeCameraPhotoOutcome { added, unavailable, canceled }

extension _ReceiptAttachmentImportActions
    on _SharedReceiptAttachmentPanelState {
  Future<void> uploadReceiptImage() async {
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
    updateAttachmentState(() => _openingPicker = true);
    try {
      final picked = await pickImages();
      if (picked.isEmpty || !mounted) {
        await returnToReceiptImportOptions();
        return;
      }
      final staged = await _stageImportedReceiptPhotos(picked);
      if (staged == null || !mounted) return;
      final importedDiagnostics = receiptBrainDiagnosticsByPath(
        staged.photoPaths,
        captureRoute: 'existing_receipt_photo_import',
        extra: const {
          'captureFlow': 'existing_receipt_photo_import',
          'existingPhotoImportUsed': true,
          'existingPhotoImportRole': 'user_selected_receipt_photo',
          'importedPhotoStagedBeforeReview': true,
        },
      );
      await reviewPickedPhotoPaths(
        staged.photoPaths,
        initialQualityChecksByPath: await qualityChecksForPhotoPaths(
          staged.photoPaths,
        ),
        initialCaptureDiagnosticsByPath: {
          for (final photoPath in staged.photoPaths)
            photoPath: {
              ...?staged.captureDiagnosticsByPhotoPath[photoPath],
              ...?importedDiagnostics[photoPath],
            },
        },
      );
    } on MissingPluginException {
      if (!mounted) return;
      showPickerError(
        'Receipt photo picking is not available in this build. Reinstall the app and try again.',
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      final message = error.message?.trim();
      showPickerError(
        message == null || message.isEmpty ? platformFallback : message,
      );
    } catch (_) {
      if (!mounted) return;
      showPickerError(fallbackMessage);
    } finally {
      if (mounted) updateAttachmentState(() => _openingPicker = false);
    }
  }

  Future<ReceiptNativeCaptureStagingResult?> _stageImportedReceiptPhotos(
    ReceiptPickedPhotoSet picked,
  ) async {
    try {
      return await ReceiptAcquiredPhotoStaging().stage(
        sourcePaths: picked.paths,
        dataSaverLevel: _dataSaverLevel,
        captureFlow: 'existing_receipt_photo_import',
        temporaryIdPrefix: 'existing-receipt-import',
        diagnostics: const {
          'existingPhotoImportUsed': true,
          'existingPhotoImportRole': 'user_selected_receipt_photo',
        },
      );
    } on ReceiptProofStorageException catch (error) {
      if (mounted) showPickerError(error.message);
    } catch (_) {
      if (mounted) {
        showPickerError(
          'That receipt photo could not be kept safely. Choose it again before continuing.',
        );
      }
    }
    return null;
  }
}
