part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewOrderActions on _ReceiptPhotoReviewScreenState {
  Future<void> removeCurrentReceiptPhoto() async {
    if (_photoPaths.length <= 1) return;
    final targetIndex = _selectedIndex;
    final targetPhotoPath = _photoPaths[_selectedIndex];
    final targetPhotoNumber = _selectedIndex + 1;
    final confirmed = await _confirmRemoveCurrentPhoto(targetPhotoNumber);
    if (!_reviewWorkActive || !confirmed) return;
    final removalPlan = ReceiptPhotoRemovalOrderPlan.build(
      currentPhotoPaths: _photoPaths,
      targetIndex: targetIndex,
      targetPhotoPath: targetPhotoPath,
    );
    if (removalPlan == null) return;
    String? removedGeneratedPath;
    Set<String> staleDataSaverPreviewPaths = const {};
    _updateReviewState(() {
      if (_generatedEditPaths.contains(removalPlan.removedPhotoPath)) {
        removedGeneratedPath = removalPlan.removedPhotoPath;
      }
      staleDataSaverPreviewPaths = _removePhotoReviewCachesForPath(
        removalPlan.removedPhotoPath,
      );
      _photoPaths
        ..clear()
        ..addAll(removalPlan.photoPaths);
      _selectedIndex = removalPlan.selectedIndex;
    });
    unawaited(_deleteStaleDataSaverPreviewFiles(staleDataSaverPreviewPaths));
    _recoverReviewAfterPhotoSetChanged();
    if (removedGeneratedPath != null) {
      unawaited(_deleteGeneratedEditPhotos(_photoPaths.toSet()));
    }
  }

  Future<bool> _confirmRemoveCurrentPhoto(int currentPhoto) async {
    if (!_reviewWorkActive) return false;
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
                  'This removes photo $currentPhoto from this photo review. If this is a long receipt, make sure the remaining photos still cover every line.',
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
    if (!_reviewWorkActive) return false;
    return result ?? false;
  }

  void moveCurrentReceiptPhoto(int direction) {
    if (_photoPaths.length <= 1) return;
    final targetIndex = _selectedIndex + direction;
    if (targetIndex < 0 || targetIndex >= _photoPaths.length) return;
    _updateReviewState(() {
      final currentPath = _photoPaths[_selectedIndex];
      _photoPaths[_selectedIndex] = _photoPaths[targetIndex];
      _photoPaths[targetIndex] = currentPath;
      _selectedIndex = targetIndex;
    });
    _recoverReviewAfterPhotoSetChanged();
  }

  void _recoverReviewAfterPhotoSetChanged() {
    _invalidateStitchPreview();
    _resetPhotoPreviewZoom();
    if (_photoPaths.isEmpty) return;
    _updateReviewState(() {
      if (_selectedIndex < 0) _selectedIndex = 0;
      if (_selectedIndex >= _photoPaths.length) {
        _selectedIndex = _photoPaths.length - 1;
      }
      final maxPairIndex = _photoPaths.length <= 1 ? 0 : _photoPaths.length - 2;
      if (_selectedStitchPairIndex > maxPairIndex) {
        _selectedStitchPairIndex = maxPairIndex;
      }
      _reviewMode = _photoPaths.length > 1
          ? _ReceiptReviewMode.order
          : _ReceiptReviewMode.preview;
      _controlsVisible = true;
      _savingPhotos = false;
      _cropProcessing = false;
      _cropSourcePath = null;
      _cropImageBytes = null;
      _cropImageSize = null;
      _cropRect = null;
      _cropDisplayRect = null;
    });
    _resetToolControlsScrollPosition();
  }
}
