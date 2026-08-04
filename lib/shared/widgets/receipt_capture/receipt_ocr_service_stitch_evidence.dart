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
    final linesByPath = <String, List<String>>{};
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
          linesByPath[path] = [
            for (final line in orderedLines)
              if (line.text.trim().isNotEmpty) line.text.trim(),
          ];
        } on TimeoutException {
          // Native ML Kit work cannot be cancelled from Dart. Stop issuing
          // requests to this recognizer and preserve selected order instead.
          break;
        } on MissingPluginException {
          break;
        } on PlatformException {
          linesByPath[path] = const [];
        } catch (_) {
          linesByPath[path] = const [];
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
        ReceiptStitchTextEvidence(
          path: path,
          lines: linesByPath[path] ?? const [],
        ),
    ];
  }
}
