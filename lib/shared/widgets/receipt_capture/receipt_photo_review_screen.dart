import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../backup/cloud_backup_status.dart';
import '../../storage/app_storage_guard.dart';
import 'receipt_capture_models.dart';
import 'receipt_assistance_policy.dart';
import 'receipt_capture_settings_store.dart';
import 'receipt_edge_cropper.dart';
import 'receipt_image_processor.dart';
import 'receipt_image_picker.dart';
import 'receipt_picker_status.dart';
import 'receipt_scanner_service.dart';
import 'receipt_storage_guard.dart';

part 'receipt_photo_review_controls.dart';
part 'receipt_photo_review_top_bar.dart';
part 'receipt_photo_review_image_edit_actions.dart';
part 'receipt_photo_review_save_actions.dart';
part 'receipt_photo_review_data_saver_panel.dart';
part 'receipt_photo_review_section_labels.dart';

enum _ReceiptReviewMode { preview, crop, order, stitch, dataSaver }

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
    this.initialSelectedIndex = 0,
    this.initialQualityChecks = const [],
    this.initialQualityChecksByPath = const {},
  });

  final List<String> initialPhotoPaths;
  final ReceiptDataSaverLevel initialDataSaverLevel;
  final bool bestShotCandidateMode;
  final int initialSelectedIndex;
  final List<ReceiptPhotoQualityCheck> initialQualityChecks;
  final Map<String, ReceiptPhotoQualityCheck> initialQualityChecksByPath;

  @override
  State<ReceiptPhotoReviewScreen> createState() =>
      _ReceiptPhotoReviewScreenState();
}

class _ReceiptPhotoReviewScreenState extends State<ReceiptPhotoReviewScreen> {
  late final List<String> _photoPaths = [...widget.initialPhotoPaths];
  late ReceiptDataSaverLevel _dataSaverLevel =
      widget.initialDataSaverLevel == ReceiptDataSaverLevel.original
      ? ReceiptDataSaverLevel.balanced
      : widget.initialDataSaverLevel;
  late var _selectedIndex = _initialSelectedIndex();
  var _openingCamera = false;
  var _controlsVisible = true;
  late var _reviewMode = _initialReviewMode();
  var _cropProcessing = false;
  var _savingPhotos = false;
  var _selectedStitchPairIndex = 0;
  final _storagePreviews = <String, ReceiptImageStoragePreview>{};
  final _previewKeysInFlight = <String>{};
  final _dataSaverPreviewPaths = <String, String>{};
  final _dataSaverPreviewKeysInFlight = <String>{};
  final _generatedEditPaths = <String>{};
  final _manualOverlapFractions = <double?>[];
  var _closingReview = false;
  late final _qualityChecksByPath = _initialQualityChecksByPath();
  ReceiptStitchResult? _stitchPreviewResult;
  String? _stitchPreviewKey;
  bool _stitchPreviewInFlight = false;
  Timer? _stitchPreviewDebounce;
  Uint8List? _cropImageBytes;
  Size? _cropImageSize;
  Rect? _cropRect;
  Rect? _cropDisplayRect;
  String? _cropSourcePath;
  final _toolControlsScrollController = ScrollController();

  ReceiptDeviceCapability get _deviceCapability {
    return ReceiptCaptureSettingsScope.maybeOf(context)?.deviceCapability ??
        const ReceiptDeviceCapability.standard();
  }

  ReceiptStitchDeviceLimits get _stitchDeviceLimits {
    return _deviceCapability.stitchLimits;
  }

  int _initialSelectedIndex() {
    if (_photoPaths.isEmpty) return 0;
    return widget.initialSelectedIndex.clamp(0, _photoPaths.length - 1);
  }

  _ReceiptReviewMode _initialReviewMode() {
    if (!widget.bestShotCandidateMode && widget.initialPhotoPaths.length > 1) {
      return _ReceiptReviewMode.order;
    }
    return _ReceiptReviewMode.preview;
  }

  @override
  void dispose() {
    _stitchPreviewDebounce?.cancel();
    _toolControlsScrollController.dispose();
    unawaited(_deleteGeneratedStitchPreview());
    unawaited(_deleteGeneratedDataSaverPreviews());
    unawaited(_deleteGeneratedEditPhotos(const {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_photoPaths.isEmpty) return _buildEmptyReviewRecovery();
    final photoPath = _photoPaths[_selectedIndex];
    _syncManualOverlapSlots();
    _ensureStoragePreview(photoPath);
    if (_reviewMode == _ReceiptReviewMode.dataSaver) {
      _ensureDataSaverImagePreview(photoPath);
    }
    if (_reviewMode == _ReceiptReviewMode.stitch && _photoPaths.length > 1) {
      _ensureStitchPreview();
    }
    final dataSaverPreviewPath =
        _dataSaverPreviewPaths[_dataSaverPreviewKey(photoPath)];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leaveReceiptReviewWithoutSaving();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050607),
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _reviewMode == _ReceiptReviewMode.crop
                  ? _buildCropSurface(photoPath)
                  : _reviewMode == _ReceiptReviewMode.stitch &&
                        _photoPaths.length > 1
                  ? _buildStitchSurface()
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
                    bestShotCandidateMode: widget.bestShotCandidateMode,
                    onClose: _reviewMode == _ReceiptReviewMode.crop
                        ? () => _setReviewMode(_ReceiptReviewMode.preview)
                        : _leaveReceiptReviewWithoutSaving,
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: _reviewBottomControlsMaxHeight(context),
                    ),
                    child: _buildReviewBottomControls(photoPath),
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

  Widget _buildEmptyReviewRecovery() {
    return Scaffold(
      backgroundColor: const Color(0xFF050607),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _OverlayIconButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Back to receipt form',
                  onPressed: _leaveReceiptReviewWithoutSaving,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.broken_image_rounded,
                color: Color(0xFFFFD166),
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Receipt photo was not available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Go back and take or choose the receipt photo again. No receipt fields were changed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _leaveReceiptReviewWithoutSaving,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back To Receipt Form'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: const Color(0xFF28A745),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewBottomControls(String photoPath) {
    final controls = _ReceiptReviewBottomControls(
      photoPaths: _photoPaths,
      selectedIndex: _selectedIndex,
      dataSaverLevel: _dataSaverLevel,
      storagePreview: _storagePreviews[_previewKey(photoPath)],
      selectedQualityCheck: _qualityChecksByPath[photoPath],
      reviewMode: _reviewMode,
      stitchPreview: _stitchPreviewResult,
      stitchPreviewInFlight: _stitchPreviewInFlight,
      stitchPairIndex: _selectedStitchPairIndex,
      manualOverlapFraction: _manualOverlapFractions.isEmpty
          ? null
          : _manualOverlapFractions[_selectedStitchPairIndex],
      toolControlsScrollController: _toolControlsScrollController,
      bestShotCandidateMode: widget.bestShotCandidateMode,
      canRemove: _photoPaths.length > 1,
      openingCamera: _openingCamera,
      cropProcessing: _cropProcessing,
      savingPhotos: _savingPhotos,
      onPhotoSelected: (index) => setState(() => _selectedIndex = index),
      onDataSaverSelected: (level) => setState(() => _dataSaverLevel = level),
      onModeChanged: _setReviewMode,
      onStitchPairSelected: (index) =>
          setState(() => _selectedStitchPairIndex = index),
      onManualOverlapChanged: _setManualOverlapFraction,
      onClearManualOverlap: _clearManualOverlapFraction,
      onMoveEarlier: () => _moveCurrentPhoto(-1),
      onMoveLater: () => _moveCurrentPhoto(1),
      onStraightenLeft: () => _rotateCurrentPhoto(-1.5),
      onStraightenRight: () => _rotateCurrentPhoto(1.5),
      onRotateLeft: () => _rotateCurrentPhoto(-90),
      onRotateRight: () => _rotateCurrentPhoto(90),
      onResetCrop: _resetCrop,
      onApplyCrop: _applyCrop,
      onCancelCrop: () => _setReviewMode(_ReceiptReviewMode.preview),
      onAddPhoto: _addAnotherPhoto,
      onRetake: _retakeCurrentPhoto,
      onRemove: () => unawaited(_removeCurrentPhoto()),
      onContinue: _continue,
    );
    return controls;
  }

  double _reviewBottomControlsMaxHeight(BuildContext context) {
    final proportional = MediaQuery.sizeOf(context).height * .22;
    final absolute = switch (_reviewMode) {
      _ReceiptReviewMode.preview => _photoPaths.length > 1 ? 150.0 : 112.0,
      _ReceiptReviewMode.crop => 96.0,
      _ReceiptReviewMode.order => 154.0,
      _ReceiptReviewMode.stitch => 176.0,
      _ReceiptReviewMode.dataSaver => 170.0,
    };
    return proportional < absolute ? proportional : absolute;
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
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                56,
                0,
                _controlsVisible ? _reviewSurfaceBottomPadding(context) : 0,
              ),
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

  double _reviewSurfaceBottomPadding(BuildContext context) {
    return _reviewBottomControlsMaxHeight(context) + 8;
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
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF050607)),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            0,
            58,
            0,
            _controlsVisible ? _reviewSurfaceBottomPadding(context) : 0,
          ),
          child: ReceiptEdgeCropper(
            imageBytes: imageBytes,
            imageSize: imageSize,
            cropRect: _cropRect,
            onCropRectChanged: _setCropRectFromCropper,
            onDisplayRectChanged: _setCropDisplayRectFromCropper,
          ),
        ),
      ),
    );
  }

  void _setCropRectFromCropper(Rect rect) {
    if (!mounted || _reviewMode != _ReceiptReviewMode.crop) return;
    if (_cropRect == rect) return;
    setState(() => _cropRect = rect);
  }

  void _setCropDisplayRectFromCropper(Rect rect) {
    if (!mounted || _reviewMode != _ReceiptReviewMode.crop) return;
    _cropDisplayRect = rect;
  }

  Widget _buildStitchSurface() {
    final preview = _stitchPreviewResult;
    final stitchedPath = preview?.stitchedPath;
    if (preview?.didStitch == true && stitchedPath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildPhotoSurface(stitchedPath),
          Positioned(
            left: 12,
            right: 12,
            top: 88,
            child: _StitchPreviewStatusBanner(
              stitch: preview!,
              rebuilding: _stitchPreviewInFlight,
            ),
          ),
        ],
      );
    }
    if (preview?.usedFallback == true) {
      final pairIndex = _selectedStitchPairIndex.clamp(
        0,
        _photoPaths.length - 2,
      );
      final overlap = _manualOverlapFractions.isEmpty
          ? .22
          : _manualOverlapFractions[pairIndex] ?? .22;
      return Stack(
        fit: StackFit.expand,
        children: [
          _ReceiptStitchPairPreview(
            firstPath: _photoPaths[pairIndex],
            secondPath: _photoPaths[pairIndex + 1],
            pairIndex: pairIndex,
            totalPairs: _photoPaths.length - 1,
            overlapFraction: overlap,
            bottomInset: _controlsVisible ? 154 : 18,
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 88,
            child: _StitchFallbackBanner(stitch: preview!),
          ),
        ],
      );
    }
    final pairIndex = _selectedStitchPairIndex.clamp(0, _photoPaths.length - 2);
    final overlap = _manualOverlapFractions.isEmpty
        ? .22
        : _manualOverlapFractions[pairIndex] ?? .22;
    return _ReceiptStitchPairPreview(
      firstPath: _photoPaths[pairIndex],
      secondPath: _photoPaths[pairIndex + 1],
      pairIndex: pairIndex,
      totalPairs: _photoPaths.length - 1,
      overlapFraction: overlap,
      bottomInset: _controlsVisible ? 154 : 18,
    );
  }

  void _updateReviewState(VoidCallback update) {
    setState(update);
  }

  void _syncManualOverlapSlots() {
    final needed = (_photoPaths.length - 1).clamp(0, 1000000);
    while (_manualOverlapFractions.length < needed) {
      _manualOverlapFractions.add(null);
    }
    while (_manualOverlapFractions.length > needed) {
      _manualOverlapFractions.removeLast();
    }
    if (needed == 0) {
      _selectedStitchPairIndex = 0;
    } else if (_selectedStitchPairIndex >= needed) {
      _selectedStitchPairIndex = needed - 1;
    }
  }

  void _setManualOverlapFraction(double value) {
    _syncManualOverlapSlots();
    if (_manualOverlapFractions.isEmpty) return;
    setState(() {
      _manualOverlapFractions[_selectedStitchPairIndex] = value.clamp(.08, .48);
    });
    _scheduleStitchPreviewRefresh();
  }

  void _clearManualOverlapFraction() {
    _syncManualOverlapSlots();
    if (_manualOverlapFractions.isEmpty) return;
    setState(() => _manualOverlapFractions[_selectedStitchPairIndex] = null);
    _scheduleStitchPreviewRefresh();
  }

  void _invalidateStitchPreview() {
    _stitchPreviewDebounce?.cancel();
    final previousPreviewPath = _stitchPreviewResult?.stitchedPath;
    _stitchPreviewKey = null;
    _stitchPreviewResult = null;
    _stitchPreviewInFlight = false;
    unawaited(_deleteStitchPreviewPath(previousPreviewPath));
  }

  void _scheduleStitchPreviewRefresh() {
    if (_reviewMode != _ReceiptReviewMode.stitch || _photoPaths.length <= 1) {
      _invalidateStitchPreview();
      return;
    }
    _stitchPreviewDebounce?.cancel();
    _stitchPreviewDebounce = Timer(const Duration(milliseconds: 260), () {
      if (mounted) _ensureStitchPreview(force: true);
    });
  }

  Future<void> _ensureStitchPreview({bool force = false}) async {
    if (_photoPaths.length <= 1 || _stitchPreviewInFlight) return;
    final key = _currentStitchPreviewKey();
    if (!force && _stitchPreviewKey == key && _stitchPreviewResult != null) {
      return;
    }
    _stitchPreviewDebounce?.cancel();
    final previousPreviewPath = _stitchPreviewResult?.stitchedPath;
    setState(() {
      _stitchPreviewInFlight = true;
      _stitchPreviewKey = key;
    });
    try {
      final manualOverlapFractions = _manualOverlapFractions
          .map((value) => value ?? 0)
          .toList(growable: false);
      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: _photoPaths,
        manualOverlapFractions: manualOverlapFractions.any((value) => value > 0)
            ? manualOverlapFractions
            : null,
        maxOutputPixels: _stitchDeviceLimits.maxOutputPixels,
        maxOutputHeight: _stitchDeviceLimits.maxOutputHeight,
      );
      if (!mounted || _currentStitchPreviewKey() != key) {
        await _deleteStitchPreviewPath(result.stitchedPath);
        return;
      }
      await _deleteStitchPreviewPath(previousPreviewPath);
      setState(() {
        _stitchPreviewResult = result;
        final failedPair = result.failedPairIndex;
        if (failedPair != null &&
            failedPair >= 0 &&
            failedPair < _photoPaths.length - 1) {
          _selectedStitchPairIndex = failedPair;
        }
        _stitchPreviewInFlight = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stitchPreviewResult = ReceiptStitchResult.fallback(
          inputPaths: _photoPaths,
          warning:
              'Receipt photos could not be matched into one safe image. Next will review them from top to bottom.',
        );
        _stitchPreviewInFlight = false;
      });
    }
  }

  String _currentStitchPreviewKey() {
    final overlapKey = _manualOverlapFractions
        .map((value) => value == null ? 'auto' : value.toStringAsFixed(3))
        .join('|');
    return '${_photoPaths.join('||')}::$overlapKey';
  }

  Future<void> _deleteGeneratedStitchPreview() async {
    final path = _stitchPreviewResult?.stitchedPath;
    await _deleteStitchPreviewPath(path);
  }

  Future<void> _deleteStitchPreviewPath(String? path) async {
    if (path == null || _photoPaths.contains(path)) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best effort cleanup for app-created stitch previews.
    }
  }

  Future<void> _ensureStoragePreview(String photoPath) async {
    final key = _previewKey(photoPath);
    if (_storagePreviews.containsKey(key) ||
        _previewKeysInFlight.contains(key)) {
      return;
    }
    _previewKeysInFlight.add(key);
    try {
      final preview = await ReceiptImageProcessor.previewPreparedBackupFile(
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
    final checks = <String, ReceiptPhotoQualityCheck>{
      ...widget.initialQualityChecksByPath,
    };
    final count =
        widget.initialPhotoPaths.length < widget.initialQualityChecks.length
        ? widget.initialPhotoPaths.length
        : widget.initialQualityChecks.length;
    for (var index = 0; index < count; index++) {
      if (checks.containsKey(widget.initialPhotoPaths[index])) continue;
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
      final previewPath =
          await ReceiptImageProcessor.optimizePreparedBackupFile(
            path: photoPath,
            level: _dataSaverLevel,
          );
      if (!mounted) return;
      setState(() => _dataSaverPreviewPaths[key] = previewPath);
    } catch (_) {
      if (mounted) _showCameraError('Could not preview this saved proof size.');
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
        // Best effort cleanup for app-created saved proof previews.
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
                'Preparing saved proof preview...',
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

class _StitchPreviewStatusBanner extends StatelessWidget {
  const _StitchPreviewStatusBanner({
    required this.stitch,
    required this.rebuilding,
  });

  final ReceiptStitchResult stitch;
  final bool rebuilding;

  @override
  Widget build(BuildContext context) {
    final title = rebuilding
        ? 'Checking Receipt Image'
        : 'Combined Receipt Preview';
    final detail = rebuilding
        ? 'Maintainiac is checking whether the receipt photos still line up.'
        : 'The photos matched safely. Next will review one combined receipt image.';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD050607),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF28A745)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            rebuilding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF28A745),
                    ),
                  )
                : const Icon(
                    Icons.done_all_rounded,
                    color: Color(0xFF28A745),
                    size: 19,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StitchFallbackBanner extends StatelessWidget {
  const _StitchFallbackBanner({required this.stitch});

  final ReceiptStitchResult stitch;

  @override
  Widget build(BuildContext context) {
    final pair = stitch.failedPairLabel;
    final detail = stitch.warning.trim().isEmpty
        ? 'The repeated lines were not clear enough to combine safely.'
        : stitch.warning;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEE050607),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.call_split_rounded,
              color: Color(0xFFFFD166),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Review Photos Top To Bottom',
                    style: TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  if (pair.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      '$pair needs match review.',
                      style: const TextStyle(
                        color: Color(0xFFFFD166),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '$detail If these two photos show repeated lines, adjust the match below. If not, tap Next and the app reviews each photo from top to bottom.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptStitchPairPreview extends StatelessWidget {
  const _ReceiptStitchPairPreview({
    required this.firstPath,
    required this.secondPath,
    required this.pairIndex,
    required this.totalPairs,
    required this.overlapFraction,
    required this.bottomInset,
  });

  final String firstPath;
  final String secondPath;
  final int pairIndex;
  final int totalPairs;
  final double overlapFraction;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final overlapPercent = (overlapFraction * 100).round();
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF050607)),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 58, 10, bottomInset),
          child: Column(
            children: [
              Expanded(
                child: _StitchPreviewPhoto(
                  path: firstPath,
                  label: 'Photo ${pairIndex + 1}',
                  alignment: Alignment.bottomCenter,
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: (10 + overlapFraction * 32).clamp(12, 28),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xCCFFD166),
                  border: Border.all(color: const Color(0xFFFFE7A8)),
                ),
                child: Text(
                  'Match repeated receipt text: $overlapPercent% guide, ${pairIndex + 1} of $totalPairs',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF11181B),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Expanded(
                child: _StitchPreviewPhoto(
                  path: secondPath,
                  label: 'Photo ${pairIndex + 2}',
                  alignment: Alignment.topCenter,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StitchPreviewPhoto extends StatelessWidget {
  const _StitchPreviewPhoto({
    required this.path,
    required this.label,
    required this.alignment,
  });

  final String path;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
            alignment: alignment,
          ),
        ),
        Align(
          alignment: alignment == Alignment.topCenter
              ? Alignment.topLeft
              : Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xCC050607),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
