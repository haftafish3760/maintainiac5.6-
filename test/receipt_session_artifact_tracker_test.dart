import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test(
    'discard deletes tracked app artifacts but never a gallery original',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'maintaniac_phase1_artifacts_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final generated = File(
        '${directory.path}/maintaniac_receipt_generated.jpg',
      );
      final galleryOriginal = File('${directory.path}/gallery_original.jpg');
      await generated.writeAsBytes(const [1, 2, 3], flush: true);
      await galleryOriginal.writeAsBytes(const [4, 5, 6], flush: true);

      final review = ReceiptPhotoReviewResult(
        photoPaths: [galleryOriginal.path],
        ocrSourcePhotoPaths: [galleryOriginal.path],
        temporarySourcePhotoPaths: [generated.path, galleryOriginal.path],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.notNeeded([galleryOriginal.path]),
      );
      final tracker = ReceiptSessionArtifactTracker()
        ..retainReviewSources(review);

      await tracker.discardSession();

      expect(await generated.exists(), isFalse);
      expect(await galleryOriginal.exists(), isTrue);
    },
  );

  test(
    'discard fails closed when native recovery cleanup is unresolved',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'maintaniac_unresolved_recovery_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final malformedManifest = File('${directory.path}/capture.json');
      await malformedManifest.writeAsString(
        '{"schema":"unknown"}',
        flush: true,
      );
      final tracker = ReceiptSessionArtifactTracker()
        ..retainRecoveryManifest(malformedManifest.path);

      await expectLater(tracker.discardSession(), throwsStateError);
      expect(await malformedManifest.exists(), isTrue);
    },
  );

  test(
    'durable save does not fail when recovery cleanup needs retry',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'maintaniac_saved_recovery_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final malformedManifest = File('${directory.path}/capture.json');
      await malformedManifest.writeAsString(
        '{"schema":"unknown"}',
        flush: true,
      );
      final tracker = ReceiptSessionArtifactTracker()
        ..retainRecoveryManifest(malformedManifest.path);

      await tracker.finalizeSuccessfulSave(keptReceiptPhotoPaths: const []);

      expect(await malformedManifest.exists(), isTrue);
    },
  );
}
