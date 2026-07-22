import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firebase SDK imports stay behind the shared ownership boundary', () {
    const temporaryLegacyOwners = {
      'lib/main.dart',
      'lib/firebase_options.dart',
      'lib/screens/settings/trip_tracking_settings_screen.dart',
      'lib/shared/trip_tracking/trip_tracking_firebase_bridge.dart',
    };
    final violations = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (path.startsWith('lib/shared/firebase/') ||
          temporaryLegacyOwners.contains(path)) {
        continue;
      }
      final source = entity.readAsStringSync();
      if (RegExp(
        r"^import 'package:(firebase_[^']+|cloud_firestore|cloud_functions)/?[^']*';",
        multiLine: true,
      ).hasMatch(source)) {
        violations.add(path);
      }
    }
    expect(
      violations,
      isEmpty,
      reason: 'Move Firebase SDK access into lib/shared/firebase.',
    );
  });
}
