part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewImageEditActions
    on _ReceiptPhotoReviewScreenState {
  Future<void> _ensureCropBytesLoaded(String photoPath) async {
    if (_cropSourcePath == photoPath &&
        _cropImageBytes != null &&
        _cropImageSize != null) {
      return;
    }
    _cropSourcePath = photoPath;
    _cropImageBytes = null;
    _cropImageSize = null;
    _cropRect = null;
    _cropDisplayRect = null;
    final bytes = await File(photoPath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (!mounted || _cropSourcePath != photoPath) return;
    if (decoded == null) {
      _showCameraError('This receipt photo could not be loaded for cropping.');
      _updateReviewState(() {
        _reviewMode = _ReceiptReviewMode.preview;
        _cropSourcePath = null;
      });
      return;
    }
    _updateReviewState(() {
      _cropImageBytes = bytes;
      _cropImageSize = Size(
        decoded.width.toDouble(),
        decoded.height.toDouble(),
      );
    });
  }

  void _setReviewMode(_ReceiptReviewMode mode) {
    _updateReviewState(() {
      _reviewMode = mode;
      _controlsVisible = true;
    });
  }

  Future<void> _applyCrop() async {
    if (_cropProcessing ||
        _cropImageBytes == null ||
        _cropImageSize == null ||
        _cropDisplayRect == null ||
        _cropRect == null) {
      return;
    }
    _updateReviewState(() => _cropProcessing = true);
    try {
      final storage = await ReceiptStorageGuard.check(
        ReceiptStoragePurpose.savePhotos,
      );
      if (!mounted) return;
      if (!storage.hasEnoughSpace) {
        _updateReviewState(() => _cropProcessing = false);
        await _showStorageDialog(
          storage.blockingMessage(ReceiptStoragePurpose.savePhotos),
        );
        return;
      }
      if (!storage.canVerify) {
        _showCameraError(
          storage.unknownMessage(ReceiptStoragePurpose.savePhotos),
        );
      } else if (storage.shouldWarnLowStorage) {
        _showCameraError(storage.warningMessage());
      }
      final path = await ReceiptImageProcessor.cropFile(
        bytes: _cropImageBytes!,
        displayImageRect: _cropDisplayRect!,
        cropRect: _cropRect!,
      );
      final quality = await ReceiptImageProcessor.qualityCheckFile(path);
      if (!mounted) return;
      _updateReviewState(() {
        _generatedEditPaths.add(path);
        _replaceCurrentPhotoPath(path, quality);
        _cropProcessing = false;
        _reviewMode = _ReceiptReviewMode.preview;
      });
    } catch (_) {
      if (!mounted) return;
      _updateReviewState(() => _cropProcessing = false);
      _showCameraError('Could not crop this receipt photo.');
    }
  }

  Future<void> _rotateCurrentPhoto(num degrees) async {
    if (_cropProcessing || _savingPhotos) return;
    _updateReviewState(() => _cropProcessing = true);
    try {
      final storage = await ReceiptStorageGuard.check(
        ReceiptStoragePurpose.savePhotos,
      );
      if (!mounted) return;
      if (!storage.hasEnoughSpace) {
        _updateReviewState(() => _cropProcessing = false);
        await _showStorageDialog(
          storage.blockingMessage(ReceiptStoragePurpose.savePhotos),
        );
        return;
      }
      if (!storage.canVerify) {
        _showCameraError(
          storage.unknownMessage(ReceiptStoragePurpose.savePhotos),
        );
      } else if (storage.shouldWarnLowStorage) {
        _showCameraError(storage.warningMessage());
      }
      final currentPath = _photoPaths[_selectedIndex];
      final path = await ReceiptImageProcessor.rotateFile(
        path: currentPath,
        degrees: degrees,
      );
      final quality = await ReceiptImageProcessor.qualityCheckFile(path);
      if (!mounted) return;
      _updateReviewState(() {
        _generatedEditPaths.add(path);
        _replaceCurrentPhotoPath(path, quality);
        _cropProcessing = false;
      });
    } catch (_) {
      if (!mounted) return;
      _updateReviewState(() => _cropProcessing = false);
      _showCameraError('Could not straighten this receipt photo.');
    }
  }

  void _resetCrop() {
    final displayRect = _cropDisplayRect;
    if (displayRect == null) return;
    _updateReviewState(() => _cropRect = displayRect);
  }

  void _replaceCurrentPhotoPath(String path, ReceiptPhotoQualityCheck quality) {
    final previousPath = _photoPaths[_selectedIndex];
    _photoPaths[_selectedIndex] = path;
    _qualityChecksByPath
      ..remove(previousPath)
      ..[path] = quality;
    _storagePreviews.removeWhere((key, _) => key.startsWith('$previousPath|'));
    _dataSaverPreviewPaths.removeWhere(
      (key, _) => key.startsWith('$previousPath::'),
    );
    _cropSourcePath = null;
    _cropImageBytes = null;
    _cropImageSize = null;
    _cropRect = null;
    _cropDisplayRect = null;
  }
}
