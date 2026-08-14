import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test(
    'two receipt sections prepare concurrently in order without changing originals',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'receipt_preparation_workers_',
      );
      final sourcePaths = <String>[];
      final generatedPaths = <String>{};
      addTearDown(() async {
        for (final path in generatedPaths) {
          final file = File(path);
          if (await file.exists()) await file.delete();
        }
        if (await directory.exists()) await directory.delete(recursive: true);
      });

      for (var section = 0; section < 2; section++) {
        final image = img.Image(width: 320, height: 720);
        img.fill(image, color: img.ColorRgb8(246, 245, 238));
        for (var y = 72; y < 660; y += 32) {
          img.drawLine(
            image,
            x1: 24,
            y1: y + section,
            x2: 296,
            y2: y + section + 2,
            color: img.ColorRgb8(20, 20, 20),
            thickness: 3,
          );
        }
        final file = File('${directory.path}/section-$section.jpg');
        await file.writeAsBytes(img.encodeJpg(image), flush: true);
        sourcePaths.add(file.path);
      }

      final tasks = [
        for (final path in sourcePaths)
          Isolate.run(
            () => ReceiptImageProcessor.prepareForOcrAndBackup(
              path: path,
              level: ReceiptDataSaverLevel.balanced,
            ),
          ).timeout(const Duration(seconds: 20)),
      ];
      final prepared = await Future.wait(tasks);

      expect(
        prepared.map((result) => result.preparation.sourcePath),
        orderedEquals(sourcePaths),
      );
      for (final result in prepared) {
        generatedPaths
          ..add(result.ocrSourcePath)
          ..add(result.backupPath);
        expect(await File(result.ocrSourcePath).exists(), isTrue);
        expect(await File(result.backupPath).exists(), isTrue);
      }
      for (final path in sourcePaths) {
        expect(await File(path).exists(), isTrue);
        generatedPaths.remove(path);
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
