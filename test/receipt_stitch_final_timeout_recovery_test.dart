import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_image_processor.dart';

void main() {
  test('final stitching timeout keeps ordered clear sections usable', () {
    final result = ReceiptStitchResult.fallback(
      inputPaths: const ['/tmp/clear-first.jpg', '/tmp/clear-second.jpg'],
      warning: 'Putting these photos together took too long.',
      fallbackReasonCode: 'stitch_timeout',
    );

    expect(result.usedFallback, isTrue);
    expect(result.ocrSourcePaths, result.inputPaths);
    expect(result.hasValidOcrSourceContract, isTrue);
    expect(
      result.userFallbackReasonLabel,
      'Putting photos together took too long',
    );
    expect(result.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
    expect(result.assistedReadinessCode, 'ordered_sections_ready');
  });

  test('receipt review turns a late final stitch into a bounded fallback', () async {
    final saveSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsString();
    final handoffSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_stitch_actions.dart',
    ).readAsString();
    final isolateSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_isolate.dart',
    ).readAsString();

    expect(
      saveSource,
      contains('final stitchFuture = _finalStitchResultForOcr('),
    );
    expect(handoffSource, isNot(contains('_stitchDeviceLimits.processingTimeout')));
    expect(handoffSource, isNot(contains("timeoutReasonCode: 'stitch_timeout'")));
    expect(
      isolateSource,
      contains('isolate?.kill(priority: Isolate.immediate)'),
    );
    expect(isolateSource, contains('_deleteFileQuietly(request.outputPath)'));
    expect(
      handoffSource,
      contains('return ReceiptStitchResult.notNeeded(preparedOcrPaths);'),
    );
  });

  test(
    'managed timeout stops stitch work and returns ordered sources',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'receipt_stitch_timeout_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final paths = <String>[];
      for (var index = 0; index < 2; index++) {
        final file = File('${directory.path}/section-$index.jpg');
        await file.writeAsBytes(
          img.encodeJpg(img.Image(width: 800, height: 1600)),
          flush: true,
        );
        paths.add(file.path);
      }

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: paths,
        processingTimeout: Duration.zero,
        timeoutReasonCode: 'stitch_test_timeout',
        timeoutWarning: 'Timed out for the focused cancellation test.',
      );

      expect(result.usedFallback, isTrue);
      expect(result.fallbackReasonCode, 'stitch_test_timeout');
      expect(result.ocrSourcePaths, paths);
    },
  );
}
