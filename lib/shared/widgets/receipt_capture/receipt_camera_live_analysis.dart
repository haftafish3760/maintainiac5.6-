part of 'receipt_camera_screen.dart';

enum _ReceiptCameraMode { standard, assisted }

enum _ReceiptCameraReadiness { notReady, almostReady, ready }

class _ReceiptLiveFrameQuality {
  const _ReceiptLiveFrameQuality({
    required this.brightness,
    required this.contrast,
    required this.focusScore,
    required this.documentEdgeScore,
    required this.textBandScore,
    required this.cropScore,
    required this.skewScore,
    required this.lineBands,
    required this.readiness,
    required this.stableFor,
  });

  final double brightness;
  final double contrast;
  final double focusScore;
  final double documentEdgeScore;
  final double textBandScore;
  final double cropScore;
  final double skewScore;
  final List<double> lineBands;
  final _ReceiptCameraReadiness readiness;
  final Duration stableFor;

  bool get isTooDark => brightness < 72;
  bool get isTooBright => brightness > 222;
  bool get isLowContrast => contrast < 18;
  bool get isSoft => focusScore < 6.8;
  bool get isMissingEdges => documentEdgeScore < 10;
  bool get isMissingLineBands => textBandScore < 8;
  bool get isPoorlyFramed => cropScore < .42;
  bool get isSkewed => skewScore < .48;
  bool get looksReady => readiness == _ReceiptCameraReadiness.ready;

  _ReceiptLiveFrameQuality copyWith({
    _ReceiptCameraReadiness? readiness,
    Duration? stableFor,
  }) {
    return _ReceiptLiveFrameQuality(
      brightness: brightness,
      contrast: contrast,
      focusScore: focusScore,
      documentEdgeScore: documentEdgeScore,
      textBandScore: textBandScore,
      cropScore: cropScore,
      skewScore: skewScore,
      lineBands: lineBands,
      readiness: readiness ?? this.readiness,
      stableFor: stableFor ?? this.stableFor,
    );
  }
}

extension _ReceiptCameraLiveAnalysis on _ReceiptCameraScreenState {
  Future<void> _syncLiveAssistance() async {
    if (widget.liveGuidanceEnabled &&
        _mode == _ReceiptCameraMode.assisted &&
        !_capturing) {
      await _startLiveAssistance();
    } else {
      await _stopLiveAssistance();
    }
  }

  Future<void> _startLiveAssistance() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }
    try {
      await controller.startImageStream(_handleLiveFrame);
    } on CameraException {
      _showLiveAssistanceUnavailable();
    }
  }

  Future<void> _stopLiveAssistance() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        !controller.value.isStreamingImages) {
      return;
    }
    try {
      await controller.stopImageStream();
    } on CameraException {
      // The camera may already be stopping because the app is backgrounding.
    }
  }

  void _handleLiveFrame(CameraImage image) {
    final now = DateTime.now();
    final last = _lastAnalyzedFrameAt;
    if (_analyzingFrame ||
        last != null &&
            now.difference(last) < _ReceiptCameraCapturePolicy.analysisGap) {
      return;
    }
    _lastAnalyzedFrameAt = now;
    _analyzingFrame = true;
    scheduleMicrotask(() {
      final quality = _ReceiptLiveFrameAnalyzer.analyze(image);
      _analyzingFrame = false;
      if (!mounted || _mode != _ReceiptCameraMode.assisted || _capturing) {
        return;
      }
      _updateLiveFrameGuidance(quality);
    });
  }

  Future<void> _autoCaptureReadyReceipt() async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted ||
        !_autoCapture ||
        _capturing ||
        _mode != _ReceiptCameraMode.assisted ||
        _liveQuality?.readiness != _ReceiptCameraReadiness.ready) {
      _autoCaptureQueued = false;
      return;
    }
    await _captureAssistedScan();
  }

  _ReceiptLiveFrameQuality _qualityWithStability(
    _ReceiptLiveFrameQuality quality,
  ) {
    final now = DateTime.now();
    final previous = _previousFrameQuality;
    _previousFrameQuality = quality;
    final steady =
        previous != null &&
        (quality.brightness - previous.brightness).abs() < 9 &&
        (quality.focusScore - previous.focusScore).abs() < 4 &&
        (quality.cropScore - previous.cropScore).abs() < .16;
    if (quality.readiness == _ReceiptCameraReadiness.ready && steady) {
      _readyFrameStartedAt ??= now;
      final stableFor = now.difference(_readyFrameStartedAt!);
      return quality.copyWith(
        stableFor: stableFor,
        readiness: stableFor >= _ReceiptCameraCapturePolicy.readyHoldTime
            ? _ReceiptCameraReadiness.ready
            : _ReceiptCameraReadiness.almostReady,
      );
    }
    _readyFrameStartedAt = null;
    return quality.copyWith(stableFor: Duration.zero);
  }
}

class _ReceiptLiveFrameAnalyzer {
  const _ReceiptLiveFrameAnalyzer._();

  static _ReceiptLiveFrameQuality analyze(CameraImage image) {
    final plane = image.planes.first;
    final bytes = plane.bytes;
    if (bytes.isEmpty || image.width <= 0 || image.height <= 0) {
      return const _ReceiptLiveFrameQuality(
        brightness: 0,
        contrast: 0,
        focusScore: 0,
        documentEdgeScore: 0,
        textBandScore: 0,
        cropScore: 0,
        skewScore: 0,
        lineBands: [],
        readiness: _ReceiptCameraReadiness.notReady,
        stableFor: Duration.zero,
      );
    }
    final width = image.width;
    final height = image.height;
    final rowStride = plane.bytesPerRow;
    final pixelStride = plane.bytesPerPixel ?? 1;
    final stepX = (width / 28).ceil().clamp(1, 48);
    final stepY = (height / 42).ceil().clamp(1, 48);
    var sum = 0.0;
    var sumSquares = 0.0;
    var edgeDelta = 0.0;
    var horizontalDelta = 0.0;
    var verticalDelta = 0.0;
    var centerInk = 0;
    var outerInk = 0;
    final rowDarkCounts = <int>[];
    var count = 0;
    for (var y = stepY; y < height - stepY; y += stepY) {
      var rowDark = 0;
      for (var x = stepX; x < width - stepX; x += stepX) {
        final value = _sample(bytes, rowStride, pixelStride, x, y);
        final left = _sample(bytes, rowStride, pixelStride, x - stepX, y);
        final up = _sample(bytes, rowStride, pixelStride, x, y - stepY);
        sum += value;
        sumSquares += value * value;
        final dx = (value - left).abs();
        final dy = (value - up).abs();
        horizontalDelta += dx;
        verticalDelta += dy;
        edgeDelta += dx + dy;
        if (value < 132) {
          rowDark++;
          final centered =
              x > width * .16 &&
              x < width * .84 &&
              y > height * .12 &&
              y < height * .88;
          if (centered) {
            centerInk++;
          } else {
            outerInk++;
          }
        }
        count++;
      }
      rowDarkCounts.add(rowDark);
    }
    if (count == 0) {
      return const _ReceiptLiveFrameQuality(
        brightness: 0,
        contrast: 0,
        focusScore: 0,
        documentEdgeScore: 0,
        textBandScore: 0,
        cropScore: 0,
        skewScore: 0,
        lineBands: [],
        readiness: _ReceiptCameraReadiness.notReady,
        stableFor: Duration.zero,
      );
    }
    final brightness = sum / count;
    final variance = (sumSquares / count) - brightness * brightness;
    final focusScore = edgeDelta / (count * 2);
    final documentEdgeScore = (horizontalDelta + verticalDelta) / (count * 2);
    final textBandScore = _textBandScore(rowDarkCounts);
    final inkTotal = centerInk + outerInk;
    final cropScore = inkTotal == 0 ? 0.0 : centerInk / inkTotal;
    final lineBands = _lineBands(rowDarkCounts);
    final skewRatio = horizontalDelta <= 0 || verticalDelta <= 0
        ? 0.0
        : math.min(horizontalDelta, verticalDelta) /
              math.max(horizontalDelta, verticalDelta);
    final skewScore = skewRatio.clamp(0.0, 1.0);
    final base = _ReceiptLiveFrameQuality(
      brightness: brightness,
      contrast: variance <= 0 ? 0 : math.sqrt(variance),
      focusScore: focusScore,
      documentEdgeScore: documentEdgeScore,
      textBandScore: textBandScore,
      cropScore: cropScore,
      skewScore: skewScore,
      lineBands: lineBands,
      readiness: _ReceiptCameraReadiness.notReady,
      stableFor: Duration.zero,
    );
    return _ReceiptLiveFrameQuality(
      brightness: base.brightness,
      contrast: base.contrast,
      focusScore: base.focusScore,
      documentEdgeScore: base.documentEdgeScore,
      textBandScore: base.textBandScore,
      cropScore: base.cropScore,
      skewScore: base.skewScore,
      lineBands: base.lineBands,
      readiness: _readinessFor(base),
      stableFor: Duration.zero,
    );
  }

  static _ReceiptCameraReadiness _readinessFor(
    _ReceiptLiveFrameQuality quality,
  ) {
    if (quality.isTooDark ||
        quality.isTooBright ||
        quality.isSoft ||
        quality.isPoorlyFramed) {
      return _ReceiptCameraReadiness.notReady;
    }
    if (quality.isLowContrast ||
        quality.isMissingEdges ||
        quality.isMissingLineBands ||
        quality.isSkewed) {
      return _ReceiptCameraReadiness.almostReady;
    }
    return _ReceiptCameraReadiness.ready;
  }

  static double _textBandScore(List<int> rowDarkCounts) {
    if (rowDarkCounts.length < 4) return 0;
    var transitions = 0;
    var rowStrength = 0.0;
    for (var i = 1; i < rowDarkCounts.length; i++) {
      final previous = rowDarkCounts[i - 1];
      final current = rowDarkCounts[i];
      if ((previous == 0 && current > 0) || (previous > 0 && current == 0)) {
        transitions++;
      }
      rowStrength += (current - previous).abs();
    }
    return rowStrength / rowDarkCounts.length + transitions;
  }

  static List<double> _lineBands(List<int> rowDarkCounts) {
    if (rowDarkCounts.length < 6) return const [];
    final strongest = rowDarkCounts.reduce(math.max);
    if (strongest <= 0) return const [];
    final threshold = math.max(2, (strongest * .42).round());
    final bands = <double>[];
    var inBand = false;
    var bandStart = 0;
    for (var index = 0; index < rowDarkCounts.length; index++) {
      final active = rowDarkCounts[index] >= threshold;
      if (active && !inBand) {
        inBand = true;
        bandStart = index;
      } else if (!active && inBand) {
        final center = (bandStart + index - 1) / 2;
        bands.add(center / (rowDarkCounts.length - 1));
        inBand = false;
      }
    }
    if (inBand) {
      final center = (bandStart + rowDarkCounts.length - 1) / 2;
      bands.add(center / (rowDarkCounts.length - 1));
    }
    if (bands.length <= 14) return List.unmodifiable(bands);
    final stride = (bands.length / 14).ceil();
    return List.unmodifiable([
      for (var index = 0; index < bands.length; index += stride) bands[index],
    ]);
  }

  static int _sample(
    Uint8List bytes,
    int rowStride,
    int pixelStride,
    int x,
    int y,
  ) {
    final index = y * rowStride + x * pixelStride;
    if (index < 0 || index >= bytes.length) return 0;
    return bytes[index];
  }
}
