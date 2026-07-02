import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test(
    'all iOS receipt camera Swift units are members of the Runner target',
    () async {
      final sources = await readIosReceiptCameraBridgeSources();
      final xcodeProject = sources.xcodeProject;
      final swiftFiles = _receiptCameraSwiftFileNames();

      expect(swiftFiles, isNotEmpty);

      for (final fileName in swiftFiles) {
        expect(
          xcodeProject,
          contains('/* $fileName */'),
          reason: '$fileName must be listed in the Xcode project.',
        );
        expect(
          xcodeProject,
          contains('/* $fileName in Sources */'),
          reason: '$fileName must be compiled by the Runner target.',
        );
      }

      final staleProjectEntries = _receiptCameraProjectFileNames(
        xcodeProject,
      ).difference(swiftFiles.toSet());

      expect(
        staleProjectEntries,
        isEmpty,
        reason:
            'The Xcode project must not reference deleted receipt camera Swift files.',
      );
    },
  );
}

List<String> _receiptCameraSwiftFileNames() {
  final files =
      Directory('ios/Runner')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where(
            (name) =>
                name.startsWith('ReceiptCameraViewController') &&
                name.endsWith('.swift'),
          )
          .toList()
        ..sort();

  return files;
}

Set<String> _receiptCameraProjectFileNames(String xcodeProject) {
  final matches = RegExp(
    r'ReceiptCameraViewController[A-Za-z0-9]*\.swift',
  ).allMatches(xcodeProject);

  return {for (final match in matches) match.group(0)!};
}
