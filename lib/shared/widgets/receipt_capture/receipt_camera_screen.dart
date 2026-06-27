import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'receipt_capture_models.dart';
import 'receipt_assistance_policy.dart';
import 'receipt_image_processor.dart';
import 'receipt_storage_guard.dart';

part 'receipt_camera_bars.dart';
part 'receipt_camera_assist.dart';
part 'receipt_camera_buttons.dart';
part 'receipt_camera_error.dart';
part 'receipt_camera_capture.dart';
part 'receipt_camera_feedback.dart';
part 'receipt_camera_live_analysis.dart';
part 'receipt_camera_preview.dart';
part 'receipt_camera_setup.dart';

class ReceiptCameraScreen extends StatefulWidget {
  const ReceiptCameraScreen({
    super.key,
    this.startAssisted = false,
    this.liveGuidanceEnabled = true,
    this.autoCaptureEnabled = false,
    this.showLongReceiptTips = true,
    this.deviceCapability = const ReceiptDeviceCapability.standard(),
    this.previousSectionGuidePath,
    this.onSettings,
  });

  final bool startAssisted;
  final bool liveGuidanceEnabled;
  final bool autoCaptureEnabled;
  final bool showLongReceiptTips;
  final ReceiptDeviceCapability deviceCapability;
  final String? previousSectionGuidePath;
  final VoidCallback? onSettings;

  @override
  State<ReceiptCameraScreen> createState() => _ReceiptCameraScreenState();
}

class _ReceiptCameraScreenState extends State<ReceiptCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  var _loading = true;
  var _capturing = false;
  var _closingCamera = false;
  var _assistedScanning = false;
  var _mode = _ReceiptCameraMode.standard;
  var _autoCapture = false;
  var _autoCaptureQueued = false;
  var _guidedCaptureWaiting = false;
  var _torchOn = false;
  var _assist = _ReceiptCameraAssistState.idle;
  _ReceiptLiveFrameQuality? _liveQuality;
  late final _ReceiptCameraCapturePolicy _capturePolicy;
  var _minZoom = 1.0;
  var _maxZoom = 1.0;
  var _zoomLevel = 1.0;
  var _zoomStartLevel = 1.0;
  var _zoomSettingInFlight = false;
  double? _queuedZoomLevel;
  DateTime? _lastAnalyzedFrameAt;
  DateTime? _readyFrameStartedAt;
  var _stableReadyFrameCount = 0;
  _ReceiptLiveFrameQuality? _previousFrameQuality;
  var _analyzingFrame = false;
  String? _errorMessage;
  var _cameraPermissionBlocked = false;
  Offset? _focusReticlePosition;
  Timer? _focusReticleTimer;
  String? _interactionHint;
  Timer? _interactionHintTimer;
  var _lastFocusSetAt = DateTime.fromMillisecondsSinceEpoch(0);
  var _zoomUnavailableNotified = false;
  static const _receiptPhotoTimeout = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _mode = widget.startAssisted
        ? _ReceiptCameraMode.assisted
        : _ReceiptCameraMode.standard;
    _capturePolicy = _ReceiptCameraCapturePolicy.forCapability(
      widget.deviceCapability,
    );
    _autoCapture = widget.autoCaptureEnabled && widget.liveGuidanceEnabled;
    _assist = _mode == _ReceiptCameraMode.assisted
        ? _ReceiptCameraAssistState.starting
        : _ReceiptCameraAssistState.idle;
    _initializeCamera();
  }

  @override
  void dispose() {
    _closingCamera = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopLiveAssistance());
    _focusReticleTimer?.cancel();
    _interactionHintTimer?.cancel();
    final controller = _controller;
    _controller = null;
    unawaited(_disposeCameraController(controller));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;
    if (state == AppLifecycleState.inactive) {
      unawaited(_stopLiveAssistance());
      if (mounted) {
        setState(() => _controller = null);
      } else {
        _controller = null;
      }
      unawaited(_disposeCameraController(controller));
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted || _closingCamera) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _cameraPermissionBlocked = false;
    });
    try {
      final hasPermission = await _ensureCameraPermission();
      if (!hasPermission) return;
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_camera', 'No camera is available.');
      }
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = await _createInitializedController(camera);
      if (!mounted || _closingCamera) {
        await controller.dispose();
        return;
      }
      final previousController = _controller;
      if (previousController != null) {
        setState(() => _controller = null);
        await _disposeCameraController(previousController);
        if (!mounted || _closingCamera) {
          await controller.dispose();
          return;
        }
      }
      _controller = controller;
      await controller.setFlashMode(FlashMode.off);
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      await _resetReceiptExposureCompensation(controller);
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _torchOn = false;
        _minZoom = minZoom;
        _maxZoom = math.max(minZoom, maxZoom);
        _zoomLevel = minZoom;
        _zoomStartLevel = minZoom;
      });
      await _syncLiveAssistance();
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _cameraErrorMessage(error);
        _cameraPermissionBlocked = _isCameraPermissionError(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'The receipt camera could not be opened.';
      });
    }
  }

  Future<bool> _ensureCameraPermission() async {
    try {
      final current = await Permission.camera.status;
      if (current.isGranted || current.isLimited) return true;
      if (current.isPermanentlyDenied || current.isRestricted) {
        if (!mounted) return false;
        setState(() {
          _loading = false;
          _cameraPermissionBlocked = true;
          _errorMessage =
              'Camera permission is turned off. Open settings and allow camera access to photograph receipts.';
        });
        return false;
      }
      final requested = await Permission.camera.request();
      if (requested.isGranted || requested.isLimited) return true;
      if (!mounted) return false;
      setState(() {
        _loading = false;
        _cameraPermissionBlocked =
            requested.isPermanentlyDenied || requested.isRestricted;
        _errorMessage = _cameraPermissionBlocked
            ? 'Camera permission is turned off. Open settings and allow camera access to photograph receipts.'
            : 'Camera permission is needed to photograph receipts.';
      });
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final next = !_torchOn;
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (!mounted) return;
      setState(() => _torchOn = next);
      _showInteractionHint(next ? 'Torch on' : 'Torch off');
    } on CameraException {
      if (!mounted) return;
      _showInteractionHint('Torch is not available on this camera.');
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (_closingCamera ||
        _capturing ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);
    try {
      await _stopLiveAssistance();
      final storage = await ReceiptStorageGuard.check(
        ReceiptStoragePurpose.capturePhoto,
      );
      if (!mounted) return;
      if (!storage.hasEnoughSpace) {
        setState(() => _capturing = false);
        _showStorageDialog(
          storage.blockingMessage(ReceiptStoragePurpose.capturePhoto),
        );
        return;
      }
      if (!storage.canVerify) {
        _showMessage(
          storage.unknownMessage(ReceiptStoragePurpose.capturePhoto),
        );
      } else if (storage.shouldWarnLowStorage) {
        _showMessage(storage.warningMessage());
      }
      setState(() => _assist = _ReceiptCameraAssistState.steady);
      await _primeReceiptCameraForCapture(
        controller,
        settleDelay: _capturePolicy.manualSettleDelay,
      );
      final candidates = <_ReceiptCameraCandidate>[];
      for (var index = 0; index < _capturePolicy.quickShotCount; index++) {
        if (!mounted) return;
        setState(() {
          _assist = index == 0
              ? _ReceiptCameraAssistState.steady
              : _ReceiptCameraAssistState.forCapture(index);
        });
        final photo = await _takeReceiptPhoto(controller);
        final quality = await ReceiptImageProcessor.qualityCheckFile(
          photo.path,
        );
        candidates.add(
          _ReceiptCameraCandidate(path: photo.path, quality: quality),
        );
        if (index < _capturePolicy.quickShotCount - 1) {
          await Future<void>.delayed(_capturePolicy.quickShotGap);
        }
      }
      if (!mounted || _closingCamera) return;
      candidates.sort(_compareReceiptCameraCandidates);
      final best = candidates.firstOrNull;
      final selectedCandidates = [?best];
      final selected = selectedCandidates.map((photo) => photo.path).toList();
      await _deleteUnusedReceiptCameraPhotos(candidates, selected.toSet());
      if (!mounted || _closingCamera) return;
      _finishCameraWithResult(
        ReceiptCameraResult.bestShotCandidates(
          selected,
          qualityChecks: [
            for (final candidate in selectedCandidates) candidate.quality,
          ],
        ),
      );
    } on TimeoutException {
      if (!mounted || _closingCamera) return;
      setState(() => _capturing = false);
      unawaited(_syncLiveAssistance());
      _showMessage('The camera did not finish the photo. Try again.');
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() => _capturing = false);
      unawaited(_syncLiveAssistance());
      _showMessage(_cameraErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _capturing = false);
      unawaited(_syncLiveAssistance());
      _showMessage('The receipt photo could not be captured.');
    }
  }

  Future<void> _captureAssistedScan() async {
    final controller = _controller;
    if (_closingCamera ||
        _capturing ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    setState(() {
      _capturing = true;
      _assistedScanning = true;
      _assist = _ReceiptCameraAssistState.starting;
    });
    try {
      await _stopLiveAssistance();
      final storage = await ReceiptStorageGuard.check(
        ReceiptStoragePurpose.capturePhoto,
      );
      if (!mounted) return;
      if (!storage.hasEnoughSpace) {
        setState(() {
          _capturing = false;
          _assistedScanning = false;
          _assist = _ReceiptCameraAssistState.lowStorage;
        });
        _showStorageDialog(
          storage.blockingMessage(ReceiptStoragePurpose.capturePhoto),
        );
        return;
      }
      if (!storage.canVerify) {
        _showMessage(
          storage.unknownMessage(ReceiptStoragePurpose.capturePhoto),
        );
      } else if (storage.shouldWarnLowStorage) {
        _showMessage(storage.warningMessage());
      }
      setState(() => _assist = _ReceiptCameraAssistState.steady);
      await _primeReceiptCameraForCapture(
        controller,
        settleDelay: _capturePolicy.assistedSettleDelay,
      );
      final candidates = <_ReceiptCameraCandidate>[];
      for (var index = 0; index < _capturePolicy.assistedShotCount; index++) {
        if (!mounted) return;
        setState(() => _assist = _ReceiptCameraAssistState.forCapture(index));
        final photo = await _takeReceiptPhoto(controller);
        final quality = await ReceiptImageProcessor.qualityCheckFile(
          photo.path,
        );
        candidates.add(
          _ReceiptCameraCandidate(path: photo.path, quality: quality),
        );
        if (mounted) {
          setState(() {
            _assist = _ReceiptCameraAssistState.fromQuality(
              quality,
              captureIndex: index,
            );
          });
        }
        if (index < _capturePolicy.assistedShotCount - 1) {
          await Future<void>.delayed(_capturePolicy.assistedShotGap);
        }
      }
      if (!mounted || _closingCamera) return;
      candidates.sort(_compareReceiptCameraCandidates);
      final best = candidates.firstOrNull;
      final selectedCandidates = [?best];
      if (selectedCandidates.isEmpty) {
        setState(() {
          _capturing = false;
          _assistedScanning = false;
          _assist = _ReceiptCameraAssistState.noPhoto;
        });
        _showMessage('No receipt images were captured.');
        return;
      }
      final selected = selectedCandidates.map((photo) => photo.path).toList();
      await _deleteUnusedReceiptCameraPhotos(candidates, selected.toSet());
      if (!mounted || _closingCamera) return;
      setState(() {
        _guidedCaptureWaiting = false;
        _assist = _ReceiptCameraAssistState.finished;
      });
      _finishCameraWithResult(
        ReceiptCameraResult.bestShotCandidates(
          selected,
          qualityChecks: [
            for (final candidate in selectedCandidates) candidate.quality,
          ],
        ),
      );
    } on TimeoutException {
      if (!mounted || _closingCamera) return;
      setState(() {
        _capturing = false;
        _assistedScanning = false;
        _assist = _ReceiptCameraAssistState.idle;
      });
      _showMessage('The camera did not finish the assisted photo. Try again.');
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _assistedScanning = false;
        _assist = _ReceiptCameraAssistState.idle;
      });
      _showMessage(_cameraErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _assistedScanning = false;
        _assist = _ReceiptCameraAssistState.idle;
      });
      _showMessage('Assisted receipt scan could not finish.');
    }
  }

  void _handleCapturePressed() {
    _autoCaptureQueued = false;
    _guidedCaptureWaiting = false;
    unawaited(_capturePhoto());
  }

  Future<XFile> _takeReceiptPhoto(CameraController controller) {
    return controller.takePicture().timeout(_receiptPhotoTimeout);
  }

  Future<void> _primeReceiptCameraForCapture(
    CameraController controller, {
    required Duration settleDelay,
  }) async {
    await controller.setFocusMode(FocusMode.auto);
    await controller.setExposureMode(ExposureMode.auto);
    const receiptTextPoint = Offset(.5, .58);
    try {
      await controller.setFocusPoint(receiptTextPoint);
    } on CameraException {
      // Tap-to-focus is best effort; many older phones still capture normally.
    }
    try {
      await controller.setExposurePoint(receiptTextPoint);
    } on CameraException {
      // Exposure points are also device-dependent.
    }
    await Future<void>.delayed(settleDelay);
  }

  Future<void> _resetReceiptExposureCompensation(
    CameraController controller,
  ) async {
    try {
      final minOffset = await controller.getMinExposureOffset();
      final maxOffset = await controller.getMaxExposureOffset();
      final safeOffset = _receiptExposureOffsetFor(minOffset, maxOffset);
      await controller.setExposureOffset(safeOffset);
    } on CameraException {
      // Exposure compensation is not supported consistently across devices.
    } on UnsupportedError {
      // Older camera backends can report the method but reject it at runtime.
    }
  }

  double _receiptExposureOffsetFor(double minOffset, double maxOffset) {
    if (minOffset.isNaN || maxOffset.isNaN || minOffset > maxOffset) {
      return 0.0;
    }
    // Keep the camera at the native auto-exposure baseline. Forced positive
    // compensation can slow capture or diverge from the phone camera look.
    return 0.0.clamp(minOffset, maxOffset).toDouble();
  }

  Future<void> _disposeCameraController(CameraController? controller) async {
    if (controller == null) return;
    try {
      if (controller.value.isInitialized &&
          controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {
      // The stream may already be gone while the native camera is closing.
    }
    try {
      await controller.dispose();
    } catch (_) {
      // Dispose can race native camera shutdown on some Android devices.
    }
  }

  void _requestCloseCamera() {
    if (_closingCamera) return;
    _closingCamera = true;
    _autoCaptureQueued = false;
    _guidedCaptureWaiting = false;
    _interactionHintTimer?.cancel();
    _focusReticleTimer?.cancel();
    final controller = _controller;
    if (mounted) {
      setState(() {
        _controller = null;
        _loading = false;
        _capturing = false;
        _assistedScanning = false;
      });
      Navigator.of(context).pop();
      unawaited(_disposeCameraController(controller));
    } else {
      _controller = null;
      unawaited(_disposeCameraController(controller));
    }
  }

  void _finishCameraWithResult(ReceiptCameraResult result) {
    if (!mounted || _closingCamera) return;
    _closingCamera = true;
    _autoCaptureQueued = false;
    _guidedCaptureWaiting = false;
    _interactionHintTimer?.cancel();
    _focusReticleTimer?.cancel();
    final controller = _controller;
    setState(() {
      _controller = null;
      _capturing = false;
      _assistedScanning = false;
    });
    Navigator.of(context).pop<ReceiptCameraResult>(result);
    unawaited(_disposeCameraController(controller));
  }

  void _showLiveAssistanceUnavailable() {
    if (!mounted) return;
    setState(() {
      _assist = const _ReceiptCameraAssistState(
        title: 'Manual Camera Ready',
        message: 'Live guidance is not available on this camera.',
        icon: Icons.camera_alt_rounded,
        color: Color(0xFFFFD166),
      );
    });
  }

  void _showInteractionHint(
    String message, {
    Duration duration = const Duration(milliseconds: 1400),
  }) {
    if (!mounted) return;
    _interactionHintTimer?.cancel();
    setState(() => _interactionHint = message);
    _interactionHintTimer = Timer(duration, () {
      if (mounted) setState(() => _interactionHint = null);
    });
  }

  void _updateLiveFrameGuidance(_ReceiptLiveFrameQuality quality) {
    if (!mounted || _capturing) return;
    final stableQuality = _qualityWithStability(quality);
    final shouldAutoCapture =
        (_autoCapture || _guidedCaptureWaiting) &&
        !_autoCaptureQueued &&
        _mode == _ReceiptCameraMode.assisted &&
        stableQuality.meetsAutoCapturePolicy(_capturePolicy) &&
        _stableReadyFrameCount >= _capturePolicy.minimumAutoCaptureFrames &&
        stableQuality.stableFor >= _capturePolicy.readyHoldTime;
    setState(() {
      _liveQuality = stableQuality;
      _assist = _ReceiptCameraAssistState.fromLiveFrame(stableQuality);
      if (shouldAutoCapture) _autoCaptureQueued = true;
    });
    if (shouldAutoCapture) unawaited(_autoCaptureReadyReceipt());
  }

  Future<void> _focusAt(Offset position, Size previewSize) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (previewSize.width <= 0 || previewSize.height <= 0) return;
    final now = DateTime.now();
    if (now.difference(_lastFocusSetAt) < const Duration(milliseconds: 300)) {
      return;
    }
    final point = _normalizedCameraPointForPreview(
      position: position,
      viewSize: previewSize,
      controller: controller,
    );

    var adjustedCamera = false;
    try {
      await controller.setFocusPoint(point);
      adjustedCamera = true;
    } on CameraException {
      // Some devices expose tap focus poorly but still allow exposure control.
    }
    try {
      await controller.setExposurePoint(point);
      adjustedCamera = true;
    } on CameraException {
      // Exposure is also best-effort on older or restricted camera backends.
    }
    if (!mounted) return;
    if (!adjustedCamera) {
      _showInteractionHint('Tap focus is not available on this camera.');
      return;
    }
    _focusReticleTimer?.cancel();
    setState(() {
      _focusReticlePosition = position;
      _lastFocusSetAt = now;
    });
    _showInteractionHint('Focus set');
    _focusReticleTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _focusReticlePosition = null);
    });
  }

  Offset _normalizedCameraPointForPreview({
    required Offset position,
    required Size viewSize,
    required CameraController controller,
  }) {
    final nativePreviewSize = controller.value.previewSize;
    if (nativePreviewSize == null ||
        nativePreviewSize.width <= 0 ||
        nativePreviewSize.height <= 0) {
      return Offset(
        (position.dx / viewSize.width).clamp(0, 1),
        (position.dy / viewSize.height).clamp(0, 1),
      );
    }

    final displayedPreviewSize = Size(
      nativePreviewSize.height,
      nativePreviewSize.width,
    );
    final scale = math.max(
      viewSize.width / displayedPreviewSize.width,
      viewSize.height / displayedPreviewSize.height,
    );
    final renderedSize = displayedPreviewSize * scale;
    final cropOffset = Offset(
      (renderedSize.width - viewSize.width) / 2,
      (renderedSize.height - viewSize.height) / 2,
    );
    return Offset(
      ((position.dx + cropOffset.dx) / renderedSize.width).clamp(0, 1),
      ((position.dy + cropOffset.dy) / renderedSize.height).clamp(0, 1),
    );
  }

  void _startZoomGesture(ScaleStartDetails details) {
    _zoomStartLevel = _zoomLevel;
  }

  Future<void> _updateZoomGesture(ScaleUpdateDetails details) async {
    if ((details.scale - 1.0).abs() < .01) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_maxZoom <= _minZoom + .05) {
      if (!_zoomUnavailableNotified) {
        _zoomUnavailableNotified = true;
        _showInteractionHint('Zoom is not available on this camera.');
      }
      return;
    }
    final nextZoom = (_zoomStartLevel * details.scale).clamp(
      _minZoom,
      _maxZoom,
    );
    if ((nextZoom - _zoomLevel).abs() < .03) return;
    _queuedZoomLevel = nextZoom;
    if (_zoomSettingInFlight) return;
    _zoomSettingInFlight = true;
    try {
      while (mounted && !_closingCamera && _queuedZoomLevel != null) {
        final target = _queuedZoomLevel!;
        _queuedZoomLevel = null;
        await controller.setZoomLevel(target);
        if (!mounted || _closingCamera) return;
        setState(() {
          _zoomLevel = target;
          _zoomUnavailableNotified = false;
        });
      }
    } on CameraException {
      if (!_zoomUnavailableNotified) {
        _zoomUnavailableNotified = true;
        _showInteractionHint('Zoom is not available on this camera.');
      }
    } finally {
      _zoomSettingInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestCloseCamera();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050607),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_closingCamera) {
      return const SizedBox.expand();
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD166)),
      );
    }
    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return _ReceiptCameraError(
        message: errorMessage,
        onRetry: _initializeCamera,
        onClose: _requestCloseCamera,
        onOpenSettings: _cameraPermissionBlocked
            ? () => openAppSettings()
            : null,
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _ReceiptCameraError(
        message: 'The receipt camera is not ready.',
        onRetry: _initializeCamera,
        onClose: _requestCloseCamera,
      );
    }
    final liveFrame = _liveFrameForOverlay();
    return Stack(
      fit: StackFit.expand,
      children: [
        _FullScreenCameraPreview(controller: controller),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onScaleStart: _startZoomGesture,
                onScaleUpdate: _updateZoomGesture,
                onTapUp: (details) => _focusAt(details.localPosition, size),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
        if (liveFrame?.isUsable == true)
          _ReceiptLiveEdgeOverlay(frame: liveFrame!),
        if (widget.previousSectionGuidePath != null)
          Positioned(
            left: 12,
            right: 12,
            top: MediaQuery.paddingOf(context).top + 116,
            child: _ReceiptPreviousSectionGuide(
              photoPath: widget.previousSectionGuidePath!,
            ),
          ),
        if (_focusReticlePosition != null)
          _ReceiptFocusReticle(
            position: _focusReticlePosition!,
            label:
                _lastFocusSetAt.isAfter(
                  DateTime.now().subtract(const Duration(seconds: 2)),
                )
                ? 'Focus set'
                : null,
          ),
        Positioned(
          left: 12,
          right: 12,
          top: MediaQuery.paddingOf(context).top + 62,
          child: IgnorePointer(
            child: _ReceiptCameraGuidancePill(
              assist: _assist,
              liveQuality: _liveQuality,
              autoCaptureEnabled: _autoCapture || _guidedCaptureWaiting,
              autoCaptureReady:
                  _liveQuality?.meetsAutoCapturePolicy(_capturePolicy) == true,
            ),
          ),
        ),
        _ReceiptZoomLevelBadge(zoomLevel: _zoomLevel, minZoom: _minZoom),
        if (_interactionHint != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: MediaQuery.paddingOf(context).bottom + 166,
            child: _ReceiptCameraInteractionHint(message: _interactionHint!),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: _ReceiptCameraBottomBar(
              capturing: _capturing,
              assistedScanning: _assistedScanning,
              assistedMode: _mode == _ReceiptCameraMode.assisted,
              autoCaptureEnabled: _autoCapture || _guidedCaptureWaiting,
              longReceiptTipsEnabled: widget.showLongReceiptTips,
              onCapture: _handleCapturePressed,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _ReceiptCameraTopBar(
            torchOn: _torchOn,
            onClose: _requestCloseCamera,
            onTorch: _toggleTorch,
            onSettings: widget.onSettings,
          ),
        ),
      ],
    );
  }

  _ReceiptDocumentFrame? _liveFrameForOverlay() {
    if (!_capturePolicy.enableLiveEdgeOverlay ||
        _mode != _ReceiptCameraMode.assisted) {
      return null;
    }
    final frame = _liveQuality?.documentFrame;
    if (frame == null ||
        !frame.isUsable ||
        frame.confidence < _capturePolicy.minimumLiveEdgeConfidence) {
      return null;
    }
    return frame;
  }
}
