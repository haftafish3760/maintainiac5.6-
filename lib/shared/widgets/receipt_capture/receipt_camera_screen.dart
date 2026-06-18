import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'receipt_capture_models.dart';
import 'receipt_image_picker.dart';
import 'receipt_image_processor.dart';
import 'receipt_storage_guard.dart';

part 'receipt_camera_bars.dart';
part 'receipt_camera_hints.dart';
part 'receipt_camera_assist.dart';
part 'receipt_camera_frame_overlay.dart';
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
    this.startAssisted = true,
    this.liveGuidanceEnabled = true,
    this.autoCaptureEnabled = false,
    this.showLongReceiptTips = true,
  });

  final bool startAssisted;
  final bool liveGuidanceEnabled;
  final bool autoCaptureEnabled;
  final bool showLongReceiptTips;

  @override
  State<ReceiptCameraScreen> createState() => _ReceiptCameraScreenState();
}

class _ReceiptCameraScreenState extends State<ReceiptCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  var _loading = true;
  var _capturing = false;
  var _assistedScanning = false;
  var _mode = _ReceiptCameraMode.standard;
  var _autoCapture = false;
  var _autoCaptureQueued = false;
  var _torchOn = false;
  var _assist = _ReceiptCameraAssistState.idle;
  _ReceiptLiveFrameQuality? _liveQuality;
  DateTime? _lastAnalyzedFrameAt;
  DateTime? _readyFrameStartedAt;
  _ReceiptLiveFrameQuality? _previousFrameQuality;
  var _analyzingFrame = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _mode = widget.startAssisted
        ? _ReceiptCameraMode.assisted
        : _ReceiptCameraMode.standard;
    _autoCapture = widget.autoCaptureEnabled && widget.liveGuidanceEnabled;
    _assist = _mode == _ReceiptCameraMode.assisted
        ? _ReceiptCameraAssistState.starting
        : _ReceiptCameraAssistState.idle;
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopLiveAssistance());
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;
    if (state == AppLifecycleState.inactive) {
      unawaited(_stopLiveAssistance());
      _controller = null;
      unawaited(controller.dispose());
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_camera', 'No camera is available.');
      }
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = await _createInitializedController(camera);
      await _controller?.dispose();
      _controller = controller;
      await controller.setFlashMode(FlashMode.off);
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _torchOn = false;
      });
      await _syncLiveAssistance();
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _cameraErrorMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'The receipt camera could not be opened.';
      });
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final next = !_torchOn;
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torchOn = next);
    } on CameraException {
      if (!mounted) return;
      _showMessage('Torch is not available on this camera.');
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
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
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      await Future<void>.delayed(_ReceiptCameraCapturePolicy.settleDelay);
      if (!mounted) return;
      final photo = await controller.takePicture();
      final quality = await ReceiptImageProcessor.qualityCheckFile(photo.path);
      if (!mounted) return;
      if (!quality.isLikelyReadable) {
        _showMessage(_ReceiptCameraAssistState.needsRetake(quality).message);
      }
      Navigator.of(context).pop<ReceiptCameraResult>(
        ReceiptCameraResult.single([photo.path], qualityChecks: [quality]),
      );
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
    if (_capturing || controller == null || !controller.value.isInitialized) {
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
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      await Future<void>.delayed(_ReceiptCameraCapturePolicy.settleDelay);
      final candidates = <_ReceiptCameraCandidate>[];
      for (
        var index = 0;
        index < _ReceiptCameraCapturePolicy.assistedShotCount;
        index++
      ) {
        if (!mounted) return;
        setState(() => _assist = _ReceiptCameraAssistState.forCapture(index));
        final photo = await controller.takePicture();
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
        if (index < _ReceiptCameraCapturePolicy.assistedShotCount - 1) {
          await Future<void>.delayed(
            _ReceiptCameraCapturePolicy.assistedShotGap,
          );
        }
      }
      if (!mounted) return;
      candidates.sort(_compareReceiptCameraCandidates);
      final best = candidates.firstOrNull;
      if (best != null && !best.quality.isLikelyReadable) {
        setState(() {
          _capturing = false;
          _assistedScanning = false;
          _assist = _ReceiptCameraAssistState.needsRetake(best.quality);
        });
        await _deleteUnusedReceiptCameraPhotos(candidates, const {});
        _showMessage(_assist.message);
        return;
      }
      final selectedCandidates = candidates.take(5).toList();
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
      if (!mounted) return;
      setState(() => _assist = _ReceiptCameraAssistState.finished);
      Navigator.of(context).pop<ReceiptCameraResult>(
        ReceiptCameraResult.bestShotCandidates(
          selected,
          qualityChecks: [
            for (final candidate in selectedCandidates) candidate.quality,
          ],
        ),
      );
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

  void _setAutoCapture(bool enabled) {
    if (!widget.liveGuidanceEnabled) {
      _showMessage('Live guidance must be on before auto capture can run.');
      return;
    }
    if (_capturing) return;
    setState(() {
      _autoCapture = enabled;
      _autoCaptureQueued = false;
      if (enabled && _mode != _ReceiptCameraMode.assisted) {
        _mode = _ReceiptCameraMode.assisted;
        _assist = _ReceiptCameraAssistState.starting;
      }
    });
    unawaited(_syncLiveAssistance());
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

  void _updateLiveFrameGuidance(_ReceiptLiveFrameQuality quality) {
    if (!mounted || _mode != _ReceiptCameraMode.assisted || _capturing) return;
    final stableQuality = _qualityWithStability(quality);
    final shouldAutoCapture =
        _autoCapture &&
        !_autoCaptureQueued &&
        stableQuality.readiness == _ReceiptCameraReadiness.ready;
    setState(() {
      _liveQuality = stableQuality;
      _assist = _ReceiptCameraAssistState.fromLiveFrame(stableQuality);
      if (shouldAutoCapture) _autoCaptureQueued = true;
    });
    if (shouldAutoCapture) unawaited(_autoCaptureReadyReceipt());
  }

  Future<void> _openDeviceCamera() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final photo = await ReceiptImagePicker.takeReceiptPhoto();
      if (!mounted) return;
      if (photo == null) {
        setState(() => _capturing = false);
        return;
      }
      Navigator.of(
        context,
      ).pop<ReceiptCameraResult>(ReceiptCameraResult.single([photo.path]));
    } catch (_) {
      if (!mounted) return;
      setState(() => _capturing = false);
      _showMessage('The device camera did not open correctly.');
    }
  }

  Future<void> _focusAt(Offset position, Size previewSize) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final point = Offset(
      (position.dx / previewSize.width).clamp(0, 1),
      (position.dy / previewSize.height).clamp(0, 1),
    );
    try {
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
    } on CameraException {
      _showMessage('Tap focus is not available on this camera.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_capturing,
      child: Scaffold(
        backgroundColor: const Color(0xFF050607),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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
        onClose: () => Navigator.of(context).pop(),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _ReceiptCameraError(
        message: 'The receipt camera is not ready.',
        onRetry: _initializeCamera,
        onClose: () => Navigator.of(context).pop(),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _focusAt(details.localPosition, size),
              child: _FullScreenCameraPreview(controller: controller),
            );
          },
        ),
        Positioned.fill(
          child: _ReceiptCameraFrameOverlay(mode: _mode, quality: _liveQuality),
        ),
        Positioned(
          left: 14,
          right: 14,
          top: MediaQuery.paddingOf(context).top + 88,
          child: _ReceiptCameraAssistCard(state: _assist),
        ),
        _ReceiptCameraTopBar(
          torchOn: _torchOn,
          onClose: () => Navigator.of(context).pop(),
          onDeviceCamera: _openDeviceCamera,
          onTorch: _toggleTorch,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _ReceiptCameraBottomBar(
            capturing: _capturing,
            assistedScanning: _assistedScanning,
            mode: _mode,
            autoCapture: _autoCapture,
            autoCaptureAvailable:
                widget.liveGuidanceEnabled && widget.autoCaptureEnabled,
            showLongReceiptTips: widget.showLongReceiptTips,
            assistState: _assist,
            liveQuality: _liveQuality,
            onCapture: _capturePhoto,
            onAssistedScan: _captureAssistedScan,
            onAutoCaptureChanged: _setAutoCapture,
          ),
        ),
      ],
    );
  }
}
