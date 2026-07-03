import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android manifest exposes receipt share targets for common PDF types',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      for (final mimeType in const [
        'application/pdf',
        'application/x-pdf',
        'application/acrobat',
        'application/vnd.pdf',
        'application/octet-stream',
        'image/*',
        'text/*',
      ]) {
        expect(manifest, contains('android:mimeType="$mimeType"'));
      }

      expect(manifest, contains('android.intent.action.SEND'));
      expect(manifest, contains('android.intent.action.SEND_MULTIPLE'));
    },
  );
}
