import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../backup/cloud_backup_status.dart';
import '../../navigation/app_page_routes.dart';
import '../../storage/app_storage_guard.dart';
import 'receipt_capture_models.dart';
import 'receipt_camera_screen.dart';
import 'receipt_edge_cropper.dart';
import 'receipt_image_processor.dart';
import 'receipt_picker_status.dart';
import 'receipt_storage_guard.dart';

part 'receipt_photo_review_controls.dart';
part 'receipt_photo_review_top_bar.dart';
part 'receipt_photo_review_image_edit_actions.dart';
part 'receipt_photo_review_save_actions.dart';
part 'receipt_photo_review_data_saver_panel.dart';
part 'receipt_photo_review_quality_card.dart';
part 'receipt_photo_review_long_receipt_hint.dart';
part 'receipt_photo_review_section_labels.dart';
part 'receipt_photo_review_strip.dart';

enum _ReceiptReviewMode { preview, crop, dataSaver }

enum _ReceiptReviewMenuAction {
  addAdditionalPhotos,
  moveEarlier,
  moveLater,
  retake,
  remove,
}

class ReceiptPhotoReviewScreen extends StatefulWidget {
  const ReceiptPhotoReviewScreen({
    super.key,
    required this.initialPhotoPaths,
    required this.initialDataSaverLevel,
    this.bestShotCandidateMode = false,
    this.initialQualityChecks = const [],
  });

  final List<String> initialPhotoPaths;
  final ReceiptDataSaverLevel initialDataSaverLevel;
  final bool bestShotCandidateMode;
  final List<ReceiptPhotoQualityCheck> initialQualityChecks;

  @override
  State<ReceiptPhotoReviewScreen> createState() =>
      _ReceiptPhotoReviewScreenState();
}

class _ReceiptPhotoReviewScreenState extends State<ReceiptPhotoReviewScreen> {
  late final List<String> _photoPaths = [...widget.initialPhotoPaths];
  late ReceiptDataSaverLevel _dataSaverLevel = widget.initialDataSaverLevel;
  var _selectedIndex = 0;
  var _openingCamera = false;
  var _controlsVisible = true;
  var _reviewMode = _ReceiptReviewMode.preview;
  var _cropProcessing = false;
  var _savingPhotos = false;
  final _storagePreviews = <String, ReceiptImageStoragePreview>{};
  final _previewKeysInFlight = <String>{};
  final _dataSaverPreviewPaths = <String, String>{};
  final _dataSaverPreviewKeysInFlight = <String>{};
  final _generatedEditPaths = <String>{};
  late final _qualityChecksByPath = _initialQualityChecksByPath();
  Uint8List? _cropImageBytes;
  Size? _cropImageSize;
  Rect? _cropRect;
  Rect? _cropDisplayRect;
  String? _cropSourcePath;

  @override
  void dispose() {
    unawaited(_deleteGeneratedDataSaverPreviews());
    unawaited(_deleteGeneratedEditPhotos(const {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = _photoPaths[_selectedIndex];
    _ensureStoragePreview(photoPath);
    if (_reviewMode == _ReceiptReviewMode.dataSaver) {
      _ensureDataSaverImagePreview(photoPath);
    }
    final dataSaverPreviewPath =
        _dataSaverPreviewPaths[_dataSaverPreviewKey(photoPath)];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050607),
        body: Stack(
          children: [
            Positioned.fill(
              child: _reviewMode == _ReceiptReviewMode.crop
                  ? _buildCropSurface(photoPath)
                  : _buildPhotoSurface(
                      _reviewMode == _ReceiptReviewMode.dataSaver
                          ? dataSaverPreviewPath ?? photoPath
                          : photoPath,
                      waitingForDataSaverPreview:
                          _reviewMode == _ReceiptReviewMode.dataSaver &&
                          dataSaverPreviewPath == null,
                    ),
            ),
            SafeArea(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: _controlsVisible ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: _ReceiptReviewTopBar(
                    current: _selectedIndex + 1,
                    total: _photoPaths.length,
                    reviewMode: _reviewMode,
                    onClose: _confirmExit,
                    onHideControls: () =>
                        setState(() => _controlsVisible = false),
                    onMenuSelected: _handleMenuAction,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  offset: _controlsVisible
                      ? Offset.zero
                      : const Offset(0, 1.08),
                  child: _ReceiptReviewBottomControls(
                    photoPaths: _photoPaths,
                    selectedIndex: _selectedIndex,
                    dataSaverLevel: _dataSaverLevel,
                    storagePreview: _storagePreviews[_previewKey(photoPath)],
                    selectedQualityCheck: _qualityChecksByPath[photoPath],
                    reviewMode: _reviewMode,
                    bestShotCandidateMode: widget.bestShotCandidateMode,
                    canRemove: _photoPaths.length > 1,
                    openingCamera: _openingCamera,
                    cropProcessing: _cropProcessing,
                    savingPhotos: _savingPhotos,
                    onPhotoSelected: (index) =>
                        setState(() => _selectedIndex = index),
                    onDataSaverSelected: (level) =>
                        setState(() => _dataSaverLevel = level),
                    onModeChanged: _setReviewMode,
                    onStraightenLeft: () => _rotateCurrentPhoto(-1.5),
                    onStraightenRight: () => _rotateCurrentPhoto(1.5),
                    onRotateLeft: () => _rotateCurrentPhoto(-90),
                    onRotateRight: () => _rotateCurrentPhoto(90),
                    onResetCrop: _resetCrop,
                    onApplyCrop: _applyCrop,
                    onCancelCrop: () => setState(
                      () => _reviewMode = _ReceiptReviewMode.preview,
                    ),
                    onAddPhoto: _addAnotherPhoto,
                    onRetake: _retakeCurrentPhoto,
                    onRemove: _removeCurrentPhoto,
                    onContinue: _continue,
                  ),
                ),
              ),
            ),
            if (!_controlsVisible)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _OverlayIconButton(
                      icon: Icons.tune_rounded,
                      label: 'Show controls',
                      onPressed: () => setState(() => _controlsVisible = true),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSurface(
    String photoPath, {
    bool waitingForDataSaverPreview = false,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _controlsVisible = !_controlsVisible),
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 6,
            child: SizedBox.expand(
              child: Image.file(
                File(photoPath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Receipt image could not be previewed.',
                      style: TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (waitingForDataSaverPreview)
          const Positioned(
            left: 14,
            right: 14,
            top: 86,
            child: _DataSaverPreviewLoadingBanner(),
          ),
      ],
    );
  }

  Widget _buildCropSurface(String photoPath) {
    _ensureCropBytesLoaded(photoPath);
    final imageBytes = _cropImageBytes;
    final imageSize = _cropImageSize;
    if (imageBytes == null ||
        imageSize == null ||
        _cropSourcePath != photoPath) {
      return const Center(child: CircularProgressIndicator());
    }
    return ReceiptEdgeCropper(
      imageBytes: imageBytes,
      imageSize: imageSize,
      cropRect: _cropRect,
      onCropRectChanged: (rect) => setState(() => _cropRect = rect),
      onDisplayRectChanged: (rect) => _cropDisplayRect = rect,
    );
  }

  void _updateReviewState(VoidCallback update) {
    setState(update);
  }

  Future<void> _ensureStoragePreview(String photoPath) async {
    final key = _previewKey(photoPath);
    if (_storagePreviews.containsKey(key) ||
        _previewKeysInFlight.contains(key)) {
      return;
    }
    _previewKeysInFlight.add(key);
    try {
      final preview = await ReceiptImageProcessor.previewFile(
        path: photoPath,
        level: _dataSaverLevel,
      );
      if (!mounted) return;
      setState(() => _storagePreviews[key] = preview);
    } catch (_) {
      if (!mounted) return;
    } finally {
      _previewKeysInFlight.remove(key);
    }
  }

  String _previewKey(String photoPath) => '$photoPath|${_dataSaverLevel.name}';

  Map<String, ReceiptPhotoQualityCheck> _initialQualityChecksByPath() {
    final checks = <String, ReceiptPhotoQualityCheck>{};
    final count =
        widget.initialPhotoPaths.length < widget.initialQualityChecks.length
        ? widget.initialPhotoPaths.length
        : widget.initialQualityChecks.length;
    for (var index = 0; index < count; index++) {
      checks[widget.initialPhotoPaths[index]] =
          widget.initialQualityChecks[index];
    }
    return checks;
  }

  Future<void> _ensureDataSaverImagePreview(String photoPath) async {
    final key = _dataSaverPreviewKey(photoPath);
    if (_dataSaverPreviewPaths.containsKey(key) ||
        _dataSaverPreviewKeysInFlight.contains(key)) {
      return;
    }
    _dataSaverPreviewKeysInFlight.add(key);
    try {
      final previewPath = await ReceiptImageProcessor.optimizeFile(
        path: photoPath,
        level: _dataSaverLevel,
      );
      if (!mounted) return;
      setState(() => _dataSaverPreviewPaths[key] = previewPath);
    } catch (_) {
      if (mounted) _showCameraError('Could not preview this data saver level.');
    } finally {
      _dataSaverPreviewKeysInFlight.remove(key);
    }
  }

  String _dataSaverPreviewKey(String path) => '$path::${_dataSaverLevel.name}';

  Future<void> _deleteGeneratedDataSaverPreviews() async {
    final originalPaths = _photoPaths.toSet();
    for (final path in _dataSaverPreviewPaths.values.toSet()) {
      if (originalPaths.contains(path)) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best effort cleanup for app-created data saver previews.
      }
    }
  }
}

class _DataSaverPreviewLoadingBanner extends StatelessWidget {
  const _DataSaverPreviewLoadingBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD050607),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFFD166),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Preparing data saver preview...',
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
