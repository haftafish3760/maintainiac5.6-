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
    required this.bottomContentScore,
    required this.lineBands,
    required this.readiness,
    required this.stableFor,
    this.documentFrame,
  });

  final double brightness;
  final double contrast;
  final double focusScore;
  final double documentEdgeScore;
  final double textBandScore;
  final double cropScore;
  final double skewScore;
  final double bottomContentScore;
  final List<double> lineBands;
  final _ReceiptCameraReadiness readiness;
  final Duration stableFor;
  final _ReceiptDocumentFrame? documentFrame;

  bool get isTooDark => brightness < 72;
  bool get isTooBright => brightness > 222;
  bool get isLowContrast => contrast < 18;
  bool get isSoft => focusScore < 6.8;
  bool get isMissingEdges => documentEdgeScore < 10;
  bool get isMissingLineBands => textBandScore < 8;
  bool get isPoorlyFramed => cropScore < .42;
  bool get isSkewed => skewScore < .48;
  bool get mayBeCutOffAtBottom {
    return textBandScore >= 8 &&
        (bottomContentScore > .16 ||
            (lineBands.isNotEmpty && lineBands.last > .92));
  }

  bool get looksReady => readiness == _ReceiptCameraReadiness.ready;
  bool get hasUsableDocumentFrame => documentFrame?.isUsable == true;
  bool get canAutoCaptureReceipt {
    return looksReady &&
        !mayBeCutOffAtBottom &&
        focusScore >= 7.5 &&
        contrast >= 18 &&
        textBandScore >= 8 &&
        cropScore >= .48;
  }

  bool meetsAutoCapturePolicy(_ReceiptCameraCapturePolicy policy) {
    return looksReady &&
        !hasHardAutoCaptureBlock &&
        !mayBeCutOffAtBottom &&
        !isSkewed &&
        focusScore >= policy.minimumAutoFocusScore &&
        contrast >= policy.minimumAutoContrast &&
        textBandScore >= policy.minimumAutoTextBandScore &&
        cropScore >= policy.minimumAutoCropScore;
  }

  bool get hasHardAutoCaptureBlock => isTooDark || isTooBright || isSoft;
  String get autoCaptureStatusLabel {
    if (isTooDark) return 'Add light';
    if (isTooBright) return 'Reduce glare';
    if (isSoft) return 'Tap receipt text';
    if (isPoorlyFramed) return 'Check full receipt';
    if (mayBeCutOffAtBottom) return 'Show full receipt';
    if (isSkewed) return 'Square it up';
    if (contrast < 18) return 'Improve contrast';
    if (textBandScore < 8) return 'Move closer';
    if (cropScore < .48) return 'Fill the frame';
    if (stableFor > Duration.zero &&
        readiness != _ReceiptCameraReadiness.ready) {
      return 'Hold steady';
    }
    if (readiness == _ReceiptCameraReadiness.ready) return 'Ready to capture';
    return 'Ready';
  }

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
      bottomContentScore: bottomContentScore,
      lineBands: lineBands,
      readiness: readiness ?? this.readiness,
      stableFor: stableFor ?? this.stableFor,
      documentFrame: documentFrame,
    );
  }
}

class _ReceiptDocumentFrame {
  const _ReceiptDocumentFrame({
    required this.normalizedRect,
    required this.confidence,
  });

  final Rect normalizedRect;
  final double confidence;

  bool get isUsable {
    return confidence >= .52 &&
        normalizedRect.width >= .22 &&
        normalizedRect.height >= .28;
  }
}

extension _ReceiptCameraLiveAnalysis on _ReceiptCameraScreenState {
  Future<void> _syncLiveAssistance() async {
    if (widget.liveGuidanceEnabled && !_capturing) {
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
        last != null && now.difference(last) < _capturePolicy.analysisGap) {
      return;
    }
    _lastAnalyzedFrameAt = now;
    _analyzingFrame = true;
    scheduleMicrotask(() {
      final quality = _ReceiptLiveFrameAnalyzer.analyze(image);
      _analyzingFrame = false;
      if (!mounted || _capturing) {
        return;
      }
      _updateLiveFrameGuidance(quality);
    });
  }

  Future<void> _autoCaptureReadyReceipt() async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted ||
        (!_autoCapture && !_guidedCaptureWaiting) ||
        !_autoCaptureQueued ||
        _capturing ||
        _mode != _ReceiptCameraMode.assisted ||
        _liveQuality?.meetsAutoCapturePolicy(_capturePolicy) != true ||
        _liveQuality?.looksReady != true) {
      _autoCaptureQueued = false;
      return;
    }
    _autoCaptureQueued = false;
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
        (quality.brightness - previous.brightness).abs() < 6 &&
        (quality.contrast - previous.contrast).abs() < 6 &&
        (quality.focusScore - previous.focusScore).abs() < 2.4 &&
        (quality.textBandScore - previous.textBandScore).abs() < 2.8 &&
        (quality.cropScore - previous.cropScore).abs() < .09;
    if (quality.meetsAutoCapturePolicy(_capturePolicy) && steady) {
      _readyFrameStartedAt ??= now;
      _stableReadyFrameCount += 1;
      final stableFor = now.difference(_readyFrameStartedAt!);
      return quality.copyWith(
        stableFor: stableFor,
        readiness: stableFor >= _capturePolicy.readyHoldTime
            ? _ReceiptCameraReadiness.ready
            : _ReceiptCameraReadiness.almostReady,
      );
    }
    _readyFrameStartedAt = null;
    _stableReadyFrameCount = 0;
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
        bottomContentScore: 0,
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
    var bottomInk = 0;
    var bottomSamples = 0;
    var inkHits = 0;
    var minInkX = width.toDouble();
    var maxInkX = 0.0;
    var minInkY = height.toDouble();
    var maxInkY = 0.0;
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
          inkHits++;
          if (x < minInkX) minInkX = x.toDouble();
          if (x > maxInkX) maxInkX = x.toDouble();
          if (y < minInkY) minInkY = y.toDouble();
          if (y > maxInkY) maxInkY = y.toDouble();
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
          if (y > height * .84 && x > width * .16 && x < width * .84) {
            bottomInk++;
          }
        }
        if (y > height * .84 && x > width * .16 && x < width * .84) {
          bottomSamples++;
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
        bottomContentScore: 0,
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
    final bottomContentScore = bottomSamples == 0
        ? 0.0
        : bottomInk / bottomSamples;
    final lineBands = _lineBands(rowDarkCounts);
    final documentFrame = _documentFrameFor(
      width: width,
      height: height,
      inkHits: inkHits,
      minInkX: minInkX,
      maxInkX: maxInkX,
      minInkY: minInkY,
      maxInkY: maxInkY,
      cropScore: cropScore,
      textBandScore: textBandScore,
      documentEdgeScore: documentEdgeScore,
    );
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
      bottomContentScore: bottomContentScore,
      lineBands: lineBands,
      readiness: _ReceiptCameraReadiness.notReady,
      stableFor: Duration.zero,
      documentFrame: documentFrame,
    );
    return _ReceiptLiveFrameQuality(
      brightness: base.brightness,
      contrast: base.contrast,
      focusScore: base.focusScore,
      documentEdgeScore: base.documentEdgeScore,
      textBandScore: base.textBandScore,
      cropScore: base.cropScore,
      skewScore: base.skewScore,
      bottomContentScore: base.bottomContentScore,
      lineBands: base.lineBands,
      readiness: _readinessFor(base),
      stableFor: Duration.zero,
      documentFrame: base.documentFrame,
    );
  }

  static _ReceiptDocumentFrame? _documentFrameFor({
    required int width,
    required int height,
    required int inkHits,
    required double minInkX,
    required double maxInkX,
    required double minInkY,
    required double maxInkY,
    required double cropScore,
    required double textBandScore,
    required double documentEdgeScore,
  }) {
    if (inkHits < 24 || maxInkX <= minInkX || maxInkY <= minInkY) {
      return null;
    }
    final left = (minInkX / width).clamp(0.0, 1.0);
    final right = (maxInkX / width).clamp(0.0, 1.0);
    final top = (minInkY / height).clamp(0.0, 1.0);
    final bottom = (maxInkY / height).clamp(0.0, 1.0);
    final rect = Rect.fromLTRB(left, top, right, bottom);
    if (rect.width < .18 || rect.height < .18) return null;
    final aspect = rect.height / math.max(.01, rect.width);
    if (aspect < .45 || aspect > 7.5) return null;
    final centeredX = 1 - ((rect.center.dx - .5).abs() * 2).clamp(0.0, 1.0);
    final centeredY = 1 - ((rect.center.dy - .5).abs() * 2).clamp(0.0, 1.0);
    final fillScore = ((rect.width + rect.height) / 2).clamp(0.0, 1.0);
    final signalScore = (documentEdgeScore / 22).clamp(0.0, 1.0);
    final lineScore = (textBandScore / 14).clamp(0.0, 1.0);
    final confidence =
        (cropScore * .26) +
        (centeredX * .16) +
        (centeredY * .10) +
        (fillScore * .18) +
        (signalScore * .15) +
        (lineScore * .15);
    return _ReceiptDocumentFrame(
      normalizedRect: rect
          .inflate(.035)
          .intersect(const Rect.fromLTWH(0, 0, 1, 1)),
      confidence: confidence.clamp(0.0, 1.0),
    );
  }

  static _ReceiptCameraReadiness _readinessFor(
    _ReceiptLiveFrameQuality quality,
  ) {
    if (quality.isTooDark || quality.isTooBright || quality.isSoft) {
      return _ReceiptCameraReadiness.notReady;
    }
    if (quality.isLowContrast ||
        quality.mayBeCutOffAtBottom ||
        quality.isPoorlyFramed ||
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
