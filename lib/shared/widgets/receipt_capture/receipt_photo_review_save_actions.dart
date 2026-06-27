part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewSaveActions on _ReceiptPhotoReviewScreenState {
  void _handleMenuAction(_ReceiptReviewMenuAction action) {
    switch (action) {
      case _ReceiptReviewMenuAction.addAdditionalPhotos:
        _addAnotherPhoto();
      case _ReceiptReviewMenuAction.moveEarlier:
        _moveCurrentPhoto(-1);
      case _ReceiptReviewMenuAction.moveLater:
        _moveCurrentPhoto(1);
      case _ReceiptReviewMenuAction.retake:
        _retakeCurrentPhoto();
      case _ReceiptReviewMenuAction.remove:
        unawaited(_removeCurrentPhoto());
    }
  }

  Future<void> _addAnotherPhoto() async {
    final picked = await _pickReceiptPhotos(
      alignmentGuidePhotoPath: _photoPaths.isEmpty
          ? null
          : _photoPaths[_selectedIndex],
    );
    if (picked.paths.isEmpty || !mounted) return;
    _updateReviewState(() {
      final insertIndex = _photoPaths.isEmpty
          ? 0
          : (_selectedIndex + 1).clamp(0, _photoPaths.length);
      _photoPaths.insertAll(insertIndex, picked.paths);
      _qualityChecksByPath.addAll(picked.qualityChecksByPath);
      _selectedIndex = insertIndex;
      if (_photoPaths.length > 1) {
        _reviewMode = _ReceiptReviewMode.order;
        _controlsVisible = true;
      }
    });
    _invalidateStitchPreview();
  }

  Future<void> _retakeCurrentPhoto() async {
    final picked = await _pickReceiptPhotos(
      alignmentGuidePhotoPath: _selectedIndex > 0
          ? _photoPaths[_selectedIndex - 1]
          : null,
    );
    if (picked.paths.isEmpty || !mounted) return;
    String? replacedGeneratedPath;
    _updateReviewState(() {
      final replacedPath = _photoPaths[_selectedIndex];
      if (_generatedEditPaths.contains(replacedPath)) {
        replacedGeneratedPath = replacedPath;
      }
      final firstPath = picked.paths.first;
      _replaceCurrentPhotoPath(
        firstPath,
        picked.qualityChecksByPath[firstPath],
      );
      if (picked.paths.length > 1) {
        _photoPaths.insertAll(_selectedIndex + 1, picked.paths.skip(1));
      }
      _qualityChecksByPath.addAll(picked.qualityChecksByPath);
      if (_photoPaths.length > 1) {
        _reviewMode = _ReceiptReviewMode.order;
        _controlsVisible = true;
      }
    });
    _invalidateStitchPreview();
    if (replacedGeneratedPath != null) {
      await _deleteGeneratedEditPhotos(_photoPaths.toSet());
    }
  }

  Future<_PickedReceiptPhotos> _pickReceiptPhotos({
    String? alignmentGuidePhotoPath,
  }) async {
    if (_openingCamera) return const _PickedReceiptPhotos.empty();
    _updateReviewState(() => _openingCamera = true);
    try {
      if (alignmentGuidePhotoPath != null) {
        final shouldContinue = await _showLongReceiptAlignmentGuide(
          alignmentGuidePhotoPath,
        );
        if (!mounted) return const _PickedReceiptPhotos.empty();
        if (!shouldContinue) return const _PickedReceiptPhotos.empty();
      }
      final settings = ReceiptCaptureSettingsScope.maybeOf(context);
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
          return _PickedReceiptPhotos.fromCameraResult(
            cameraResult,
            cameraResult.photoPaths,
          );
        }
        if (scanResult.status == ReceiptNativeScanStatus.canceled) {
          return const _PickedReceiptPhotos.empty();
        }
        _showScannerFallbackNotice(scanResult);
      }
      final picked = await ReceiptImagePicker.takeReceiptPhotoSet();
      if (picked.isEmpty) {
        return const _PickedReceiptPhotos.empty();
      }
      return _PickedReceiptPhotos.fromNativePhotoPaths(picked.paths);
    } on MissingPluginException {
      if (mounted) {
        _showScannerFallbackNotice(
          const ReceiptNativeScanResult.unavailable(
            'Document scanning is not available in this build.',
          ),
        );
      }
      try {
        final picked = await ReceiptImagePicker.takeReceiptPhotoSet();
        if (picked.isEmpty) {
          return const _PickedReceiptPhotos.empty();
        }
        return _PickedReceiptPhotos.fromNativePhotoPaths(picked.paths);
      } on MissingPluginException {
        if (mounted) {
          _showCameraError(
            'The phone camera is not available in this build. Use Add Existing Photo, or reinstall the app and try again.',
          );
        }
        return const _PickedReceiptPhotos.empty();
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _showCameraError(_nativeCameraOpenErrorMessage(error));
      }
      return const _PickedReceiptPhotos.empty();
    } catch (_) {
      if (mounted) {
        _showCameraError(
          'The camera did not open. Try Add Another Photo again, or choose an existing receipt image.',
        );
      }
      return const _PickedReceiptPhotos.empty();
    } finally {
      if (mounted) _updateReviewState(() => _openingCamera = false);
    }
  }

  Future<bool> _showLongReceiptAlignmentGuide(String photoPath) async {
    if (!mounted) return false;
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Line Up The Next Receipt Photo',
                  style: TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use the bottom of the last photo as your guide. Start the next photo with a few repeated lines so Maintainiac can match the receipt sections.',
                  style: TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                _ReceiptAlignmentGuidePreview(photoPath: photoPath),
                const SizedBox(height: 10),
                const _ReceiptAlignmentGuideNote(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Open Camera'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  void _showCameraError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showScannerFallbackNotice(ReceiptNativeScanResult result) {
    if (!mounted || result.status == ReceiptNativeScanStatus.scanned) return;
    final detail = result.message.trim();
    final message = detail.isEmpty
        ? 'Document scanner was not available. Opening the phone camera instead so you can still capture the receipt.'
        : '$detail Opening the phone camera instead so you can still capture the receipt.';
    _showCameraError(message);
  }

  String _nativeCameraOpenErrorMessage(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = error.message?.trim();
    final combined = '$code ${message ?? ''}'.toLowerCase();
    if (combined.contains('permission') ||
        combined.contains('denied') ||
        combined.contains('restricted')) {
      return 'Camera permission is blocked. Open your phone settings, allow camera access for Maintainiac, then try Add Another Photo again.';
    }
    if (combined.contains('cancel')) {
      return 'Camera was canceled. No receipt photo was added.';
    }
    if (message != null && message.isNotEmpty) {
      return '$message Try Add Another Photo again, or choose an existing receipt image.';
    }
    return 'The phone camera could not open. Try Add Another Photo again, or choose an existing receipt image.';
  }

  Future<void> _showStorageDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2528),
          title: const Text(
            'Storage Space Needed',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Color(0xFFC7D0D4),
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeCurrentPhoto() async {
    if (_photoPaths.length <= 1) return;
    final confirmed = await _confirmRemoveCurrentPhoto(_selectedIndex + 1);
    if (!mounted || !confirmed) return;
    String? removedGeneratedPath;
    Set<String> staleDataSaverPreviewPaths = const {};
    _updateReviewState(() {
      final removedPath = _photoPaths[_selectedIndex];
      if (_generatedEditPaths.contains(removedPath)) {
        removedGeneratedPath = removedPath;
      }
      staleDataSaverPreviewPaths = _removePhotoReviewCachesForPath(removedPath);
      _photoPaths.removeAt(_selectedIndex);
      if (_selectedIndex >= _photoPaths.length) {
        _selectedIndex = _photoPaths.length - 1;
      }
    });
    unawaited(_deleteStaleDataSaverPreviewFiles(staleDataSaverPreviewPaths));
    _invalidateStitchPreview();
    if (removedGeneratedPath != null) {
      unawaited(_deleteGeneratedEditPhotos(_photoPaths.toSet()));
    }
  }

  Future<bool> _confirmRemoveCurrentPhoto(int currentPhoto) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Remove receipt photo?',
                  style: TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This removes photo $currentPhoto from this receipt review. If this is a long receipt, make sure the remaining photos still cover every line.',
                  style: const TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD166),
                          foregroundColor: const Color(0xFF101416),
                        ),
                        child: const Text('Remove Photo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  void _moveCurrentPhoto(int direction) {
    if (_photoPaths.length <= 1) return;
    final targetIndex = _selectedIndex + direction;
    if (targetIndex < 0 || targetIndex >= _photoPaths.length) return;
    _updateReviewState(() {
      final currentPath = _photoPaths[_selectedIndex];
      _photoPaths[_selectedIndex] = _photoPaths[targetIndex];
      _photoPaths[targetIndex] = currentPath;
      _selectedIndex = targetIndex;
    });
    _invalidateStitchPreview();
  }

  Future<void> _continue() async {
    if (_savingPhotos || _closingReview) return;
    if (_needsStitchReviewBeforeSave) {
      if (_reviewMode != _ReceiptReviewMode.stitch) {
        _updateReviewState(() {
          _reviewMode = _ReceiptReviewMode.stitch;
          _controlsVisible = true;
        });
        unawaited(_ensureStitchPreview(force: true));
        return;
      }
      if (_stitchPreviewResult == null) {
        await _ensureStitchPreview(force: true);
        return;
      }
      if (_stitchPreviewInFlight) {
        _showCameraError(
          'Wait for the photo match check, then choose how the receipt review should be filled.',
        );
        return;
      }
    }
    _updateReviewState(() => _savingPhotos = true);
    try {
      final storage = await ReceiptStorageGuard.check(
        ReceiptStoragePurpose.savePhotos,
      );
      if (!mounted) return;
      if (!storage.hasEnoughSpace) {
        _updateReviewState(() => _savingPhotos = false);
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
      final pathsToSave = widget.bestShotCandidateMode
          ? [_photoPaths[_selectedIndex]]
          : _photoPaths;
      final savedPaths = <String>[];
      final ocrSourcePaths = <String>[];
      final savedQualityChecks = <String, ReceiptPhotoQualityCheck>{};
      for (final path in pathsToSave) {
        final prepared = await ReceiptImageProcessor.prepareForOcrAndBackup(
          path: path,
          level: _dataSaverLevel,
        ).timeout(const Duration(seconds: 20));
        if (_closingReview) return;
        savedPaths.add(prepared.backupPath);
        ocrSourcePaths.add(prepared.ocrSourcePath);
        savedQualityChecks[prepared.backupPath] = prepared.quality;
      }
      final stitch = await _finalStitchResultForOcr(
        inputPaths: pathsToSave,
        preparedOcrPaths: ocrSourcePaths,
      ).timeout(const Duration(seconds: 24));
      if (!mounted || _closingReview) return;
      await _deleteUnusedBestShotCandidatePhotos(pathsToSave.toSet());
      await _deleteGeneratedStitchPreview();
      await _deleteGeneratedEditPhotos({
        ...pathsToSave,
        ...savedPaths,
        ...ocrSourcePaths,
        ...stitch.ocrSourcePaths,
        if (stitch.stitchedPath != null) stitch.stitchedPath!,
      });
      if (!mounted || _closingReview) return;
      Navigator.of(context).pop(
        ReceiptPhotoReviewResult(
          photoPaths: savedPaths,
          ocrSourcePhotoPaths: stitch.ocrSourcePaths,
          dataSaverLevel: _dataSaverLevel,
          stitchResult: stitch,
          photoQualityChecksByPath: savedQualityChecks,
        ),
      );
    } on TimeoutException {
      if (!mounted || _closingReview) return;
      _updateReviewState(() => _savingPhotos = false);
      _showCameraError(
        'Receipt prep took too long. Try again, or retake the photo.',
      );
    } catch (_) {
      if (!mounted) return;
      _updateReviewState(() => _savingPhotos = false);
      _showCameraError('Could not save these receipt photos.');
    }
  }

  Future<void> _leaveReceiptReviewWithoutSaving() async {
    if (_closingReview) return;
    _closingReview = true;
    if (mounted) {
      _updateReviewState(() => _savingPhotos = false);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    unawaited(_cleanupAbandonedReceiptReview());
  }

  Future<void> _cleanupAbandonedReceiptReview() async {
    await _deleteUnusedBestShotCandidatePhotos(const {});
    await _deleteGeneratedEditPhotos(const {});
  }

  bool get _needsStitchReviewBeforeSave {
    return !widget.bestShotCandidateMode && _photoPaths.length > 1;
  }

  Future<void> _deleteUnusedBestShotCandidatePhotos(
    Set<String> keptPaths,
  ) async {
    if (!widget.bestShotCandidateMode) return;
    for (final path in _photoPaths) {
      if (keptPaths.contains(path)) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best effort cleanup for app-created Guided Capture candidates.
      }
    }
  }

  Future<void> _deleteGeneratedEditPhotos(Set<String> keptPaths) async {
    final generatedPaths = _generatedEditPaths.toList(growable: false);
    for (final path in generatedPaths) {
      if (keptPaths.contains(path)) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best effort cleanup for app-created edited receipt photos.
      } finally {
        _generatedEditPaths.remove(path);
      }
    }
  }

  Future<ReceiptStitchResult> _finalStitchResultForOcr({
    required List<String> inputPaths,
    required List<String> preparedOcrPaths,
  }) async {
    final preview = _stitchPreviewResult;
    final previewPath = preview?.stitchedPath;
    final previewCanBeUsed =
        !_stitchPreviewInFlight &&
        preview?.didStitch == true &&
        previewPath != null &&
        _stitchPreviewKey == _currentStitchPreviewKey() &&
        inputPaths.length == _photoPaths.length;
    if (previewCanBeUsed && await File(previewPath).exists()) {
      final finalPath = await ReceiptImageProcessor.copyReceiptOcrArtifact(
        path: previewPath,
      );
      return preview!.copyForFinalOcr(
        inputPaths: preparedOcrPaths,
        ocrSourcePaths: [finalPath],
        stitchedPath: finalPath,
      );
    }

    final manualOverlapFractions = _manualOverlapFractions
        .map((value) => value ?? 0)
        .toList(growable: false);
    return ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: preparedOcrPaths,
      manualOverlapFractions: manualOverlapFractions.any((value) => value > 0)
          ? manualOverlapFractions
          : null,
      maxOutputPixels: _stitchDeviceLimits.maxOutputPixels,
      maxOutputHeight: _stitchDeviceLimits.maxOutputHeight,
    );
  }
}

class _PickedReceiptPhotos {
  const _PickedReceiptPhotos({
    required this.paths,
    required this.qualityChecksByPath,
  });

  const _PickedReceiptPhotos.empty()
    : paths = const [],
      qualityChecksByPath = const {};

  factory _PickedReceiptPhotos.fromCameraResult(
    ReceiptCameraResult result,
    List<String> paths,
  ) {
    final checks = <String, ReceiptPhotoQualityCheck>{};
    for (final path in paths) {
      final index = result.photoPaths.indexOf(path);
      final quality = result.qualityForIndex(index);
      if (quality != null) checks[path] = quality;
    }
    return _PickedReceiptPhotos(paths: paths, qualityChecksByPath: checks);
  }

  static Future<_PickedReceiptPhotos> fromNativePhotoPaths(
    List<String> paths,
  ) async {
    final checks = <String, ReceiptPhotoQualityCheck>{};
    for (final path in paths) {
      try {
        checks[path] = await ReceiptImageProcessor.qualityCheckFile(path);
      } catch (_) {
        // Native camera capture still continues; the review screen can proceed
        // without a quality badge if this lightweight check fails.
      }
    }
    return _PickedReceiptPhotos(paths: paths, qualityChecksByPath: checks);
  }

  final List<String> paths;
  final Map<String, ReceiptPhotoQualityCheck> qualityChecksByPath;
}

class _ReceiptAlignmentGuidePreview extends StatelessWidget {
  const _ReceiptAlignmentGuidePreview({required this.photoPath});

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0C1113),
          border: Border.all(color: const Color(0xFF526168)),
        ),
        child: SizedBox(
          height: 126,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(photoPath),
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Previous receipt section could not be previewed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFC7D0D4),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  );
                },
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66050607),
                        Color(0x11050607),
                        Color(0xAA050607),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xDD11181B),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFFFFD166)),
                  ),
                  child: const Text(
                    'Repeat a few lines from this bottom area in the next photo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptAlignmentGuideNote extends StatelessWidget {
  const _ReceiptAlignmentGuideNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF334047)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF8FD3FF), size: 17),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'The phone camera opens next. Maintainiac cannot draw over that camera screen, so use this preview as your alignment guide before taking the next photo.',
              style: TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
