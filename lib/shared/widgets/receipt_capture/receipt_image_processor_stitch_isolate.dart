part of 'receipt_image_processor.dart';

class _ReceiptStitchIsolateMessage {
  const _ReceiptStitchIsolateMessage({
    required this.request,
    required this.resultPort,
  });

  final _ReceiptStitchRequest request;
  final SendPort resultPort;
}

Future<void> _receiptStitchIsolateEntry(
  _ReceiptStitchIsolateMessage message,
) async {
  final result = await _runReceiptStitchInBackground(message.request);
  message.resultPort.send(result);
}

Future<ReceiptStitchResult> _runReceiptStitchInManagedIsolate({
  required _ReceiptStitchRequest request,
  required Duration? processingTimeout,
  required String timeoutReasonCode,
  required String timeoutWarning,
}) async {
  final resultPort = ReceivePort();
  Isolate? isolate;
  try {
    isolate = await Isolate.spawn(
      _receiptStitchIsolateEntry,
      _ReceiptStitchIsolateMessage(
        request: request,
        resultPort: resultPort.sendPort,
      ),
      onError: resultPort.sendPort,
      onExit: resultPort.sendPort,
      errorsAreFatal: true,
      debugName: 'maintainiac-receipt-stitch',
    );
    final responseFuture = resultPort.first;
    final response = processingTimeout == null
        ? await responseFuture
        : await responseFuture.timeout(processingTimeout);
    if (response is ReceiptStitchResult) return response;
    await ReceiptImageProcessor._deleteFileQuietly(request.outputPath);
    return ReceiptStitchResult.fallback(
      inputPaths: request.paths,
      warning:
          'Receipt photos could not be combined safely. Receipt details will use them from top to bottom.',
      fallbackReasonCode: 'stitch_isolate_failed',
    );
  } on TimeoutException {
    isolate?.kill(priority: Isolate.immediate);
    await Future<void>.delayed(Duration.zero);
    await ReceiptImageProcessor._deleteFileQuietly(request.outputPath);
    return ReceiptStitchResult.fallback(
      inputPaths: request.paths,
      warning: timeoutWarning,
      fallbackReasonCode: timeoutReasonCode,
    );
  } catch (_) {
    await ReceiptImageProcessor._deleteFileQuietly(request.outputPath);
    return ReceiptStitchResult.fallback(
      inputPaths: request.paths,
      warning:
          'Receipt photos could not be combined safely. Receipt details will use them from top to bottom.',
      fallbackReasonCode: 'stitch_isolate_failed',
    );
  } finally {
    isolate?.kill(priority: Isolate.immediate);
    resultPort.close();
  }
}
