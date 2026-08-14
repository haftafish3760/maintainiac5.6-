part of 'receipt_ocr_service.dart';

extension ReceiptOcrServiceStitchEvidence on ReceiptOcrService {
  Future<List<ReceiptStitchTextEvidence>> recognizeStitchTextEvidence(
    List<String> paths, {
    Duration? totalBudget,
  }) async {
    final normalizedPaths = [
      for (final path in paths)
        if (path.trim().isNotEmpty) path.trim(),
    ];
    if (normalizedPaths.isEmpty) return const [];
    final evidenceByPath = <String, ReceiptStitchTextEvidence>{};
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final stopwatch = Stopwatch()..start();
    final effectiveBudget =
        totalBudget ??
        Duration(
          milliseconds:
              photoReadTimeout.inMilliseconds * normalizedPaths.length,
        );
    try {
      for (final path in normalizedPaths) {
        final remaining = effectiveBudget - stopwatch.elapsed;
        if (remaining <= Duration.zero) break;
        final readTimeout = remaining < photoReadTimeout
            ? remaining
            : photoReadTimeout;
        try {
          final recognized = await recognizer
              .processImage(InputImage.fromFilePath(path))
              .timeout(readTimeout);
          final orderedLines =
              [for (final block in recognized.blocks) ...block.lines]..sort((
                left,
                right,
              ) {
                final vertical = left.boundingBox.top.compareTo(
                  right.boundingBox.top,
                );
                if (vertical != 0) return vertical;
                return left.boundingBox.left.compareTo(right.boundingBox.left);
              });
          final imageSize = await _receiptStitchImageCoordinateSize(
            path,
            orderedLines,
          );
          final positionedLines = <ReceiptStitchTextLineEvidence>[
            for (final line in orderedLines)
              if (line.text.trim().isNotEmpty)
                ReceiptStitchTextLineEvidence(
                  text: line.text.trim(),
                  left: (line.boundingBox.left / imageSize.width).clamp(
                    0.0,
                    1.0,
                  ),
                  top: (line.boundingBox.top / imageSize.height).clamp(
                    0.0,
                    1.0,
                  ),
                  right: (line.boundingBox.right / imageSize.width).clamp(
                    0.0,
                    1.0,
                  ),
                  bottom: (line.boundingBox.bottom / imageSize.height).clamp(
                    0.0,
                    1.0,
                  ),
                  angleDegrees:
                      line.angle ??
                      (line.cornerPoints.length >= 2
                          ? math.atan2(
                                  (line.cornerPoints[1].y -
                                          line.cornerPoints[0].y)
                                      .toDouble(),
                                  (line.cornerPoints[1].x -
                                          line.cornerPoints[0].x)
                                      .toDouble(),
                                ) *
                                180 /
                                math.pi
                          : 0),
                ),
          ];
          evidenceByPath[path] = ReceiptStitchTextEvidence(
            path: path,
            lines: [for (final line in positionedLines) line.text],
            positionedLines: positionedLines,
          );
        } on TimeoutException {
          // Native ML Kit work cannot be cancelled from Dart. Stop issuing
          // requests to this recognizer and preserve selected order instead.
          break;
        } on MissingPluginException {
          break;
        } on PlatformException {
          evidenceByPath[path] = ReceiptStitchTextEvidence(
            path: path,
            lines: const [],
          );
        } catch (_) {
          evidenceByPath[path] = ReceiptStitchTextEvidence(
            path: path,
            lines: const [],
          );
        }
      }
    } finally {
      stopwatch.stop();
      try {
        await recognizer.close().timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    return [
      for (final path in normalizedPaths)
        evidenceByPath[path] ??
            ReceiptStitchTextEvidence(path: path, lines: const []),
    ];
  }
}

Future<({double width, double height})> _receiptStitchImageCoordinateSize(
  String path,
  List<TextLine> lines,
) async {
  var width = 0.0;
  var height = 0.0;
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  try {
    buffer = await ui.ImmutableBuffer.fromFilePath(path);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    width = descriptor.width.toDouble();
    height = descriptor.height.toDouble();
  } catch (_) {
    // Bounding-box maxima below preserve useful relative evidence when image
    // metadata cannot be read. Receipt content is never discarded for this.
  } finally {
    descriptor?.dispose();
    buffer?.dispose();
  }
  for (final line in lines) {
    width = math.max(width, line.boundingBox.right);
    height = math.max(height, line.boundingBox.bottom);
  }
  return (width: width <= 0 ? 1.0 : width, height: height <= 0 ? 1.0 : height);
}
