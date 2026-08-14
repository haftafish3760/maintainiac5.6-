import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test(
    'deletes only Maintainiac-owned receipt JPEGs from system temp',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'receipt_artifact_cleanup_',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      final owned = File(
        '${directory.path}/maintaniac_receipt_optimized_cleanup.jpg',
      );
      final unrelated = File('${directory.path}/gallery_original.jpg');
      final wrongType = File(
        '${directory.path}/maintaniac_receipt_optimized_cleanup.png',
      );
      await owned.writeAsBytes([1, 2, 3]);
      await unrelated.writeAsBytes([4, 5, 6]);
      await wrongType.writeAsBytes([7, 8, 9]);

      await const ReceiptTemporaryArtifactCleanup().deleteAppOwnedFiles([
        owned.path,
        unrelated.path,
        wrongType.path,
      ]);

      expect(await owned.exists(), isFalse);
      expect(await unrelated.exists(), isTrue);
      expect(await wrongType.exists(), isTrue);
    },
  );

  test(
    'keeps a temporary receipt artifact used by the saved receipt',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'receipt_artifact_keep_',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      final kept = File('${directory.path}/maintaniac_receipt_saved_image.jpg');
      await kept.writeAsBytes([1, 2, 3]);

      await const ReceiptTemporaryArtifactCleanup().deleteAppOwnedFiles(
        [kept.path],
        keptPaths: [kept.path],
      );

      expect(await kept.exists(), isTrue);
    },
  );

  test(
    'does not follow a temp symlink to an outside receipt-named file',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'receipt_artifact_symlink_',
      );
      final outsideDirectory = await Directory.systemTemp.parent.createTemp(
        'receipt_artifact_outside_',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
        if (await outsideDirectory.exists()) {
          await outsideDirectory.delete(recursive: true);
        }
      });
      final outside = File(
        '${outsideDirectory.path}/maintaniac_receipt_private_original.jpg',
      );
      await outside.writeAsBytes([1, 2, 3]);
      final link = Link(
        '${tempDirectory.path}/maintaniac_receipt_optimized_symlink.jpg',
      );
      await link.create(outside.path);

      await const ReceiptTemporaryArtifactCleanup().deleteAppOwnedFiles([
        link.path,
      ]);

      expect(await outside.exists(), isTrue);
      expect(await link.exists(), isTrue);
    },
  );
}
