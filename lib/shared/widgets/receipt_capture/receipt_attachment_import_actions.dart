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
      await reviewPickedPhotoPaths(
        picked.paths,
        initialQualityChecksByPath: await qualityChecksForPhotoPaths(
          picked.paths,
        ),
        initialCaptureDiagnosticsByPath: receiptBrainDiagnosticsByPath(
          picked.paths,
          captureRoute: 'existing_receipt_photo_import',
          extra: const {
            'captureFlow': 'existing_receipt_photo_import',
            'existingPhotoImportUsed': true,
            'existingPhotoImportRole': 'user_selected_receipt_photo',
          },
        ),
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
}
