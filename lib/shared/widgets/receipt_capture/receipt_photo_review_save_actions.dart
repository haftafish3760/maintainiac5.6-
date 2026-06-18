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
        _removeCurrentPhoto();
    }
  }

  Future<void> _addAnotherPhoto() async {
    final picked = await _pickReceiptPhotos();
    if (picked.paths.isEmpty || !mounted) return;
    _updateReviewState(() {
      _photoPaths.addAll(picked.paths);
      _qualityChecksByPath.addAll(picked.qualityChecksByPath);
      _selectedIndex = _photoPaths.length - 1;
    });
  }

  Future<void> _retakeCurrentPhoto() async {
    final picked = await _pickReceiptPhotos();
    if (picked.paths.isEmpty || !mounted) return;
    String? replacedGeneratedPath;
    _updateReviewState(() {
      final replacedPath = _photoPaths[_selectedIndex];
      if (_generatedEditPaths.contains(replacedPath)) {
        replacedGeneratedPath = replacedPath;
      }
      _qualityChecksByPath.remove(replacedPath);
      _photoPaths[_selectedIndex] = picked.paths.first;
      if (picked.paths.length > 1) {
        _photoPaths.insertAll(_selectedIndex + 1, picked.paths.skip(1));
      }
      _qualityChecksByPath.addAll(picked.qualityChecksByPath);
    });
    if (replacedGeneratedPath != null) {
      await _deleteGeneratedEditPhotos(_photoPaths.toSet());
    }
  }

  Future<_PickedReceiptPhotos> _pickReceiptPhotos() async {
    if (_openingCamera) return const _PickedReceiptPhotos.empty();
    _updateReviewState(() => _openingCamera = true);
    try {
      final result = await Navigator.of(context).push<ReceiptCameraResult>(
        appNativeRoute(context, const ReceiptCameraScreen()),
      );
      if (result == null) return const _PickedReceiptPhotos.empty();
      final paths = result.isBestShotCandidateSet
          ? result.photoPaths.take(1).toList()
          : result.photoPaths;
      return _PickedReceiptPhotos.fromCameraResult(result, paths);
    } on MissingPluginException {
      if (mounted) {
        _showCameraError(
          'Receipt camera is not available in this build. Reinstall the app and try again.',
        );
      }
      return const _PickedReceiptPhotos.empty();
    } on PlatformException catch (error) {
      if (mounted) {
        final message = error.message?.trim();
        _showCameraError(
          message == null || message.isEmpty
              ? 'Android could not open the camera.'
              : message,
        );
      }
      return const _PickedReceiptPhotos.empty();
    } catch (_) {
      if (mounted) _showCameraError('The camera did not open correctly.');
      return const _PickedReceiptPhotos.empty();
    } finally {
      if (mounted) _updateReviewState(() => _openingCamera = false);
    }
  }

  void _showCameraError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
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

  void _removeCurrentPhoto() {
    if (_photoPaths.length <= 1) return;
    String? removedGeneratedPath;
    _updateReviewState(() {
      final removedPath = _photoPaths[_selectedIndex];
      if (_generatedEditPaths.contains(removedPath)) {
        removedGeneratedPath = removedPath;
      }
      _qualityChecksByPath.remove(removedPath);
      _photoPaths.removeAt(_selectedIndex);
      if (_selectedIndex >= _photoPaths.length) {
        _selectedIndex = _photoPaths.length - 1;
      }
    });
    if (removedGeneratedPath != null) {
      unawaited(_deleteGeneratedEditPhotos(_photoPaths.toSet()));
    }
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
  }

  Future<void> _confirmExit() async {
    final action = await showDialog<_ReceiptExitAction>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2528),
          title: const Text(
            'Leave receipt photos?',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'You have receipt photos in progress. Save them to this receipt, keep editing, or leave without saving.',
            style: TextStyle(
              color: Color(0xFFC7D0D4),
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ReceiptExitAction.leave),
              child: const Text('Leave'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ReceiptExitAction.keepEditing),
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ReceiptExitAction.save),
              child: const Text('Save Progress'),
            ),
          ],
        );
      },
    );
    if (!mounted ||
        action == null ||
        action == _ReceiptExitAction.keepEditing) {
      return;
    }
    if (action == _ReceiptExitAction.save) {
      _continue();
      return;
    }
    await _deleteUnusedBestShotCandidatePhotos(const {});
    await _deleteGeneratedEditPhotos(const {});
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _continue() async {
    if (_savingPhotos) return;
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
      for (final path in pathsToSave) {
        savedPaths.add(
          await ReceiptImageProcessor.optimizeFile(
            path: path,
            level: _dataSaverLevel,
          ),
        );
      }
      if (!mounted) return;
      await _deleteUnusedBestShotCandidatePhotos(pathsToSave.toSet());
      await _deleteGeneratedEditPhotos(pathsToSave.toSet());
      if (!mounted) return;
      Navigator.of(context).pop(
        ReceiptPhotoReviewResult(
          photoPaths: savedPaths,
          ocrSourcePhotoPaths: [...pathsToSave],
          dataSaverLevel: _dataSaverLevel,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _updateReviewState(() => _savingPhotos = false);
      _showCameraError('Could not save these receipt photos.');
    }
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
        // Best effort cleanup for app-created Best Shot candidates.
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

  final List<String> paths;
  final Map<String, ReceiptPhotoQualityCheck> qualityChecksByPath;
}
